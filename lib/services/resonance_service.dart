import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/abnormality_repository.dart';
import '../core/diary_repository.dart';
import '../core/glm_client.dart';
import '../core/secrets.dart';
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

/// 智谱 GLM 实现的共鸣度匹配器。
///
/// 严格约束：仅返回 JSON 对象 `{abnormalityId: delta}`，delta ∈ [0, 15]。
class GlmLlmMatcher implements LlmMatcher {
  GlmLlmMatcher({GlmClient? client, String? model})
      : _client = client ?? GlmClient(),
        _model = model ?? Secrets.glmResonanceModel;

  final GlmClient _client;
  final String _model;

  static const String _systemPrompt = '''
你是脑叶公司（Lobotomy Corporation）共鸣度匹配引擎。
任务：根据用户当天的日记内容与用户主动选择的"认知滤网"标签，
判断这条日记与给定的若干"异想体（Abnormality）"在语义上的共鸣强度。

严格规则：
1. 仅基于异想体的 featureTags（语义特征）来判断；不允许凭空联想。
2. 给每个异想体一个整数共鸣度增量 delta，范围 0 到 15。
   - 0 表示几乎无关；
   - 5 左右表示有间接共鸣；
   - 10 以上表示强共鸣；
   - 15 仅在日记内容明显对应大量 featureTags 时给出。
3. 输出必须是合法 JSON 对象，键为异想体 ID，值为整数 delta。
   不要输出任何解释、Markdown、注释或额外文字。
4. 不要返回未在候选列表中的异想体 ID。
5. delta 为 0 的项可以省略。
''';

  @override
  Future<Map<String, int>> match({
    required String content,
    required List<String> cognitiveFilters,
    required List<Abnormality> candidates,
  }) async {
    if (candidates.isEmpty) return const <String, int>{};

    final List<Map<String, dynamic>> candidatePayload = candidates
        .map((a) => {
              'id': a.id,
              'featureTags': a.featureTags,
            })
        .toList(growable: false);

    final Map<String, dynamic> userPayload = {
      'diary': content,
      'cognitiveFilters': cognitiveFilters,
      'candidates': candidatePayload,
    };

    final String reply = await _client.chat(
      model: _model,
      temperature: 0.2,
      responseFormat: const {'type': 'json_object'},
      messages: [
        const GlmMessage(role: 'system', content: _systemPrompt),
        GlmMessage(
          role: 'user',
          content: json.encode(userPayload),
        ),
      ],
    );

    return _parseReply(reply, candidates);
  }

  Map<String, int> _parseReply(String reply, List<Abnormality> candidates) {
    final Set<String> validIds = candidates.map((a) => a.id).toSet();
    final Map<String, int> out = <String, int>{};
    try {
      final dynamic decoded = json.decode(_extractJson(reply));
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((k, v) {
          if (!validIds.contains(k)) return;
          if (v is num) {
            int delta = v.toInt();
            if (delta < 0) delta = 0;
            if (delta > 15) delta = 15;
            if (delta > 0) out[k] = delta;
          }
        });
      }
    } catch (_) {
      // 解析失败：返回空表，由调用方决定降级策略。
    }
    return out;
  }

  /// 从可能含有围栏代码块的文本中抽出 JSON 主体。
  String _extractJson(String raw) {
    final String s = raw.trim();
    if (s.startsWith('{') && s.endsWith('}')) return s;
    final int start = s.indexOf('{');
    final int end = s.lastIndexOf('}');
    if (start >= 0 && end > start) return s.substring(start, end + 1);
    return s;
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

    Map<String, int> deltas;
    try {
      deltas = await _matcher.match(
        content: entry.content,
        cognitiveFilters: entry.cognitiveFilters,
        candidates: candidates,
      );
    } catch (_) {
      // 大模型调用失败时降级为本地启发式，确保流程不被阻断。
      deltas = await const HeuristicLlmMatcher().match(
        content: entry.content,
        cognitiveFilters: entry.cognitiveFilters,
        candidates: candidates,
      );
    }

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

/// LLM 匹配器 Provider。默认使用 GLM；测试 / 离线时可覆盖为
/// [HeuristicLlmMatcher]。
final llmMatcherProvider = Provider<LlmMatcher>(
  (ref) => GlmLlmMatcher(),
);

/// ResonanceService Provider。
final resonanceServiceProvider = Provider<ResonanceService>((ref) {
  return ResonanceService(
    abnormalityRepo: ref.watch(abnormalityRepositoryProvider),
    diaryRepo: ref.watch(diaryRepositoryProvider),
    matcher: ref.watch(llmMatcherProvider),
  );
});
