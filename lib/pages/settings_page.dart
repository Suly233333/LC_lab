import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../core/preset_loader.dart';
import '../core/secrets.dart';
import '../core/theme.dart';
import '../models/abnormality.dart';
import '../models/diary_entry.dart';
import '../state/app_providers.dart';
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  bool get _hasGlmKey =>
      Secrets.glmApiKey.isNotEmpty &&
      Secrets.glmApiKey != 'YOUR_GLM_API_KEY_HERE';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const Positioned.fill(child: LCorpGridBackground()),
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusPanel(
              title: 'GLM LINK',
              lines: [
                _hasGlmKey ? 'API KEY: CONFIGURED' : 'API KEY: MOCK FALLBACK',
                'CHAT MODEL: ${Secrets.glmChatModel}',
                'MATCH MODEL: ${Secrets.glmResonanceModel}',
              ],
            ),
            const SizedBox(height: 12),
            _ActionPanel(
              title: 'DATA',
              children: [
                LCorpButton(
                  label: 'EXPORT DATA',
                  enableScanline: false,
                  onPressed: () => _exportData(context, ref),
                ),
                const SizedBox(height: 8),
                LCorpButton(
                  label: 'RESET LOCAL DATA',
                  enableScanline: false,
                  onPressed: () => _confirmReset(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ActionPanel(
              title: 'DEBUG',
              children: [
                SwitchListTile(
                  value: false,
                  onChanged: null,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'RESONANCE TRACE',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.hint,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: const Text(
                    'Disabled to preserve hidden resonance values.',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.hint,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _StatusPanel(
              title: 'ABOUT',
              lines: [
                'PROJECT MOON LIFE RECORD',
                'L-CORP EDITION / v1.2 WORKSPACE',
                'LOGS / GALLERY / COMMS / SYSTEM',
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final List<DiaryEntry> diaries =
        ref.read(diaryListProvider).valueOrNull ?? const <DiaryEntry>[];
    final List<Abnormality> abnormalities =
        ref.read(abnormalitiesProvider).valueOrNull ?? const <Abnormality>[];
    final String payload = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'diaryEntries': diaries.map((e) => e.toJson()).toList(growable: false),
      'abnormalities':
          abnormalities.map((a) => a.toJson()).toList(growable: false),
    });
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('// EXPORT COPIED TO CLIPBOARD')),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('// RESET LOCAL DATA?'),
        content: const Text('此操作会清空本地观测和异想体状态，然后重新载入 presets。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final diaryRepo = ref.read(diaryRepositoryProvider);
    final abnRepo = ref.read(abnormalityRepositoryProvider);
    await diaryRepo.clearAll();
    await abnRepo.clearAll();
    final List<Abnormality> bootstrapped =
        await PresetLoader.bootstrapAbnormalities();
    await abnRepo.upsertAll(bootstrapped);
    await ref.read(diaryListProvider.notifier).reload();
    await ref.read(abnormalitiesProvider.notifier).reload();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('// LOCAL DATA RESET COMPLETE')),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// $title',
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final String line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                line,
                style: const TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  color: AppColors.hint,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '// $title',
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
