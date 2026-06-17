import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../models/diary_entry.dart';
import '../services/attachment_service.dart';
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

/// 异想体对话页（Attachment）。
///
/// - 自由对话（GLM/CharGLM 接入，离线时降级 Mock）
/// - 异想体会按概率主动提问
/// - 直接 pop 关闭，不再结算"工作"
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
        title: Text('COMMUNICATION  /  ${abn?.name ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'RELATED OBSERVATIONS',
            icon: const Icon(Icons.article_outlined),
            onPressed: abn == null ? null : () => _showRelatedLogs(abn),
          ),
        ],
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !_sending,
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
              onPressed: _sending ? null : _send,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRelatedLogs(Abnormality abnormality) async {
    final List<DiaryEntry> entries =
        ref.read(diaryListProvider).valueOrNull ?? const <DiaryEntry>[];
    final List<DiaryEntry> related = entries
        .where((entry) => (entry.resonanceDeltas[abnormality.id] ?? 0) > 0)
        .toList(growable: false)
      ..sort((a, b) {
        final int byScore = (b.resonanceDeltas[abnormality.id] ?? 0)
            .compareTo(a.resonanceDeltas[abnormality.id] ?? 0);
        if (byScore != 0) return byScore;
        return b.createdAt.compareTo(a.createdAt);
      });

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary, width: 1),
      ),
      builder: (_) => _RelatedLogsSheet(
        abnormality: abnormality,
        entries: related.take(5).toList(growable: false),
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
          '// 与异想体自由对话。',
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
                borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
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

class _RelatedLogsSheet extends StatelessWidget {
  const _RelatedLogsSheet({
    required this.abnormality,
    required this.entries,
  });

  final Abnormality abnormality;
  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '// RELATED OBSERVATIONS / ${abnormality.name}',
              style: const TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'NO RELATED OBSERVATION FOUND',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.hint,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) => _RelatedLogTile(entry: entries[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RelatedLogTile extends StatelessWidget {
  const _RelatedLogTile({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final String content = entry.content.trim().isEmpty
        ? '(空白观测)'
        : entry.content.trim();
    final String date = entry.createdAt.toIso8601String().substring(0, 10);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.primary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.onBackground,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (entry.cognitiveFilters.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: entry.cognitiveFilters
                  .map(
                    (tag) => Text(
                      '#$tag',
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFontFamily,
                        color: AppColors.hint,
                        fontSize: 11,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}
