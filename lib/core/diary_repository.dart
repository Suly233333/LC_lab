import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/diary_entry.dart';
import 'database_helper.dart';

/// 日记条目持久化仓库。
///
/// 表 `diary_entries` 已在 createdAt 上建立索引，支持按日期范围查询。
class DiaryRepository {
  final DatabaseHelper _helper;

  DiaryRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  Future<void> insert(DiaryEntry entry) async {
    final Database db = await _helper.database;
    await db.insert(
      DatabaseHelper.tableDiaryEntries,
      _toRow(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(DiaryEntry entry) async {
    final Database db = await _helper.database;
    await db.update(
      DatabaseHelper.tableDiaryEntries,
      _toRow(entry),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _helper.database;
    await db.delete(
      DatabaseHelper.tableDiaryEntries,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final Database db = await _helper.database;
    await db.delete(DatabaseHelper.tableDiaryEntries);
  }

  /// 全量按时间倒序读取。
  Future<List<DiaryEntry>> getAll() async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableDiaryEntries,
      orderBy: 'createdAt DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  /// 按日期范围查询（左闭右开）。
  Future<List<DiaryEntry>> queryByRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableDiaryEntries,
      where: 'createdAt >= ? AND createdAt < ?',
      whereArgs: [
        fromInclusive.toIso8601String(),
        toExclusive.toIso8601String(),
      ],
      orderBy: 'createdAt DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  /// 累计独立日记天数。
  ///
  /// 异想体 [requiredDays] 解锁阈值的硬上限为 30，因此查询时直接按
  /// [cap] = 30 截断即可满足任何资格判定，无需统计更高的天数。
  Future<int> distinctDayCount({int cap = 30}) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT substr(createdAt, 1, 10)) AS c '
      'FROM ${DatabaseHelper.tableDiaryEntries}',
    );
    final int n = (rows.first['c'] as int?) ?? 0;
    return n > cap ? cap : n;
  }

  Map<String, Object?> _toRow(DiaryEntry e) => {
        'id': e.id,
        'content': e.content,
        'attachments': json.encode(e.attachments),
        'cognitiveFilters': json.encode(e.cognitiveFilters),
        'resonanceDeltas': json.encode(e.resonanceDeltas),
        'createdAt': e.createdAt.toIso8601String(),
      };

  DiaryEntry _fromRow(Map<String, Object?> row) {
    return DiaryEntry(
      id: row['id'] as String,
      content: row['content'] as String,
      attachments: (json.decode(row['attachments'] as String) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      cognitiveFilters:
          (json.decode(row['cognitiveFilters'] as String) as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      resonanceDeltas:
          (json.decode(row['resonanceDeltas'] as String) as Map<dynamic, dynamic>)
              .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }
}
