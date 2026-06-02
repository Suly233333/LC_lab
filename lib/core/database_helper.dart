import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 全局 sqflite 数据库初始化与建表。
///
/// 5 张表：
/// - abnormalities：异想体档案与运行时状态
/// - diary_entries：日记条目（含隐藏的 resonanceDeltas JSON）
/// - work_logs：工作执行历史
/// - agents：员工
/// - ego_inventory：已获得的 EGO 装备库存
///
/// 另含 1 张 KV 表 `app_state` 用于存储 PE Box 全局余额、当日 DailyState 等。
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbFileName = 'lc_lab.db';
  static const int dbVersion = 2;

  // 表名
  static const String tableAbnormalities = 'abnormalities';
  static const String tableDiaryEntries = 'diary_entries';
  static const String tableWorkLogs = 'work_logs';
  static const String tableAgents = 'agents';
  static const String tableEgoInventory = 'ego_inventory';
  static const String tableAppState = 'app_state';

  // app_state KV keys
  static const String kPeBoxBalance = 'pe_box_balance';
  static const String kDailyState = 'daily_state';
  static const String kLastQliphothScan = 'last_qliphoth_scan';

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 出逃状态字段
      await db.execute(
        'ALTER TABLE $tableAbnormalities '
        'ADD COLUMN isEscaped INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableAbnormalities ADD COLUMN escapeStartedAt TEXT',
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch();

    batch.execute('''
      CREATE TABLE $tableAbnormalities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        grade TEXT NOT NULL,
        featureTags TEXT NOT NULL,
        workTypeWeights TEXT NOT NULL,
        requiredDays INTEGER NOT NULL,
        requiredResonance INTEGER NOT NULL,
        currentResonance INTEGER NOT NULL DEFAULT 0,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        isInitial INTEGER NOT NULL DEFAULT 0,
        unlockDate TEXT,
        energyLevel INTEGER NOT NULL DEFAULT 50,
        qliphothCounter INTEGER NOT NULL,
        qliphothMax INTEGER NOT NULL,
        breachType TEXT NOT NULL,
        penaltyAmount INTEGER,
        escapeDrain INTEGER,
        isEscaped INTEGER NOT NULL DEFAULT 0,
        escapeStartedAt TEXT,
        description TEXT NOT NULL,
        manageNote TEXT NOT NULL,
        workReactions TEXT NOT NULL
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

    batch.execute('''
      CREATE TABLE $tableWorkLogs (
        id TEXT PRIMARY KEY,
        abnormalityId TEXT NOT NULL,
        agentId TEXT NOT NULL,
        workType TEXT NOT NULL,
        success INTEGER NOT NULL,
        isCriticalFail INTEGER NOT NULL,
        peBoxGained INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_work_createdAt ON $tableWorkLogs(createdAt)',
    );
    batch.execute(
      'CREATE INDEX idx_work_abnormality ON $tableWorkLogs(abnormalityId, createdAt)',
    );

    batch.execute('''
      CREATE TABLE $tableAgents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatarPath TEXT,
        hp INTEGER NOT NULL,
        maxHp INTEGER NOT NULL,
        aptitude TEXT NOT NULL,
        equippedEgoIds TEXT NOT NULL,
        isUser INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableEgoInventory (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        cost INTEGER NOT NULL,
        bonusStats TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableAppState (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

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
