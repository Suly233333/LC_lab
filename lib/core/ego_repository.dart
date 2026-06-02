import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/ego_gear.dart';
import 'database_helper.dart';

/// EGO 装备库存仓库（已购买装备列表）。
class EgoRepository {
  EgoRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<void> insert(EgoGear gear) async {
    final Database db = await _helper.database;
    await db.insert(
      DatabaseHelper.tableEgoInventory,
      _toRow(gear),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<EgoGear?> getById(String id) async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableEgoInventory,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<List<EgoGear>> getAll() async {
    final Database db = await _helper.database;
    final List<Map<String, Object?>> rows =
        await db.query(DatabaseHelper.tableEgoInventory);
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<EgoGear>> getMany(Iterable<String> ids) async {
    if (ids.isEmpty) return const <EgoGear>[];
    final Database db = await _helper.database;
    final String placeholders = List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseHelper.tableEgoInventory,
      where: 'id IN ($placeholders)',
      whereArgs: ids.toList(),
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<void> delete(String id) async {
    final Database db = await _helper.database;
    await db.delete(
      DatabaseHelper.tableEgoInventory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toRow(EgoGear g) => {
        'id': g.id,
        'name': g.name,
        'description': g.description,
        'cost': g.cost,
        'bonusStats': json.encode(g.bonusStats),
      };

  EgoGear _fromRow(Map<String, Object?> row) {
    return EgoGear(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      cost: row['cost'] as int,
      bonusStats:
          (json.decode(row['bonusStats'] as String) as Map<dynamic, dynamic>)
              .map((k, v) => MapEntry(k as String, (v as num).toInt())),
    );
  }
}
