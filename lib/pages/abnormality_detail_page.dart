import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../state/app_providers.dart';
import '../widgets/abnormality_image.dart';
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';
import 'attachment_chat_page.dart';

/// 异想体详情页（简化版 v1.1）。
///
/// 仅负责展示档案信息 + 进入对话界面，不再承担工作 / 突破 / 镇压等职能。
class AbnormalityDetailPage extends ConsumerWidget {
  const AbnormalityDetailPage({super.key, required this.abnormalityId});

  final String abnormalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Abnormality>> async =
        ref.watch(abnormalitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ABNORMALITY DOSSIER')),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          Positioned.fill(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('// DOSSIER ERROR: $e')),
              data: (list) {
                Abnormality? a;
                for (final Abnormality x in list) {
                  if (x.id == abnormalityId) {
                    a = x;
                    break;
                  }
                }
                if (a == null) {
                  return const Center(
                    child: Text('// NO SUCH ENTRY',
                        style: TextStyle(
                          fontFamily: AppTheme.monoFontFamily,
                          color: AppColors.hint,
                          letterSpacing: 1.5,
                        )),
                  );
                }
                return _buildBody(context, a);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, Abnormality a) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GradeBadge(grade: a.grade),
          const SizedBox(height: 12),
          // 立绘
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.primary, width: 1),
                borderRadius: AppTheme.borderRadius,
              ),
              child: ClipRRect(
                borderRadius: AppTheme.borderRadius,
                child: AbnormalityImage(assetPath: a.portraitAssetPath),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            a.name,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '// ${a.id}',
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.hint,
              fontSize: 12,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _Section(title: 'DESCRIPTION', body: a.description),
          const SizedBox(height: 16),
          _Section(title: 'MANAGEMENT NOTE', body: a.manageNote),
          const SizedBox(height: 28),
          LCorpButton(
            label: 'BEGIN COMMUNICATION',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AttachmentChatPage(abnormalityId: a.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});
  final String grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        grade,
        style: const TextStyle(
          fontFamily: AppTheme.monoFontFamily,
          color: AppColors.background,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary, width: 1),
        borderRadius: AppTheme.borderRadius,
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
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.onBackground,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
