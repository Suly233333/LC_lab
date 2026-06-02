import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/abnormality_repository.dart';
import '../core/database_helper.dart';
import '../core/work_log_repository.dart';
import '../models/abnormality.dart';
import '../state/app_providers.dart';
import 'breach_service.dart';

/// 8 小时未互动检测任务（Qliphoth Counter Decay）。
///
/// AGENT.md §2.3：超过 8 小时未与该异想体互动（仅指**工作执行**，写日记不算）
/// → `qliphothCounter -= 1`。
///
/// 实现策略：
/// - 应用启动时执行一次扫描（追赶离线时段错过的扣减）；
/// - 应用前台时每 [scanInterval] 触发一次扫描；
/// - 计算"基线时刻"为 `max(latestInteractionAt(abn) ?? unlockDate, lastScanAt)`，
///   而后判断 `now - basis` 跨过多少个完整 8 小时窗口，每个窗口扣 1。
class QliphothScheduler {
  QliphothScheduler({
    required this.ref,
    Duration? scanInterval,
    Duration? decayWindow,
  })  : scanInterval = scanInterval ?? const Duration(minutes: 30),
        decayWindow = decayWindow ?? const Duration(hours: 8);

  final Ref ref;

  /// 前台轮询间隔。
  final Duration scanInterval;

  /// 单次扣减窗口长度（默认 8 小时）。
  final Duration decayWindow;

  Timer? _timer;
  Timer? _minuteTimer;
  Timer? _hourTimer;
  bool _running = false;

  /// 启动定时扫描。多次调用安全（重复启动会被忽略）。
  void start() {
    if (_timer != null) return;
    // 立即追赶一次。
    unawaited(scanOnce());
    _timer = Timer.periodic(scanInterval, (_) => scanOnce());

    // 出逃巡检：每分钟扣 PE Box / 30 分钟自动返回。
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      try {
        await ref.read(breachServiceProvider).tickEscape();
      } catch (_) {}
    });

    // 员工 HP 自然恢复：每小时 +10。
    _hourTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await ref.read(breachServiceProvider).healAgentsTick();
      } catch (_) {}
    });
  }

  /// 停止定时扫描。
  void stop() {
    _timer?.cancel();
    _timer = null;
    _minuteTimer?.cancel();
    _minuteTimer = null;
    _hourTimer?.cancel();
    _hourTimer = null;
  }

  /// 单次扫描：根据上次扫描时间与每个异想体的最近互动时间，
  /// 累计本次需要扣减的窗口数并写回数据库。
  Future<void> scanOnce({DateTime? now}) async {
    if (_running) return;
    _running = true;
    try {
      final DateTime stamp = now ?? DateTime.now();
      final AbnormalityRepository abnRepo =
          ref.read(abnormalityRepositoryProvider);
      final WorkLogRepository workRepo =
          ref.read(workLogRepositoryProvider);

      final DateTime? lastScan = await _readLastScanAt();
      final List<Abnormality> all = await abnRepo.getAll();
      bool changed = false;

      for (final Abnormality a in all) {
        if (!a.isUnlocked) continue;
        if (a.qliphothCounter <= 0) continue;

        final DateTime? latestWork =
            await workRepo.latestInteractionAt(a.id);
        final DateTime baseline = _maxDate(<DateTime?>[
          latestWork,
          a.unlockDate,
          lastScan,
        ]);

        final Duration gap = stamp.difference(baseline);
        if (gap < decayWindow) continue;

        final int windows = gap.inMicroseconds ~/ decayWindow.inMicroseconds;
        if (windows <= 0) continue;

        final int next = a.qliphothCounter - windows;
        final int clamped = next < 0 ? 0 : next;
        await abnRepo.setQliphothCounter(a.id, clamped);
        changed = true;

        // 8 小时窗口扣完后归零 → 触发突破。
        if (clamped == 0) {
          await ref.read(breachServiceProvider).maybeBreach(a.id);
        }
      }

      await _writeLastScanAt(stamp);

      if (changed) {
        // 通知 UI 刷新（不暴露具体数值变化）。
        await ref.read(abnormalitiesProvider.notifier).reload();
      }
    } finally {
      _running = false;
    }
  }

  Future<DateTime?> _readLastScanAt() async {
    final Database db = await DatabaseHelper.instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableAppState,
      where: 'key = ?',
      whereArgs: [DatabaseHelper.kLastQliphothScan],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value'] as String? ?? '');
  }

  Future<void> _writeLastScanAt(DateTime when) async {
    final Database db = await DatabaseHelper.instance.database;
    await db.insert(
      DatabaseHelper.tableAppState,
      {
        'key': DatabaseHelper.kLastQliphothScan,
        'value': when.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  DateTime _maxDate(List<DateTime?> values) {
    DateTime? best;
    for (final DateTime? d in values) {
      if (d == null) continue;
      if (best == null || d.isAfter(best)) best = d;
    }
    return best ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

final qliphothSchedulerProvider = Provider<QliphothScheduler>((ref) {
  final QliphothScheduler scheduler = QliphothScheduler(ref: ref);
  ref.onDispose(scheduler.stop);
  return scheduler;
});
