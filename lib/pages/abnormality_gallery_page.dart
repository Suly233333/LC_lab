import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../models/daily_state.dart';
import '../services/extraction_service.dart';
import '../state/app_providers.dart';
import '../widgets/caution_overlay.dart';
import '../widgets/extraction_ceremony_widget.dart';
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';
import 'abnormality_detail_page.dart';

/// 异想体档案库页（Abnormality Gallery）。
///
/// - 已解锁：展示名称、等级、缩略描述。
/// - 未解锁：整张卡片被「黄黑斜纹 CLASSIFIED」遮盖板覆盖，仅露出等级标签。
/// - 不展示任何共鸣度数值 / 进度条。
class AbnormalityGalleryPage extends ConsumerWidget {
  const AbnormalityGalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Abnormality>> async =
        ref.watch(abnormalitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ABNORMALITY GALLERY'),
        actions: [
          IconButton(
            tooltip: 'DAILY EXTRACTION',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () => _runExtraction(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          Positioned.fill(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('// ARCHIVE ERROR: $e')),
              data: (list) => _buildGrid(context, ref, list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, WidgetRef ref, List<Abnormality> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('// NO ENTRIES IN ARCHIVE',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.hint,
              letterSpacing: 1.5,
            )),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) => _AbnormalityCard(abnormality: list[i]),
    );
  }

  Future<void> _runExtraction(BuildContext context, WidgetRef ref) async {
    final ExtractionService service = ref.read(extractionServiceProvider);
    final DailyState daily = ref.read(dailyStateProvider).value ??
        DailyState.forDate(DateTime.now());

    if (!daily.canUnlock) {
      _showSnack(context, '// DAILY UNLOCK QUOTA REACHED');
      return;
    }

    final List<Abnormality> candidates =
        await service.rollDailyCandidates();
    if (!context.mounted) return;
    if (candidates.isEmpty) {
      _showSnack(context, '// NO ELIGIBLE TARGETS — KEEP OBSERVING');
      return;
    }

    final Abnormality? picked = await showDialog<Abnormality>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CandidatePickerDialog(candidates: candidates),
    );
    if (picked == null) return;

    final bool ok = await service.unlockFromCandidates(picked.id);
    if (!context.mounted) return;
    if (!ok) {
      _showSnack(context, '// EXTRACTION REFUSED');
      return;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: ExtractionCeremonyWidget(abnormality: picked),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

class _CandidatePickerDialog extends StatelessWidget {
  const _CandidatePickerDialog({required this.candidates});
  final List<Abnormality> candidates;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.all(20),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '// SELECT ONE CANDIDATE',
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                color: AppColors.alert,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ...candidates.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LCorpButton(
                  label: '??? / ${a.grade}',
                  enableScanline: false,
                  onPressed: () => Navigator.of(context).pop(a),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbnormalityCard extends StatelessWidget {
  const _AbnormalityCard({required this.abnormality});
  final Abnormality abnormality;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = abnormality.isUnlocked;
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: InkWell(
        onTap: unlocked
            ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AbnormalityDetailPage(
                      abnormalityId: abnormality.id,
                    ),
                  ),
                )
            : null,
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody(unlocked)),
            if (!unlocked)
              const Positioned.fill(
                child: CautionOverlay(label: 'CLASSIFIED'),
              ),
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppColors.background,
                child: Text(
                  unlocked ? abnormality.grade : '???',
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    color: AppColors.alert,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool unlocked) {
    if (!unlocked) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 立绘占位（v1.0 暂用图标）
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            abnormality.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            abnormality.id,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.hint,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
