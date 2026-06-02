/// 每日状态（DailyState）。
///
/// 管理每日提取候选与解锁配额：
/// - 每天随机抽取 3 个候选异想体（写入 [extractionCandidates]）
/// - 用户每日最多解锁 1 个（[unlockedCount] 上限 1）
/// - 按自然日 0:00 重置（[shouldReset] / [forDate]）
class DailyState {
  /// 每日最大可解锁数。
  static const int dailyUnlockLimit = 1;

  /// 每日候选数。
  static const int extractionPoolSize = 3;

  /// 该状态对应的自然日（仅取年月日，时分秒置零）。
  final DateTime date;

  /// 当日候选异想体 ID 列表，长度 ≤ [extractionPoolSize]。
  final List<String> extractionCandidates;

  /// 当日已解锁数，硬上限 [dailyUnlockLimit]。
  int unlockedCount;

  DailyState({
    required this.date,
    this.extractionCandidates = const [],
    this.unlockedCount = 0,
  });

  /// 创建一个仅含日期的对象（候选与计数为空）。
  factory DailyState.forDate(DateTime moment) {
    final DateTime day = DateTime(moment.year, moment.month, moment.day);
    return DailyState(date: day);
  }

  /// 是否仍可解锁（未达每日上限）。
  bool get canUnlock => unlockedCount < dailyUnlockLimit;

  /// 给定时间是否需要刷新到新一天的状态。
  bool shouldReset(DateTime now) {
    return now.year != date.year ||
        now.month != date.month ||
        now.day != date.day;
  }

  /// 复制并替换部分字段。
  DailyState copyWith({
    DateTime? date,
    List<String>? extractionCandidates,
    int? unlockedCount,
  }) {
    return DailyState(
      date: date ?? this.date,
      extractionCandidates: extractionCandidates ?? this.extractionCandidates,
      unlockedCount: unlockedCount ?? this.unlockedCount,
    );
  }

  factory DailyState.fromJson(Map<String, dynamic> json) {
    return DailyState(
      date: DateTime.parse(json['date'] as String),
      extractionCandidates:
          (json['extractionCandidates'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toList(),
      unlockedCount: (json['unlockedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'extractionCandidates': extractionCandidates,
        'unlockedCount': unlockedCount,
      };
}
