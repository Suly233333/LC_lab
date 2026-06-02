import 'work_log.dart' show WorkType;

/// 员工（Agent）。
///
/// v1.0 仅有"主管本人"作为唯一员工执行工作。
class Agent {
  /// 主键 ID。
  final String id;

  /// 显示名。
  String name;

  /// 头像路径（本地文件或 asset）。
  String? avatarPath;

  /// 当前 HP。
  int hp;

  /// HP 上限，受伤恢复时 clamp 至此值；默认 100。
  final int maxHp;

  /// 四维适性等级，key 为 [WorkType.values]，整数。
  /// 例如 {instinct: 1, insight: 2, attachment: 3, repression: 1}。
  final Map<String, int> aptitude;

  /// 已装备的 EGO 装备 ID 列表。
  List<String> equippedEgoIds;

  /// 是否为用户本人（v1.0 唯一员工）。
  final bool isUser;

  Agent({
    required this.id,
    required this.name,
    this.avatarPath,
    this.hp = 100,
    this.maxHp = 100,
    Map<String, int>? aptitude,
    List<String>? equippedEgoIds,
    this.isUser = false,
  })  : aptitude = aptitude ??
            {
              WorkType.instinct: 1,
              WorkType.insight: 1,
              WorkType.attachment: 1,
              WorkType.repression: 1,
            },
        equippedEgoIds = equippedEgoIds ?? <String>[];

  /// 是否处于"受伤"状态：HP 归零无法工作。
  bool get isInjured => hp <= 0;

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatarPath'] as String?,
      hp: (json['hp'] as num?)?.toInt() ?? 100,
      maxHp: (json['maxHp'] as num?)?.toInt() ?? 100,
      aptitude: (json['aptitude'] as Map<dynamic, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      equippedEgoIds: (json['equippedEgoIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      isUser: (json['isUser'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarPath': avatarPath,
        'hp': hp,
        'maxHp': maxHp,
        'aptitude': aptitude,
        'equippedEgoIds': equippedEgoIds,
        'isUser': isUser,
      };
}
