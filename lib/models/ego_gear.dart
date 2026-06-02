/// EGO 装备奖励维度的常量 key。
class EgoStat {
  EgoStat._();

  /// 镇压加成，用于出逃异想体镇压成功率公式：
  /// `clamp(Σ(equippedEgo.bonusStats[suppression] × 0.1) + 0.2, 0.1, 0.9)`
  static const String suppression = 'suppression';

  /// HP 上限加成（预留）。
  static const String maxHp = 'maxHp';

  /// 四维适性加成（预留），key 同 WorkType。
  static const String instinct = 'instinct';
  static const String insight = 'insight';
  static const String attachment = 'attachment';
  static const String repression = 'repression';
}

/// EGO 装备（EgoGear）。
///
/// 在 EGO 商店通过 PE Box 兑换；员工装备后通过 [bonusStats] 提供加成。
class EgoGear {
  /// 主键 ID。
  final String id;

  /// 装备名。
  final String name;

  /// 描述。
  final String description;

  /// 兑换需消耗的 PE Box 数量。
  final int cost;

  /// 加成数值表，key 见 [EgoStat]。
  /// 镇压加成位于 `bonusStats[EgoStat.suppression]`，用于镇压成功率公式。
  final Map<String, int> bonusStats;

  EgoGear({
    required this.id,
    required this.name,
    this.description = '',
    required this.cost,
    Map<String, int>? bonusStats,
  }) : bonusStats = bonusStats ?? const {};

  factory EgoGear.fromJson(Map<String, dynamic> json) {
    return EgoGear(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      cost: (json['cost'] as num).toInt(),
      bonusStats: (json['bonusStats'] as Map<dynamic, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k as String, (v as num).toInt())),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'cost': cost,
        'bonusStats': bonusStats,
      };
}
