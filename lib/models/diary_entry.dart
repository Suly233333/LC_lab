/// 日记条目（DiaryEntry）。
///
/// 日记是主管对现实进行"观测"并转化为共鸣度的唯一途径，
/// **仅用于解锁异想体**，与解锁后的工作系统无关。
///
/// 重要：本模型 **不包含** `abnormalityId` 与 `workType` 字段。
/// 共鸣度匹配由大模型在所有未解锁异想体的 `featureTags` 上计算后写入
/// [resonanceDeltas]，禁止在 UI 直接展示。
class DiaryEntry {
  /// 主键 ID（UUID 或时间戳）。
  final String id;

  /// Markdown 文本内容。
  final String content;

  /// 附件路径（图片 / 音频本地路径或 URL）。
  final List<String> attachments;

  /// 认知滤网（标签）：预设 + 用户自定义。
  final List<String> cognitiveFilters;

  /// ⚠️ Hidden from UI：本条日记对各异想体的共鸣度增量。
  /// key = abnormalityId，value = delta。
  final Map<String, int> resonanceDeltas;

  /// 创建时间。
  final DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.content,
    this.attachments = const [],
    this.cognitiveFilters = const [],
    this.resonanceDeltas = const {},
    required this.createdAt,
  });

  /// 拷贝并替换部分字段（用于在大模型返回 deltas 后回填）。
  DiaryEntry copyWith({
    String? id,
    String? content,
    List<String>? attachments,
    List<String>? cognitiveFilters,
    Map<String, int>? resonanceDeltas,
    DateTime? createdAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      cognitiveFilters: cognitiveFilters ?? this.cognitiveFilters,
      resonanceDeltas: resonanceDeltas ?? this.resonanceDeltas,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      cognitiveFilters:
          (json['cognitiveFilters'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      resonanceDeltas:
          (json['resonanceDeltas'] as Map<dynamic, dynamic>? ?? const {})
              .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'attachments': attachments,
        'cognitiveFilters': cognitiveFilters,
        'resonanceDeltas': resonanceDeltas,
        'createdAt': createdAt.toIso8601String(),
      };
}
