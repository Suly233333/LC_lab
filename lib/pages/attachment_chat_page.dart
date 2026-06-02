import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../models/work_log.dart' show WorkType;
import '../services/attachment_service.dart';
import '../services/work_service.dart';
import '../state/app_providers.dart';
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';

/// 聊天消息条目。
class _ChatMessage {
  _ChatMessage({required this.fromUser, required this.text, this.isQuestion = false});
  final bool fromUser;
  final String text;
  final bool isQuestion;
}

/// 沟通工作对话页（Attachment）。
///
/// - 自由对话（AttachmentService.mockResponse 占位，未来替换为真实大模型）
/// - 异想体会按概率主动提问
/// - 结束对话（CLOSE SESSION）时调用 WorkService 结算一次沟通工作
class AttachmentChatPage extends ConsumerStatefulWidget {
  const AttachmentChatPage({super.key, required this.abnormalityId});
  final String abnormalityId;

  @override
  ConsumerState<AttachmentChatPage> createState() =>
      _AttachmentChatPageState();
}

class _AttachmentChatPageState extends ConsumerState<AttachmentChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  bool _sending = false;
  bool _settling = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Abnormality? _resolveAbnormality() {
    return ref.watch(abnormalitiesProvider).whenOrNull(
          data: (list) => list.firstWhere(
            (a) => a.id == widget.abnormalityId,
            orElse: () => list.first,
          ),
        );
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final Abnormality? abn = _resolveAbnormality();
    if (abn == null) return;

    setState(() {
      _messages.add(_ChatMessage(fromUser: true, text: text));
      _input.clear();
      _sending = true;
    });
    _scrollToBottom();

    final AttachmentService service = ref.read(attachmentServiceProvider);
    final List<AttachmentTurn> history = _messages
        .map((m) => AttachmentTurn(fromUser: m.fromUser, text: m.text))
        .toList(growable: false);
    String reply;
    try {
      reply = await service.respond(
        abnormality: abn,
        history: history,
      );
    } catch (e) {
      reply = '（与它的连接出现了杂音…）\n[$e]';
    }
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(fromUser: false, text: reply));
    });
    _scrollToBottom();

    // 异想体偶尔反问
    final String? question = service.maybeAskQuestion(abnormality: abn);
    if (question != null && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          fromUser: false,
          text: question,
          isQuestion: true,
        ));
      });
      _scrollToBottom();
    }

    if (mounted) setState(() => _sending = false);
  }

  Future<void> _closeSession() async {
    if (_settling) return;
    if (_messages.where((m) => m.fromUser).isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _settling = true);
    try {
      final WorkOutcome outcome = await ref
          .read(workServiceProvider)
          .performWork(
            abnormalityId: widget.abnormalityId,
            workType: WorkType.attachment,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(outcome.success
              ? '// SESSION SUCCEEDED  +${outcome.peBoxGained} PE'
              : '// SESSION FAILED'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('// $e')),
      );
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Abnormality? abn = _resolveAbnormality();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ATTACHMENT  /  ${abn?.name ?? ''}'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const _Hint()
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) =>
                              _Bubble(message: _messages[i]),
                        ),
                ),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_sending && !_settling,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    color: AppColors.onBackground,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '说点什么...',
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 38,
                child: LCorpButton(
                  label: 'SEND',
                  height: 38,
                  enableScanline: false,
                  onPressed: (_sending || _settling) ? null : _send,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: LCorpButton(
              label: _settling
                  ? 'SETTLING...'
                  : 'CLOSE SESSION (LOG WORK)',
              height: 38,
              onPressed: _settling ? null : _closeSession,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Text(
          '// 与异想体自由对话，结束时点击 CLOSE SESSION 结算工作。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.monoFontFamily,
            color: AppColors.hint,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool user = message.fromUser;
    final Color border = message.isQuestion
        ? AppColors.alert
        : (user ? AppColors.primary : AppColors.primary);
    final Color bg = user ? AppColors.primary : AppColors.surface;
    final Color fg = user ? AppColors.background : AppColors.onBackground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            user ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isQuestion)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '? QUESTION',
                        style: TextStyle(
                          fontFamily: AppTheme.monoFontFamily,
                          color: AppColors.alert,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: fg,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
