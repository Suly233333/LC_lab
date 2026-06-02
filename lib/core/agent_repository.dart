import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/agent.dart';
import '../models/work_log.dart' show WorkType;
import 'database_helper.dart';

/// 员工仓库（Agent / EgoGear 库存）。
///
/// v1.0 仅有"主管本人"作为唯一员工。
class AgentRepository {
  AgentRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  static const String defaultUserId = 'agent_self';

  Future<void> upsert(Agent a) async {
    final Database db = await _helper.database;
    await db.insert(
      DatabaseHelper.tableAgents,
      _toRow(a),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Agent?> getById(String id) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableAgents,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<List<Agent>> getAll() async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows =
        await db.query(DatabaseHelper.tableAgents);
    return rows.map(_fromRow).toList(growable: false);
  }

  /// 确保至少存在一个用户主管。返回该用户。
  Future<Agent> ensureDefaultUser() async {
    final Agent? existing = await getById(defaultUserId);
    if (existing != null) return existing;

    final Agent fresh = Agent(
      id: defaultUserId,
      name: 'MANAGER',
      hp: 100,
      maxHp: 100,
      aptitude: <String, int>{
        WorkType.instinct: 1,
        WorkType.insight: 1,
        WorkType.attachment: 1,
        WorkType.repression: 1,
      },
      isUser: true,
    );
    await upsert(fresh);
    return fresh;
  }

  /// 设置 HP（clamp 至 [0, maxHp]）。
  Future<void> setHp(String id, int value) async {
    final Database db = await _helper.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseHelper.tableAgents} '
      'SET hp = MAX(0, MIN(maxHp, ?)) WHERE id = ?',
      [value, id],
    );
  }

  Future<void> equip(String id, List<String> egoIds) async {
    final Database db = await _helper.database;
    await db.update(
      DatabaseHelper.tableAgents,
      {'equippedEgoIds': json.encode(egoIds)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toRow(Agent a) => {
        'id': a.id,
        'name': a.name,
        'avatarPath': a.avatarPath,
        'hp': a.hp,
        'maxHp': a.maxHp,
        'aptitude': json.encode(a.aptitude),
        'equippedEgoIds': json.encode(a.equippedEgoIds),
        'isUser': a.isUser ? 1 : 0,
      };

  Agent _fromRow(Map<String, Object?> row) {
    return Agent(
      id: row['id'] as String,
      name: row['name'] as String,
      avatarPath: row['avatarPath'] as String?,
      hp: row['hp'] as int,
      maxHp: row['maxHp'] as int,
      aptitude:
          (json.decode(row['aptitude'] as String) as Map<dynamic, dynamic>)
              .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      equippedEgoIds:
          (json.decode(row['equippedEgoIds'] as String) as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      isUser: (row['isUser'] as int) != 0,
    );
  }
}
