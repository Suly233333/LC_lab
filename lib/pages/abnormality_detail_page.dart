import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../state/app_providers.dart';
import '../widgets/lcorp_grid_background.dart';

/// 异想体详情页（占位实现）。
///
/// 6.3 工作交互界面将在此页中接入四种工作按钮、能量条、计数器组件等。
class AbnormalityDetailPage extends ConsumerWidget {
  const AbnormalityDetailPage({super.key, required this.abnormalityId});

  final String abnormalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Abnormality>> async =
        ref.watch(abnormalitiesProvider);

    final Abnormality? target = async.maybeWhen(
      data: (list) => list.firstWhere(
        (a) => a.id == abnormalityId,
        orElse: () => list.first,
      ),
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(target?.name ?? 'CONTAINMENT'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          if (target == null)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${target.id}  /  ${target.grade}',
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.alert,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    target.description,
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.onBackground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 1),
                      color: AppColors.surface,
                    ),
                    child: Text(
                      target.manageNote,
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFontFamily,
                        color: AppColors.hint,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '// WORK CONSOLE — TBD',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
