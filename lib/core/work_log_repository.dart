import 'package:sqflite/sqflite.dart';

import '../models/work_log.dart';
import 'database_helper.dart';

/// 工作记录持久化仓库。
///
/// 表 `work_logs` 已建索引：`createdAt` 与 `(abnormalityId, createdAt)`，
/// 支持按日期范围与按异想体维度的高效查询。
class WorkLogRepository {
  final DatabaseHelper _helper;

  WorkLogRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  Future<void> insert(WorkLog log) async {
    final Database db = await _helper.database;
    await db.insert(
      DatabaseHelper.tableWorkLogs,
      _toRow(log),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _helper.database;
    await db.delete(
      DatabaseHelper.tableWorkLogs,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<WorkLog>> getAll({int? limit}) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableWorkLogs,
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<WorkLog>> getByAbnormality(
    String abnormalityId, {
    int? limit,
  }) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableWorkLogs,
      where: 'abnormalityId = ?',
      whereArgs: [abnormalityId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  /// 查询某异想体在 [since] 之后是否存在工作记录（用于 8 小时未互动检测）。
  Future<DateTime?> latestInteractionAt(String abnormalityId) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableWorkLogs,
      columns: ['createdAt'],
      where: 'abnormalityId = ?',
      whereArgs: [abnormalityId],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.first['createdAt'] as String);
  }

  Future<List<WorkLog>> queryByRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableWorkLogs,
      where: 'createdAt >= ? AND createdAt < ?',
      whereArgs: [
        fromInclusive.toIso8601String(),
        toExclusive.toIso8601String(),
      ],
      orderBy: 'createdAt DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Map<String, Object?> _toRow(WorkLog l) => {
        'id': l.id,
        'abnormalityId': l.abnormalityId,
        'agentId': l.agentId,
        'workType': l.workType,
        'success': l.success ? 1 : 0,
        'isCriticalFail': l.isCriticalFail ? 1 : 0,
        'peBoxGained': l.peBoxGained,
        'createdAt': l.createdAt.toIso8601String(),
      };

  WorkLog _fromRow(Map<String, Object?> row) {
    return WorkLog(
      id: row['id'] as String,
      abnormalityId: row['abnormalityId'] as String,
      agentId: row['agentId'] as String,
      workType: row['workType'] as String,
      success: (row['success'] as int) != 0,
      isCriticalFail: (row['isCriticalFail'] as int) != 0,
      peBoxGained: row['peBoxGained'] as int,
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }
}
