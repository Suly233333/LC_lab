import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 全局 sqflite 数据库初始化与建表。
///
/// 精简版（v1.1）：
/// - abnormalities：异想体档案与解锁状态
/// - diary_entries：日记条目（含隐藏的 resonanceDeltas JSON）
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbFileName = 'lc_lab.db';
  static const int dbVersion = 3;

  // 表名
  static const String tableAbnormalities = 'abnormalities';
  static const String tableDiaryEntries = 'diary_entries';

  Database? _db;

  /// 获取 / 懒加载数据库。
  Future<Database> get database async {
    final Database? existing = _db;
    if (existing != null && existing.isOpen) return existing;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final String dbPath = await getDatabasesPath();
    final String fullPath = p.join(dbPath, dbFileName);
    return openDatabase(
      fullPath,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// v1.1 重构：旧 schema 直接 DROP 重建（用户数据丢失，可接受）。
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final Batch batch = db.batch();
    batch.execute('DROP TABLE IF EXISTS $tableAbnormalities');
    batch.execute('DROP TABLE IF EXISTS $tableDiaryEntries');
    batch.execute('DROP TABLE IF EXISTS work_logs');
    batch.execute('DROP TABLE IF EXISTS agents');
    batch.execute('DROP TABLE IF EXISTS ego_inventory');
    batch.execute('DROP TABLE IF EXISTS app_state');
    await batch.commit(noResult: true);
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch();

    batch.execute('''
      CREATE TABLE $tableAbnormalities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        grade TEXT NOT NULL,
        featureTags TEXT NOT NULL,
        requiredDays INTEGER NOT NULL,
        requiredResonance INTEGER NOT NULL,
        currentResonance INTEGER NOT NULL DEFAULT 0,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        isInitial INTEGER NOT NULL DEFAULT 0,
        unlockDate TEXT,
        description TEXT NOT NULL,
        manageNote TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableDiaryEntries (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        attachments TEXT NOT NULL,
        cognitiveFilters TEXT NOT NULL,
        resonanceDeltas TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_diary_createdAt ON $tableDiaryEntries(createdAt)',
    );

    await batch.commit(noResult: true);
  }

  /// 关闭数据库（用于测试或显式回收）。
  Future<void> close() async {
    final Database? d = _db;
    if (d != null && d.isOpen) {
      await d.close();
      _db = null;
    }
  }
}
