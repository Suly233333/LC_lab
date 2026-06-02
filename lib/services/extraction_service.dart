import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/abnormality_repository.dart';
import '../core/diary_repository.dart';
import '../models/abnormality.dart';
import '../models/daily_state.dart';
import '../state/app_providers.dart';

/// 每日提取仪式服务（Extraction Ceremony）。
///
/// 资格判定（AGENT.md §2.1）：
/// - `currentResonance ≥ requiredResonance` **且** `累计记录天数 ≥ requiredDays`
/// - 累计记录天数封顶 30
/// - `isInitial == true` 的异想体不进入提取池（自动解锁）
///
/// 配额：
/// - 每天随机抽取 [DailyState.extractionPoolSize] = 3 个候选
/// - 每日最多解锁 [DailyState.dailyUnlockLimit] = 1 个
/// - 按自然日 0:00 重置（DailyStateNotifier 已实现）
class ExtractionService {
  ExtractionService({
    required this.ref,
    Random? random,
  }) : _random = random ?? Random();

  final Ref ref;
  final Random _random;

  /// 计算当前所有"具备解锁资格"的异想体（不含已解锁与初始解锁项）。
  Future<List<Abnormality>> eligibleAbnormalities() async {
    final AbnormalityRepository abnRepo =
        ref.read(abnormalityRepositoryProvider);
    final DiaryRepository diaryRepo = ref.read(diaryRepositoryProvider);

    final List<Abnormality> all = await abnRepo.getAll();
    final int days = await diaryRepo.distinctDayCount();

    return all.where((a) {
      if (a.isUnlocked) return false;
      if (a.isInitial) return false;
      if (a.currentResonance < a.requiredResonance) return false;
      if (days < a.requiredDays) return false;
      return true;
    }).toList(growable: false);
  }

  /// 生成或读取当日候选名单。
  ///
  /// - 若 [DailyState.extractionCandidates] 已存在且对应 ID 仍可解锁，
  ///   直接返回；
  /// - 否则从 [eligibleAbnormalities] 中随机抽 [DailyState.extractionPoolSize]
  ///   个，写入 DailyState 并返回。
  Future<List<Abnormality>> rollDailyCandidates({bool force = false}) async {
    await ref.read(dailyStateProvider.notifier).refreshIfNewDay();

    final DailyState daily =
        ref.read(dailyStateProvider).value ?? DailyState.forDate(DateTime.now());
    final AbnormalityRepository abnRepo =
        ref.read(abnormalityRepositoryProvider);

    if (!force && daily.extractionCandidates.isNotEmpty) {
      final List<Abnormality> cached = <Abnormality>[];
      for (final String id in daily.extractionCandidates) {
        final Abnormality? a = await abnRepo.getById(id);
        if (a != null && !a.isUnlocked) cached.add(a);
      }
      if (cached.isNotEmpty) return cached;
    }

    final List<Abnormality> pool = await eligibleAbnormalities();
    final List<Abnormality> shuffled = [...pool]..shuffle(_random);
    final int take = shuffled.length < DailyState.extractionPoolSize
        ? shuffled.length
        : DailyState.extractionPoolSize;
    final List<Abnormality> picked =
        shuffled.take(take).toList(growable: false);

    await ref
        .read(dailyStateProvider.notifier)
        .setCandidates(picked.map((a) => a.id).toList(growable: false));
    return picked;
  }

  /// 解锁某个候选异想体。
  /// 返回 `true` 表示解锁成功，`false` 表示被配额或资格阻止。
  Future<bool> unlockFromCandidates(String abnormalityId) async {
    await ref.read(dailyStateProvider.notifier).refreshIfNewDay();
    final DailyState daily =
        ref.read(dailyStateProvider).value ?? DailyState.forDate(DateTime.now());
    if (!daily.canUnlock) return false;
    if (!daily.extractionCandidates.contains(abnormalityId)) return false;

    final AbnormalityRepository abnRepo =
        ref.read(abnormalityRepositoryProvider);
    final Abnormality? target = await abnRepo.getById(abnormalityId);
    if (target == null || target.isUnlocked) return false;

    await ref
        .read(abnormalitiesProvider.notifier)
        .unlock(abnormalityId, when: DateTime.now());
    await ref.read(dailyStateProvider.notifier).incrementUnlockCount();
    return true;
  }
}

final extractionServiceProvider = Provider<ExtractionService>((ref) {
  return ExtractionService(ref: ref);
});
