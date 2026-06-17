/// 异想体（Abnormality）核心数据模型 — 精简版（v1.1）。
///
/// ⚠️ 共鸣度禁令（见 AGENT.md §2.1）：
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

  /// 累计记录天数解锁阈值。
  final int requiredDays;

  /// 解锁所需共鸣度阈值。⚠️ Hidden from UI。
  final int requiredResonance;

  /// 当前累计共鸣度。⚠️ Hidden from UI，由 ResonanceService 累加。
  int currentResonance;

  /// 是否已解锁。
  bool isUnlocked;

  /// 是否为初始解锁异想体（true 时跳过共鸣度判定，自动解锁）。
  final bool isInitial;

  /// 解锁时间。
  DateTime? unlockDate;

  /// 解锁前需遮盖的描述。
  final String description;

  /// 解锁前需遮盖的管理备注。
  final String manageNote;

  Abnormality({
    required this.id,
    required this.name,
    required this.grade,
    required this.featureTags,
    required this.requiredDays,
    required this.requiredResonance,
    this.currentResonance = 0,
    this.isUnlocked = false,
    this.isInitial = false,
    this.unlockDate,
    required this.description,
    required this.manageNote,
  });

  /// 档案库 / 列表使用的图标资源路径（按 ID 推导）。
  /// 缺图时上层应回退到默认图标占位。
  String get iconAssetPath => 'assets/abnormalities/icons/$name.png';

  /// 详情页 / 提取仪式使用的立绘资源路径（按 ID 推导）。
  /// 缺图时上层应回退到默认占位。
  String get portraitAssetPath =>
      'assets/abnormalities/portraits/$name.png';

  /// 从 JSON / sqflite map 反序列化。
  factory Abnormality.fromJson(Map<String, dynamic> json) {
    return Abnormality(
      id: json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as String,
      featureTags: (json['featureTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      requiredDays: (json['requiredDays'] as num).toInt(),
      requiredResonance: (json['requiredResonance'] as num).toInt(),
      currentResonance: (json['currentResonance'] as num?)?.toInt() ?? 0,
      isUnlocked: (json['isUnlocked'] as bool?) ?? false,
      isInitial: (json['isInitial'] as bool?) ?? false,
      unlockDate: json['unlockDate'] == null
          ? null
          : DateTime.parse(json['unlockDate'] as String),
      description: json['description'] as String,
      manageNote: json['manageNote'] as String,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'featureTags': featureTags,
        'requiredDays': requiredDays,
        'requiredResonance': requiredResonance,
        'currentResonance': currentResonance,
        'isUnlocked': isUnlocked,
        'isInitial': isInitial,
        'unlockDate': unlockDate?.toIso8601String(),
        'description': description,
        'manageNote': manageNote,
      };
}
