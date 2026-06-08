import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/glm_client.dart';
import '../core/secrets.dart';
import '../models/abnormality.dart';

/// 简单对话回合载体（用户 / 异想体）。
class AttachmentTurn {
  const AttachmentTurn({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}

/// 沟通工作 AI 服务。
///
/// - 真实实现 [GlmAttachmentService] 调用智谱 GLM，按异想体设定生成对话。
/// - 占位实现 [MockAttachmentService] 在网络异常或测试时降级使用。
abstract class AttachmentService {
  /// 生成一条来自异想体的回复。
  ///
  /// [history] 是按时间正序的完整对话上下文（含本次用户消息）。
  Future<String> respond({
    required Abnormality abnormality,
    required List<AttachmentTurn> history,
  });

  /// 异想体偶尔会主动提问；返回 null 表示本次不发问。
  String? maybeAskQuestion({required Abnormality abnormality});
}

/// CharGLM 实现：为每个异想体构造专属 system prompt + meta 角色信息，
/// 让模型严格扮演。
class GlmAttachmentService implements AttachmentService {
  GlmAttachmentService({GlmClient? client, String? model, Random? random})
      : _client = client ?? GlmClient(),
        _model = model ?? Secrets.glmChatModel,
        _random = random ?? Random();

  final GlmClient _client;
  final String _model;
  final Random _random;

  /// 玩家在游戏中的固定身份。
  static const String _userName = '主管';
  static const String _userInfo =
      '脑叶公司（Lobotomy Corporation）的主管，负责异想体的收容与管理工作。'
      '态度冷静、克制，正在与该异想体进行 attachment（沟通）工作。';

  bool get _isCharGlm => _model.toLowerCase().startsWith('charglm');

  String _systemPromptFor(Abnormality a) {
    final String tags = a.featureTags.join('、');
    return '''
你正在扮演脑叶公司（Lobotomy Corporation）收容设施中的一只异想体。
你不是 AI，不是助手，不要破坏角色，也不要谈论"模型/规则/系统"。

# 异想体档案
- ID：${a.id}
- 名称：${a.name}
- 等级：${a.grade}
- 外观与设定：${a.description}
- 管理备注：${a.manageNote}
- 语义特征（featureTags）：$tags

# 对话规则
1. 对方是来到收容间与你沟通的脑叶公司员工"主管"。
2. 严格保持自己的人格、节奏与说话方式：
   - 行为方式应符合 featureTags 与 description。
3. 回复尽量简短克制，1~3 句，避免长篇说教；可以用括号描写动作或氛围。
4. 不要透露任何关于"共鸣度 / currentResonance / requiredResonance"的具体数值。
5. 不要使用 Markdown 标题；可以使用普通中文标点。
6. 不要扮演员工或主管的发言；只输出该异想体此刻对当前对话的回应。
7. 用中文回应。
''';
  }

  /// CharGLM 专用 meta：把异想体设定结构化注入。
  Map<String, dynamic> _metaFor(Abnormality a) {
    final String tags = a.featureTags.join('、');
    final String botInfo =
        '${a.name}（${a.id} / ${a.grade}）。${a.description} '
        '管理备注：${a.manageNote} '
        '语义特征：$tags。'
        '严禁透露共鸣度数值；不要替主管发言；保持人格不要破戒。';
    return {
      'bot_name': a.name,
      'bot_info': botInfo,
      'user_name': _userName,
      'user_info': _userInfo,
    };
  }

  @override
  Future<String> respond({
    required Abnormality abnormality,
    required List<AttachmentTurn> history,
  }) async {
    final List<GlmMessage> msgs = <GlmMessage>[];

    // CharGLM 推荐用 meta 承载角色信息；通用 GLM 则在 system prompt 注入。
    if (!_isCharGlm) {
      msgs.add(
        GlmMessage(role: 'system', content: _systemPromptFor(abnormality)),
      );
    }
    for (final AttachmentTurn t in history) {
      msgs.add(GlmMessage(
        role: t.fromUser ? 'user' : 'assistant',
        content: t.text,
      ));
    }
    final String reply = await _client.chat(
      model: _model,
      temperature: 0.85,
      messages: msgs,
      meta: _isCharGlm ? _metaFor(abnormality) : null,
    );
    return reply.trim().isEmpty ? '（它沉默着，没有回应。）' : reply.trim();
  }

  @override
  String? maybeAskQuestion({required Abnormality abnormality}) {
    if (_random.nextDouble() > 0.35) return null;
    if (abnormality.featureTags.isEmpty) return null;
    final String tag = abnormality.featureTags[
        _random.nextInt(abnormality.featureTags.length)];
    final List<String> templates = [
      '你也曾经感受过「$tag」吗？',
      '当你独自一人时，「$tag」会浮现吗？',
      '人类是怎样面对「$tag」的？',
    ];
    return templates[_random.nextInt(templates.length)];
  }
}

/// 占位实现：基于 featureTags 的简单回复，用于离线降级。
class MockAttachmentService implements AttachmentService {
  MockAttachmentService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// 兼容旧 API：保留 mockResponse 入口供测试调用。
  Future<String> mockResponse({
    required Abnormality abnormality,
    required String userMessage,
  }) async {
    return respond(
      abnormality: abnormality,
      history: [AttachmentTurn(fromUser: true, text: userMessage)],
    );
  }

  @override
  Future<String> respond({
    required Abnormality abnormality,
    required List<AttachmentTurn> history,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final List<String> openings = [
      '它静静地看着你，似乎在等待。',
      '空气凝滞了一瞬，然后流动起来。',
      '它没有说话，只是缓慢地呼吸。',
    ];

    final String tag = abnormality.featureTags.isEmpty
        ? '存在'
        : abnormality.featureTags[
            _random.nextInt(abnormality.featureTags.length)];

    final AttachmentTurn? last =
        history.isEmpty ? null : history.last;
    if (last == null || last.text.trim().isEmpty) {
      return '${openings[_random.nextInt(openings.length)]}（关于「$tag」）';
    }
    return '${openings[_random.nextInt(openings.length)]}\n关于"$tag"——你又是怎么看的？';
  }

  @override
  String? maybeAskQuestion({required Abnormality abnormality}) {
    if (_random.nextDouble() > 0.4) return null;
    if (abnormality.featureTags.isEmpty) return null;
    final String tag = abnormality.featureTags[
        _random.nextInt(abnormality.featureTags.length)];
    final List<String> templates = [
      '你也曾经感受过「$tag」吗？',
      '当你独自一人时，「$tag」会浮现吗？',
      '人类是怎样面对「$tag」的？',
    ];
    return templates[_random.nextInt(templates.length)];
  }
}

/// 默认接入 GLM；测试 / 离线时可覆盖为 [MockAttachmentService]。
final attachmentServiceProvider = Provider<AttachmentService>(
  (ref) => GlmAttachmentService(),
);
