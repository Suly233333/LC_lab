import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/abnormality.dart';
import 'database_helper.dart';

/// 异想体持久化仓库（精简版 v1.1）。
class AbnormalityRepository {
  final DatabaseHelper _helper;

  AbnormalityRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  // ---------- Abnormality CRUD ----------

  /// 全量插入或更新一批异想体（启动时引导用）。
  Future<void> upsertAll(List<Abnormality> items) async {
    final Database db = await _helper.database;
    final Batch batch = db.batch();
    for (final Abnormality a in items) {
      batch.insert(
        DatabaseHelper.tableAbnormalities,
        _toRow(a),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 单个 upsert。
  Future<void> upsert(Abnormality a) async {
    final Database db = await _helper.database;
    await db.insert(
      DatabaseHelper.tableAbnormalities,
      _toRow(a),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 按 ID 读取。
  Future<Abnormality?> getById(String id) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableAbnormalities,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// 读取全部。
  Future<List<Abnormality>> getAll() async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows =
        await db.query(DatabaseHelper.tableAbnormalities);
    return rows.map(_fromRow).toList(growable: false);
  }

  /// 仅读取已解锁条目。
  Future<List<Abnormality>> getUnlocked() async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableAbnormalities,
      where: 'isUnlocked = 1',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  /// 删除某条（一般不会用到，仅测试）。
  Future<void> delete(String id) async {
    final Database db = await _helper.database;
    await db.delete(
      DatabaseHelper.tableAbnormalities,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 累加 currentResonance（隐藏字段）。
  Future<void> addResonance(String id, int delta) async {
    final Database db = await _helper.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseHelper.tableAbnormalities} '
      'SET currentResonance = currentResonance + ? WHERE id = ?',
      [delta, id],
    );
  }

  /// 标记解锁。
  Future<void> markUnlocked(String id, DateTime when) async {
    final Database db = await _helper.database;
    await db.update(
      DatabaseHelper.tableAbnormalities,
      {
        'isUnlocked': 1,
        'unlockDate': when.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------- 行 / 模型转换 ----------

  Map<String, Object?> _toRow(Abnormality a) => {
        'id': a.id,
        'name': a.name,
        'grade': a.grade,
        'featureTags': json.encode(a.featureTags),
        'requiredDays': a.requiredDays,
        'requiredResonance': a.requiredResonance,
        'currentResonance': a.currentResonance,
        'isUnlocked': a.isUnlocked ? 1 : 0,
        'isInitial': a.isInitial ? 1 : 0,
        'unlockDate': a.unlockDate?.toIso8601String(),
        'description': a.description,
        'manageNote': a.manageNote,
      };

  Abnormality _fromRow(Map<String, Object?> row) {
    return Abnormality.fromJson({
      'id': row['id'],
      'name': row['name'],
      'grade': row['grade'],
      'featureTags': json.decode(row['featureTags'] as String),
      'requiredDays': row['requiredDays'],
      'requiredResonance': row['requiredResonance'],
      'currentResonance': row['currentResonance'],
      'isUnlocked': (row['isUnlocked'] as int) != 0,
      'isInitial': (row['isInitial'] as int) != 0,
      'unlockDate': row['unlockDate'],
      'description': row['description'],
      'manageNote': row['manageNote'],
    });
  }
}
