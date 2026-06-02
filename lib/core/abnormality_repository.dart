import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/abnormality.dart';
import 'database_helper.dart';

/// 异想体 / 全局余额（PE Box）持久化仓库。
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

  /// 设置 qliphothCounter（clamp 到 [0, qliphothMax]）。
  Future<void> setQliphothCounter(String id, int value) async {
    final Database db = await _helper.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseHelper.tableAbnormalities} '
      'SET qliphothCounter = MAX(0, MIN(qliphothMax, ?)) WHERE id = ?',
      [value, id],
    );
  }

  /// 设置 energyLevel（clamp 到 [0, 100]）。
  Future<void> setEnergyLevel(String id, int value) async {
    final Database db = await _helper.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseHelper.tableAbnormalities} '
      'SET energyLevel = MAX(0, MIN(100, ?)) WHERE id = ?',
      [value, id],
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

  // ---------- PE Box 全局余额（app_state KV） ----------

  /// 读取 PE Box 全局余额，缺省返回 0。
  Future<int> getPeBoxBalance() async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableAppState,
      where: 'key = ?',
      whereArgs: [DatabaseHelper.kPeBoxBalance],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.first['value'] as String? ?? '0') ?? 0;
  }

  /// 设置 PE Box 余额，自动 clamp 至 ≥ 0。
  Future<int> setPeBoxBalance(int value) async {
    final int clamped = value < 0 ? 0 : value;
    final Database db = await _helper.database;
    await db.insert(
      DatabaseHelper.tableAppState,
      {
        'key': DatabaseHelper.kPeBoxBalance,
        'value': clamped.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return clamped;
  }

  /// 增减 PE Box；扣除时 clamp 至 ≥ 0；返回最新余额。
  Future<int> addPeBoxBalance(int delta) async {
    final int current = await getPeBoxBalance();
    return setPeBoxBalance(current + delta);
  }

  // ---------- 行 / 模型转换 ----------

  Map<String, Object?> _toRow(Abnormality a) => {
        'id': a.id,
        'name': a.name,
        'grade': a.grade,
        'featureTags': json.encode(a.featureTags),
        'workTypeWeights': json.encode(a.workTypeWeights),
        'requiredDays': a.requiredDays,
        'requiredResonance': a.requiredResonance,
        'currentResonance': a.currentResonance,
        'isUnlocked': a.isUnlocked ? 1 : 0,
        'isInitial': a.isInitial ? 1 : 0,
        'unlockDate': a.unlockDate?.toIso8601String(),
        'energyLevel': a.energyLevel,
        'qliphothCounter': a.qliphothCounter,
        'qliphothMax': a.qliphothMax,
        'breachType': a.breachType.name,
        'penaltyAmount': a.penaltyAmount,
        'escapeDrain': a.escapeDrain,
        'description': a.description,
        'manageNote': a.manageNote,
        'workReactions': json.encode(a.workReactions),
      };

  Abnormality _fromRow(Map<String, Object?> row) {
    return Abnormality.fromJson({
      'id': row['id'],
      'name': row['name'],
      'grade': row['grade'],
      'featureTags': json.decode(row['featureTags'] as String),
      'workTypeWeights': json.decode(row['workTypeWeights'] as String),
      'requiredDays': row['requiredDays'],
      'requiredResonance': row['requiredResonance'],
      'currentResonance': row['currentResonance'],
      'isUnlocked': (row['isUnlocked'] as int) != 0,
      'isInitial': (row['isInitial'] as int) != 0,
      'unlockDate': row['unlockDate'],
      'energyLevel': row['energyLevel'],
      'qliphothCounter': row['qliphothCounter'],
      'qliphothMax': row['qliphothMax'],
      'breachType': row['breachType'],
      'penaltyAmount': row['penaltyAmount'],
      'escapeDrain': row['escapeDrain'],
      'description': row['description'],
      'manageNote': row['manageNote'],
      'workReactions': json.decode(row['workReactions'] as String),
    });
  }
}
