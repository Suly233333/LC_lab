/// 工作类型枚举字符串常量。统一使用字符串 key 以兼容
/// `Abnormality.workTypeWeights` / `Agent.aptitude` 的 Map 索引。
class WorkType {
  WorkType._();

  /// 本能。
  static const String instinct = 'instinct';

  /// 洞察。
  static const String insight = 'insight';

  /// 沟通。
  static const String attachment = 'attachment';

  /// 压迫。
  static const String repression = 'repression';

  /// 全部合法工作类型。
  static const List<String> values = [
    instinct,
    insight,
    attachment,
    repression,
  ];
}

/// 工作记录（WorkLog）。
///
/// 每次工作执行（无论成败）都会生成一条独立记录，用于：
/// - 8 小时未互动检测（写日记不算，需 WorkLog 命中该 abnormalityId）
/// - 历史回溯与统计
class WorkLog {
  /// 主键 ID。
  final String id;

  /// 关联的（已解锁）异想体 ID。
  final String abnormalityId;

  /// 执行工作的员工 ID。
  final String agentId;

  /// 工作类型，见 [WorkType]。
  final String workType;

  /// 工作判定结果：true 成功 / false 失败。
  final bool success;

  /// 是否为大失败（成功率 < 20% 且判定失败）。
  final bool isCriticalFail;

  /// 本次工作产出的 PE Box 数量；失败时为 0。
  final int peBoxGained;

  /// 创建时间。
  final DateTime createdAt;

  WorkLog({
    required this.id,
    required this.abnormalityId,
    required this.agentId,
    required this.workType,
    required this.success,
    required this.isCriticalFail,
    required this.peBoxGained,
    required this.createdAt,
  });

  factory WorkLog.fromJson(Map<String, dynamic> json) {
    return WorkLog(
      id: json['id'] as String,
      abnormalityId: json['abnormalityId'] as String,
      agentId: json['agentId'] as String,
      workType: json['workType'] as String,
      success: _toBool(json['success']),
      isCriticalFail: _toBool(json['isCriticalFail']),
      peBoxGained: (json['peBoxGained'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'abnormalityId': abnormalityId,
        'agentId': agentId,
        'workType': workType,
        'success': success ? 1 : 0,
        'isCriticalFail': isCriticalFail ? 1 : 0,
        'peBoxGained': peBoxGained,
        'createdAt': createdAt.toIso8601String(),
      };

  static bool _toBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    return raw == 'true' || raw == '1';
  }
}
