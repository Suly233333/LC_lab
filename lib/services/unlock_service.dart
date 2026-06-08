import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/abnormality_repository.dart';
import '../core/diary_repository.dart';
import '../models/abnormality.dart';
import '../state/app_providers.dart';

/// 自动解锁服务（v1.1 精简版）。
///
/// 资格判定（AGENT.md §2.1）：
/// - `currentResonance ≥ requiredResonance` **且** `累计记录天数 ≥ requiredDays`
/// - `isInitial == true` 的异想体不参与（启动时已自动解锁）
/// - 已解锁项不参与
///
/// 满足条件 → 立即解锁，并通过 [pendingUnlocksProvider] 通知 UI 弹仪式动画。
class UnlockService {
  UnlockService({required this.ref});

  final Ref ref;

  /// 评估并解锁所有满足条件的异想体；返回本次新增解锁的异想体列表。
  Future<List<Abnormality>> evaluateAutoUnlock() async {
    final AbnormalityRepository abnRepo =
        ref.read(abnormalityRepositoryProvider);
    final DiaryRepository diaryRepo = ref.read(diaryRepositoryProvider);

    final List<Abnormality> all = await abnRepo.getAll();
    final int days = await diaryRepo.distinctDayCount();

    final List<Abnormality> unlocked = <Abnormality>[];
    final DateTime now = DateTime.now();
    for (final Abnormality a in all) {
      if (a.isUnlocked) continue;
      if (a.isInitial) continue;
      if (a.currentResonance < a.requiredResonance) continue;
      if (days < a.requiredDays) continue;
      await abnRepo.markUnlocked(a.id, now);
      a.isUnlocked = true;
      a.unlockDate = now;
      unlocked.add(a);
    }

    if (unlocked.isNotEmpty) {
      // 刷新全局列表
      await ref.read(abnormalitiesProvider.notifier).reload();
      // 推送给 UI 弹仪式动画
      ref.read(pendingUnlocksProvider.notifier).enqueue(unlocked);
    }
    return unlocked;
  }
}

final unlockServiceProvider = Provider<UnlockService>((ref) {
  return UnlockService(ref: ref);
});
