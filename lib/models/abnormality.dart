/// 异想体突破类型。
///
/// - [escape]：异想体出逃，每分钟扣除 PE Box，直到镇压或自动返回。
/// - [penaltyBox]：扣除一定比例 PE Box 储备后重置计数器。
/// - [none]：无突破事件，仅重置计数器。
enum BreachType { escape, penaltyBox, none }

/// 异想体（Abnormality）核心数据模型。
///
/// ⚠️ 共鸣度禁令（见 AGENT.md §4 / §2.1）：
/// [currentResonance] / [requiredResonance] 严禁在前端 UI 以任何形式
/// （数字、百分比、进度条等）展示给用户。
class Abnormality {
  /// 异想体唯一 ID，例如 "O-03-03"。
  final String id;

  /// 名称。
  final String name;

  /// 等级：ZAYIN / TETH / HE / WAW / ALEPH。
  final String grade;

  /// 语义特征标签，用于共鸣度匹配（不展示给用户，仅作为大模型输入）。
  final List<String> featureTags;

  /// 工作权重表，key 为 instinct/insight/attachment/repression。
  /// 取值范围 0.0~2.0。
  final Map<String, double> workTypeWeights;

  /// 累计记录天数解锁阈值，最大 30。
  final int requiredDays;

  /// 解锁所需共鸣度阈值。⚠️ Hidden from UI。
  final int requiredResonance;

  /// 当前累计共鸣度。⚠️ Hidden from UI，由 ResonanceService 累加。
  int currentResonance;

  /// 是否已解锁。
  bool isUnlocked;

  /// 是否为初始解锁异想体（true 时不进入提取池，自动解锁）。
  final bool isInitial;

  /// 解锁时间。
  DateTime? unlockDate;

  /// 能量值，0~100；新解锁时初始值 50。能量为 0 进入消极状态。
  int energyLevel;

  /// 逆卡巴拉计数器当前值。
  int qliphothCounter;

  /// 逆卡巴拉计数器最大值。
  final int qliphothMax;

  /// 突破类型。
  final BreachType breachType;

  /// 当 [breachType] = penaltyBox 时扣除的 PE Box 百分比（0~100）。
  final int? penaltyAmount;

  /// 当 [breachType] = escape 时每分钟扣除的 PE Box。
  final int? escapeDrain;

  /// 是否处于出逃状态（仅 BreachType.escape 可达）。
  bool isEscaped;

  /// 出逃开始时间（用于 30 分钟自动返回 / 每分钟扣 PE Box）。
  DateTime? escapeStartedAt;

  /// 解锁前需遮盖的描述。
  final String description;

  /// 解锁前需遮盖的管理备注。
  final String manageNote;

  /// 工作反馈文案。key 格式 `{workType}_{result}`，
  /// 例如 `instinct_success` / `instinct_fail`。
  final Map<String, String> workReactions;

  Abnormality({
    required this.id,
    required this.name,
    required this.grade,
    required this.featureTags,
    required this.workTypeWeights,
    required this.requiredDays,
    required this.requiredResonance,
    this.currentResonance = 0,
    this.isUnlocked = false,
    this.isInitial = false,
    this.unlockDate,
    this.energyLevel = 50,
    required this.qliphothCounter,
    required this.qliphothMax,
    required this.breachType,
    this.penaltyAmount,
    this.escapeDrain,
    this.isEscaped = false,
    this.escapeStartedAt,
    required this.description,
    required this.manageNote,
    required this.workReactions,
  });

  /// 是否处于消极状态（能量值归零）。
  /// 消极状态下所有工作权重 ×0.5。
  bool get isNegative => energyLevel <= 0;

  /// 档案库 / 列表使用的图标资源路径（按 ID 推导）。
  /// 缺图时上层应回退到默认图标占位。
  String get iconAssetPath => 'assets/abnormalities/icons/$id.png';

  /// 详情页 / 提取仪式使用的立绘资源路径（按 ID 推导）。
  /// 缺图时上层应回退到默认占位。
  String get portraitAssetPath =>
      'assets/abnormalities/portraits/$id.png';

  /// 从 JSON / sqflite map 反序列化。
  factory Abnormality.fromJson(Map<String, dynamic> json) {
    return Abnormality(
      id: json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as String,
      featureTags: (json['featureTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      workTypeWeights: (json['workTypeWeights'] as Map<dynamic, dynamic>)
          .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      requiredDays: (json['requiredDays'] as num).toInt(),
      requiredResonance: (json['requiredResonance'] as num).toInt(),
      currentResonance: (json['currentResonance'] as num?)?.toInt() ?? 0,
      isUnlocked: (json['isUnlocked'] as bool?) ?? false,
      isInitial: (json['isInitial'] as bool?) ?? false,
      unlockDate: json['unlockDate'] == null
          ? null
          : DateTime.parse(json['unlockDate'] as String),
      energyLevel: (json['energyLevel'] as num?)?.toInt() ?? 50,
      qliphothCounter: (json['qliphothCounter'] as num).toInt(),
      qliphothMax: (json['qliphothMax'] as num).toInt(),
      breachType: _parseBreach(json['breachType'] as String),
      penaltyAmount: (json['penaltyAmount'] as num?)?.toInt(),
      escapeDrain: (json['escapeDrain'] as num?)?.toInt(),
      isEscaped: (json['isEscaped'] as bool?) ?? false,
      escapeStartedAt: json['escapeStartedAt'] == null
          ? null
          : DateTime.parse(json['escapeStartedAt'] as String),
      description: json['description'] as String,
      manageNote: json['manageNote'] as String,
      workReactions: (json['workReactions'] as Map<dynamic, dynamic>)
          .map((k, v) => MapEntry(k as String, v as String)),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'featureTags': featureTags,
        'workTypeWeights': workTypeWeights,
        'requiredDays': requiredDays,
        'requiredResonance': requiredResonance,
        'currentResonance': currentResonance,
        'isUnlocked': isUnlocked,
        'isInitial': isInitial,
        'unlockDate': unlockDate?.toIso8601String(),
        'energyLevel': energyLevel,
        'qliphothCounter': qliphothCounter,
        'qliphothMax': qliphothMax,
        'breachType': breachType.name,
        'penaltyAmount': penaltyAmount,
        'escapeDrain': escapeDrain,
        'isEscaped': isEscaped,
        'escapeStartedAt': escapeStartedAt?.toIso8601String(),
        'description': description,
        'manageNote': manageNote,
        'workReactions': workReactions,
      };

  static BreachType _parseBreach(String raw) {
    switch (raw) {
      case 'escape':
        return BreachType.escape;
      case 'penaltyBox':
        return BreachType.penaltyBox;
      case 'none':
      default:
        return BreachType.none;
    }
  }
}
