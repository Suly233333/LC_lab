import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/abnormality_repository.dart';
import '../core/diary_repository.dart';
import '../models/abnormality.dart';
import '../models/diary_entry.dart';
import '../state/app_providers.dart';

/// 大模型匹配器接口。
///
/// 输入：日记内容（文本）+ 认知滤网（标签）+ 候选异想体（仅未解锁）
/// 输出：`{abnormalityId: delta}`，delta 为该日记对该异想体的共鸣度增量。
///
/// ⚠️ Prompt 约束：实际接入时需要求大模型仅返回严格 JSON，禁止任何
/// 解释性文本；此处的接口契约与之对齐。
abstract class LlmMatcher {
  Future<Map<String, int>> match({
    required String content,
    required List<String> cognitiveFilters,
    required List<Abnormality> candidates,
  });
}

/// 占位 mock 匹配器：根据日记文本/标签与候选 featureTags 的子串命中
/// 数量给出 0~10 的分值，用于在大模型尚未接入时驱动整套流程。
class HeuristicLlmMatcher implements LlmMatcher {
  const HeuristicLlmMatcher();

  @override
  Future<Map<String, int>> match({
    required String content,
    required List<String> cognitiveFilters,
    required List<Abnormality> candidates,
  }) async {
    final String haystack = (content + cognitiveFilters.join(' ')).toLowerCase();
    final Map<String, int> result = <String, int>{};
    for (final Abnormality a in candidates) {
      int score = 0;
      for (final String tag in a.featureTags) {
        final String t = tag.toLowerCase();
        if (t.isEmpty) continue;
        if (haystack.contains(t)) score += 5;
        for (final String filter in cognitiveFilters) {
          if (filter.toLowerCase() == t) score += 3;
        }
      }
      if (score > 15) score = 15; // 单条日记单异想体上限 15
      if (score > 0) result[a.id] = score;
    }
    return result;
  }
}

/// 共鸣度引擎。
///
/// 仅作用于"未解锁"的异想体；对每条新日记调用 [scoreAndPersist]：
/// 1. 收集所有 `isUnlocked == false` 的异想体作为候选；
/// 2. 调用 [LlmMatcher] 得到 `{abnormalityId: delta}`；
/// 3. 将 deltas **写入 DiaryEntry.resonanceDeltas（隐藏字段）**；
/// 4. 累加到对应 Abnormality.currentResonance（隐藏字段）。
///
/// ⚠️ 严禁将 deltas 与 currentResonance 暴露给 UI 层。
class ResonanceService {
  ResonanceService({
    required AbnormalityRepository abnormalityRepo,
    required DiaryRepository diaryRepo,
    LlmMatcher? matcher,
  // ignore: prefer_initializing_formals
  })  : _abnRepo = abnormalityRepo,
        // ignore: prefer_initializing_formals
        _diaryRepo = diaryRepo,
        _matcher = matcher ?? const HeuristicLlmMatcher();

  final AbnormalityRepository _abnRepo;
  final DiaryRepository _diaryRepo;
  final LlmMatcher _matcher;

  /// 处理一条新日记：调用大模型 → 写回 deltas → 累加到异想体。
  /// 返回该日记最终的 [DiaryEntry]（含 deltas）。
  Future<DiaryEntry> scoreAndPersist(DiaryEntry entry) async {
    // 仅未解锁参与匹配。
    final List<Abnormality> all = await _abnRepo.getAll();
    final List<Abnormality> candidates =
        all.where((a) => !a.isUnlocked).toList(growable: false);

    if (candidates.isEmpty) {
      // 无候选时直接持久化日记，deltas 保持空。
      await _diaryRepo.update(entry);
      return entry;
    }

    final Map<String, int> deltas = await _matcher.match(
      content: entry.content,
      cognitiveFilters: entry.cognitiveFilters,
      candidates: candidates,
    );

    // 回填日记 deltas（隐藏字段）。
    final DiaryEntry updated = entry.copyWith(resonanceDeltas: deltas);
    await _diaryRepo.update(updated);

    // 累加到异想体 currentResonance。
    for (final MapEntry<String, int> e in deltas.entries) {
      if (e.value <= 0) continue;
      await _abnRepo.addResonance(e.key, e.value);
    }
    return updated;
  }
}

/// LLM 匹配器 Provider，可在测试或上线时替换为真实大模型实现。
final llmMatcherProvider = Provider<LlmMatcher>(
  (ref) => const HeuristicLlmMatcher(),
);

/// ResonanceService Provider。
final resonanceServiceProvider = Provider<ResonanceService>((ref) {
  return ResonanceService(
    abnormalityRepo: ref.watch(abnormalityRepositoryProvider),
    diaryRepo: ref.watch(diaryRepositoryProvider),
    matcher: ref.watch(llmMatcherProvider),
  );
});
