import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../state/app_providers.dart';
import '../widgets/abnormality_image.dart';
import '../widgets/caution_overlay.dart';
import '../widgets/extraction_ceremony_widget.dart';
import '../widgets/lcorp_grid_background.dart';
import 'abnormality_detail_page.dart';

/// 异想体档案库页（Abnormality Gallery）。
///
/// - 已解锁：展示名称、等级、缩略描述。点击进入详情/对话页。
/// - 未解锁：整张卡片被「警报红 / 近黑斜纹 CLASSIFIED」遮盖板覆盖。
/// - 监听 [pendingUnlocksProvider]，自动弹出仪式动画揭晓新解锁项。
/// - 不展示任何共鸣度数值 / 进度条。
class AbnormalityGalleryPage extends ConsumerStatefulWidget {
  const AbnormalityGalleryPage({super.key});

  @override
  ConsumerState<AbnormalityGalleryPage> createState() =>
      _AbnormalityGalleryPageState();
}

class _AbnormalityGalleryPageState
    extends ConsumerState<AbnormalityGalleryPage> {
  bool _showingCeremony = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunCeremony();
    });
  }

  Future<void> _maybeRunCeremony() async {
    if (_showingCeremony) return;
    final List<Abnormality> queue = ref.read(pendingUnlocksProvider);
    if (queue.isEmpty) return;
    _showingCeremony = true;
    try {
      for (final Abnormality a in queue) {
        if (!mounted) break;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(24),
            child: ExtractionCeremonyWidget(abnormality: a),
          ),
        );
      }
      ref.read(pendingUnlocksProvider.notifier).clear();
    } finally {
      _showingCeremony = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Abnormality>>(pendingUnlocksProvider, (prev, next) {
      if (next.isNotEmpty) _maybeRunCeremony();
    });

    final AsyncValue<List<Abnormality>> async =
        ref.watch(abnormalitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ABNORMALITY GALLERY'),
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
              data: (list) => _buildGrid(context, list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Abnormality> list) {
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
}

class _AbnormalityCard extends StatelessWidget {
  const _AbnormalityCard({required this.abnormality});
  final Abnormality abnormality;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = abnormality.isUnlocked;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.primary, width: 1),
        borderRadius: AppTheme.borderRadius,
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
              left: 0,
              top: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: unlocked ? AppColors.primary : AppColors.alert,
                child: Text(
                  unlocked ? abnormality.grade : '???',
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    color: AppColors.background,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
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
          // 立绘占位（缺图自动回退到图标）
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.primary, width: 1),
                borderRadius: AppTheme.borderRadius,
              ),
              child: ClipRRect(
                borderRadius: AppTheme.borderRadius,
                child: AbnormalityImage(
                  assetPath: abnormality.iconAssetPath,
                ),
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
