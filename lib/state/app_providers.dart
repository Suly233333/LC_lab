import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/abnormality_repository.dart';
import '../core/diary_repository.dart';
import '../core/preset_loader.dart';
import '../models/abnormality.dart';
import '../models/diary_entry.dart';

/// ---------------- 仓库 Provider（单例） ----------------

final abnormalityRepositoryProvider = Provider<AbnormalityRepository>(
  (ref) => AbnormalityRepository(),
);

final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => DiaryRepository(),
);

/// ---------------- 异想体（全部 / 已解锁） ----------------

class AbnormalityListNotifier
    extends AsyncNotifier<List<Abnormality>> {
  late final AbnormalityRepository _repo;

  @override
  Future<List<Abnormality>> build() async {
    _repo = ref.watch(abnormalityRepositoryProvider);
    List<Abnormality> existing = await _repo.getAll();
    if (existing.isEmpty) {
      // 首次启动：从预设引导，初始异想体自动解锁。
      existing = await PresetLoader.bootstrapAbnormalities();
      await _repo.upsertAll(existing);
    }
    return existing;
  }

  /// 强制重载。
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  /// 标记解锁某异想体。
  Future<void> unlock(String id, {DateTime? when}) async {
    final DateTime stamp = when ?? DateTime.now();
    await _repo.markUnlocked(id, stamp);
    await reload();
  }
}

final abnormalitiesProvider =
    AsyncNotifierProvider<AbnormalityListNotifier, List<Abnormality>>(
  AbnormalityListNotifier.new,
);

/// 仅已解锁的便利筛选。
final unlockedAbnormalitiesProvider = Provider<List<Abnormality>>((ref) {
  final AsyncValue<List<Abnormality>> value =
      ref.watch(abnormalitiesProvider);
  return value.maybeWhen(
    data: (list) => list.where((a) => a.isUnlocked).toList(),
    orElse: () => const <Abnormality>[],
  );
});

/// ---------------- 日记列表 ----------------

class DiaryListNotifier extends AsyncNotifier<List<DiaryEntry>> {
  late final DiaryRepository _repo;

  @override
  Future<List<DiaryEntry>> build() async {
    _repo = ref.watch(diaryRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  /// 仅本地存储一条新日记；共鸣度计算应由 ResonanceService 后续完成
  /// 并通过 [updateEntry] 回填 deltas。
  Future<void> addEntry(DiaryEntry entry) async {
    await _repo.insert(entry);
    await reload();
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    await _repo.update(entry);
    await reload();
  }

  Future<void> deleteEntry(String id) async {
    await _repo.delete(id);
    await reload();
  }
}

final diaryListProvider =
    AsyncNotifierProvider<DiaryListNotifier, List<DiaryEntry>>(
  DiaryListNotifier.new,
);

/// ---------------- 待揭晓的解锁队列 ----------------

/// 由 [UnlockService.evaluateAutoUnlock] 写入；档案库页监听后弹仪式动画并清空。
class PendingUnlocksNotifier extends Notifier<List<Abnormality>> {
  @override
  List<Abnormality> build() => const <Abnormality>[];

  void enqueue(List<Abnormality> items) {
    if (items.isEmpty) return;
    state = <Abnormality>[...state, ...items];
  }

  void clear() {
    state = const <Abnormality>[];
  }
}

final pendingUnlocksProvider =
    NotifierProvider<PendingUnlocksNotifier, List<Abnormality>>(
  PendingUnlocksNotifier.new,
);
