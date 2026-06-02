import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../models/diary_entry.dart';
import '../services/resonance_service.dart';
import '../state/app_providers.dart';
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';

/// 预设认知滤网（标签）池。用户可在此基础上自定义。
const List<String> _presetCognitiveFilters = <String>[
  '忏悔',
  '宽恕',
  '善意',
  '信仰',
  '自我审视',
  '孤独',
  '怀旧',
  '编织',
  '故事',
  '倾听',
  '琐碎',
  '耐心',
  '愤怒',
  '恐惧',
  '希望',
];

/// 新建观测页（NewEntryPage）。
///
/// 仅记录"观测"，**不选择异想体也不选择工作类型**。
/// 共鸣度匹配由 ResonanceService 在保存后异步执行。
class NewEntryPage extends ConsumerStatefulWidget {
  const NewEntryPage({super.key});

  @override
  ConsumerState<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends ConsumerState<NewEntryPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();

  final Set<String> _selectedTags = <String>{};
  final List<String> _attachments = <String>[];

  bool _saving = false;

  @override
  void dispose() {
    _contentController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() => _attachments.add(file.path));
  }

  void _addCustomTag() {
    final String raw = _customTagController.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _selectedTags.add(raw);
      _customTagController.clear();
    });
  }

  Future<void> _save() async {
    final String content = _contentController.text.trim();
    if (content.isEmpty && _attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('// EMPTY OBSERVATION REJECTED'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final DiaryEntry entry = DiaryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        attachments: List<String>.from(_attachments),
        cognitiveFilters: _selectedTags.toList(growable: false),
        resonanceDeltas: const <String, int>{},
        createdAt: DateTime.now(),
      );

      // 1. 先持久化日记本体。
      await ref.read(diaryListProvider.notifier).addEntry(entry);

      // 2. 异步触发共鸣度匹配（写入隐藏字段）。
      final ResonanceService service =
          ref.read(resonanceServiceProvider);
      await service.scoreAndPersist(entry);

      // 3. 刷新已解锁/资格判断所需的列表。
      await ref.read(diaryListProvider.notifier).reload();
      await ref.read(abnormalitiesProvider.notifier).reload();

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NEW OBSERVATION'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TerminalText.title('// CONTENT'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    minLines: 6,
                    maxLines: 12,
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.onBackground,
                    ),
                    decoration: const InputDecoration(
                      hintText: '记录今日所见、所感、所行（支持 Markdown）...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  TerminalText.title('// COGNITIVE FILTERS'),
                  const SizedBox(height: 6),
                  const TerminalText(
                    '选择或自定义标签，作为认知滤网参与共鸣匹配。',
                    fontSize: 11,
                    color: AppColors.hint,
                  ),
                  const SizedBox(height: 12),
                  _buildTagSelector(),
                  const SizedBox(height: 12),
                  _buildCustomTagInput(),
                  if (_selectedTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSelectedTags(),
                  ],
                  const SizedBox(height: 24),
                  TerminalText.title('// EVIDENCE / ATTACHMENTS'),
                  const SizedBox(height: 8),
                  _buildAttachments(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: LCorpButton(
              label: _saving ? 'PROCESSING...' : 'SUBMIT OBSERVATION',
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _presetCognitiveFilters.map((t) {
        final bool active = _selectedTags.contains(t);
        return _TagChip(
          label: t,
          active: active,
          onTap: () {
            setState(() {
              if (active) {
                _selectedTags.remove(t);
              } else {
                _selectedTags.add(t);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCustomTagInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customTagController,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.onBackground,
            ),
            decoration: const InputDecoration(
              hintText: '添加自定义滤网（CONFIDENTIAL）',
              isDense: true,
            ),
            onSubmitted: (_) => _addCustomTag(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 38,
          child: LCorpButton(
            label: 'ADD',
            width: 80,
            height: 38,
            enableScanline: false,
            onPressed: _addCustomTag,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTags() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.alert),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalText(
            '// ACTIVE FILTERS',
            fontSize: 11,
            color: AppColors.alert,
            letterSpacing: 1.5,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedTags
                .map(
                  (t) => _TagChip(
                    label: t,
                    active: true,
                    onTap: () => setState(() => _selectedTags.remove(t)),
                    showRemove: true,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachments.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _attachments
                .asMap()
                .entries
                .map((e) => _AttachmentThumb(
                      path: e.value,
                      onRemove: () =>
                          setState(() => _attachments.removeAt(e.key)),
                    ))
                .toList(),
          ),
        if (_attachments.isNotEmpty) const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: LCorpButton(
            label: '+ ATTACH IMAGE',
            width: 200,
            height: 38,
            onPressed: _pickImage,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    this.active = false,
    this.onTap,
    this.showRemove = false,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool showRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.primary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TerminalText(
              '#$label',
              fontSize: 12,
              color: active ? AppColors.background : AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            if (showRemove) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 12,
                color: active ? AppColors.background : AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final File file = File(path);
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 1),
            color: AppColors.surface,
          ),
          child: file.existsSync()
              ? Image.file(file, fit: BoxFit.cover)
              : const Center(
                  child: Icon(Icons.broken_image,
                      color: AppColors.alert, size: 24),
                ),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.alert,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close,
                  size: 14, color: AppColors.background),
            ),
          ),
        ),
      ],
    );
  }
}
