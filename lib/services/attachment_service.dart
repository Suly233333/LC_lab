import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/abnormality.dart';

/// 沟通工作 AI 服务（占位 mock）。
///
/// 在大模型接入前，使用基于 [Abnormality.featureTags] 与 [Abnormality.workReactions]
/// 的简单回复策略；并按概率主动向员工提问。
class AttachmentService {
  AttachmentService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// 生成一条来自异想体的回复。
  ///
  /// `userMessage` 为员工最新发言；返回值为异想体回复文本，
  /// 实际接入大模型时只需替换该实现。
  Future<String> mockResponse({
    required Abnormality abnormality,
    required String userMessage,
  }) async {
    // 模拟网络往返
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final List<String> openings = [
      abnormality.workReactions['attachment_success'] ?? '...',
      '它静静地看着你，似乎在等待。',
      '空气凝滞了一瞬，然后流动起来。',
    ];

    final String tag = abnormality.featureTags.isEmpty
        ? '存在'
        : abnormality.featureTags[
            _random.nextInt(abnormality.featureTags.length)];

    if (userMessage.trim().isEmpty) {
      return '${openings[_random.nextInt(openings.length)]}（关于「$tag」）';
    }

    return '${openings[_random.nextInt(openings.length)]}\n关于"$tag"——你又是怎么看的？';
  }

  /// 异想体偶尔会主动提问；返回 null 表示本次不发问。
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

final attachmentServiceProvider =
    Provider<AttachmentService>((ref) => AttachmentService());
