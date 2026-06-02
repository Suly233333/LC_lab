import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/diary_entry.dart';
import '../state/app_providers.dart';
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';
import 'abnormality_gallery_page.dart';
import 'new_entry_page.dart';

/// 观测日志列表页（Observation Logs）。
///
/// 严格遵守"神秘感原则"：不展示任何共鸣度数值、增量、进度条或百分比。
/// 仅列出日记的元信息（时间、标签、文本预览）与附件数量提示。
class ObservationLogsPage extends ConsumerWidget {
  const ObservationLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DiaryEntry>> entriesAsync =
        ref.watch(diaryListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OBSERVATION LOGS'),
        actions: [
          IconButton(
            tooltip: 'ABNORMALITY GALLERY',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AbnormalityGalleryPage(),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          Positioned.fill(
            child: entriesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: TerminalText.alert('LOG STREAM ERROR: $e'),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return _EmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _LogCard(entry: entries[i]),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: LCorpButton(
              label: '+ NEW OBSERVATION',
              onPressed: () => _openNewEntry(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNewEntry(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const NewEntryPage()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined,
                color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            TerminalText.title('// NO OBSERVATION ON RECORD'),
            const SizedBox(height: 8),
            const TerminalText(
              '记录今日的观测，每一份观测都将参与共鸣匹配。',
              color: AppColors.hint,
              fontSize: 12,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends ConsumerWidget {
  const _LogCard({required this.entry});

  final DiaryEntry entry;

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String preview = _previewOf(entry.content);
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: InkWell(
        onLongPress: () => _confirmDelete(context, ref, entry),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TerminalText(
                    _fmt.format(entry.createdAt),
                    fontSize: 12,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                  const Spacer(),
                  if (entry.attachments.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.attach_file,
                            color: AppColors.alert, size: 14),
                        const SizedBox(width: 4),
                        TerminalText(
                          '${entry.attachments.length}',
                          fontSize: 12,
                          color: AppColors.alert,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TerminalText(
                preview,
                fontSize: 14,
                color: AppColors.onBackground,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.cognitiveFilters.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.cognitiveFilters
                      .map((tag) => _TagChip(label: tag))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _previewOf(String content) {
    final String trimmed = content.trim();
    if (trimmed.isEmpty) return '(空白观测)';
    return trimmed;
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, DiaryEntry e) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.primary, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        title: const TerminalText('// DELETE OBSERVATION?',
            fontSize: 16,
            color: AppColors.primary,
            fontWeight: FontWeight.bold),
        content: const TerminalText(
          '此操作不可撤销，共鸣度增量记录将一并清除。',
          fontSize: 12,
          color: AppColors.onBackground,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(diaryListProvider.notifier).deleteEntry(e.id);
    }
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
      child: TerminalText(
        '#$label',
        fontSize: 11,
        color: AppColors.primary,
        letterSpacing: 1.0,
      ),
    );
  }
}
