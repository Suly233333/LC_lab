import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/abnormality_repository.dart';
import '../core/database_helper.dart';
import '../core/diary_repository.dart';
import '../core/preset_loader.dart';
import '../core/work_log_repository.dart';
import '../models/abnormality.dart';
import '../models/daily_state.dart';
import '../models/diary_entry.dart';

/// ---------------- 仓库 Provider（单例） ----------------

final abnormalityRepositoryProvider = Provider<AbnormalityRepository>(
  (ref) => AbnormalityRepository(),
);

final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => DiaryRepository(),
);

final workLogRepositoryProvider = Provider<WorkLogRepository>(
  (ref) => WorkLogRepository(),
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

/// ---------------- PE Box 全局余额（下限 0） ----------------

class PeBoxBalanceNotifier extends AsyncNotifier<int> {
  late final AbnormalityRepository _repo;

  @override
  Future<int> build() async {
    _repo = ref.watch(abnormalityRepositoryProvider);
    return _repo.getPeBoxBalance();
  }

  Future<void> setBalance(int v) async {
    final int updated = await _repo.setPeBoxBalance(v);
    state = AsyncValue.data(updated);
  }

  /// 加（正）/扣（负）；扣除时 clamp 至 0。
  Future<void> add(int delta) async {
    final int updated = await _repo.addPeBoxBalance(delta);
    state = AsyncValue.data(updated);
  }
}

final peBoxBalanceProvider =
    AsyncNotifierProvider<PeBoxBalanceNotifier, int>(
  PeBoxBalanceNotifier.new,
);

/// ---------------- 当日 DailyState ----------------

class DailyStateNotifier extends AsyncNotifier<DailyState> {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  @override
  Future<DailyState> build() async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableAppState,
      where: 'key = ?',
      whereArgs: [DatabaseHelper.kDailyState],
      limit: 1,
    );
    final DateTime now = DateTime.now();
    if (rows.isEmpty) {
      final DailyState fresh = DailyState.forDate(now);
      await _persist(fresh);
      return fresh;
    }
    final Map<String, dynamic> raw =
        json.decode(rows.first['value'] as String) as Map<String, dynamic>;
    DailyState loaded = DailyState.fromJson(raw);
    if (loaded.shouldReset(now)) {
      loaded = DailyState.forDate(now);
      await _persist(loaded);
    }
    return loaded;
  }

  Future<void> _persist(DailyState s) async {
    final Database db = await _helper.database;
    await db.insert(
      DatabaseHelper.tableAppState,
      {
        'key': DatabaseHelper.kDailyState,
        'value': json.encode(s.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 替换当日候选名单。
  Future<void> setCandidates(List<String> candidates) async {
    final DailyState current = state.value ?? DailyState.forDate(DateTime.now());
    final DailyState next =
        current.copyWith(extractionCandidates: candidates);
    state = AsyncValue.data(next);
    await _persist(next);
  }

  /// 解锁后自增计数（硬上限 [DailyState.dailyUnlockLimit]）。
  Future<void> incrementUnlockCount() async {
    final DailyState current = state.value ?? DailyState.forDate(DateTime.now());
    final int candidate = current.unlockedCount + 1;
    final int clamped = candidate > DailyState.dailyUnlockLimit
        ? DailyState.dailyUnlockLimit
        : candidate;
    final DailyState next = current.copyWith(unlockedCount: clamped);
    state = AsyncValue.data(next);
    await _persist(next);
  }

  /// 显式刷新（如跨日时被调用）。
  Future<void> refreshIfNewDay() async {
    final DailyState current = state.value ?? DailyState.forDate(DateTime.now());
    final DateTime now = DateTime.now();
    if (current.shouldReset(now)) {
      final DailyState fresh = DailyState.forDate(now);
      state = AsyncValue.data(fresh);
      await _persist(fresh);
    }
  }
}

final dailyStateProvider =
    AsyncNotifierProvider<DailyStateNotifier, DailyState>(
  DailyStateNotifier.new,
);
