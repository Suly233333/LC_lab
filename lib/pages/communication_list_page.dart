import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../state/app_providers.dart';
import '../widgets/abnormality_image.dart';
import '../widgets/lcorp_grid_background.dart';
import 'attachment_chat_page.dart';

class CommunicationListPage extends ConsumerWidget {
  const CommunicationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Abnormality>> async =
        ref.watch(abnormalitiesProvider);

    return Stack(
      children: [
        const Positioned.fill(child: LCorpGridBackground()),
        Positioned.fill(
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(child: Text('// COMMS ERROR: $e')),
            data: (list) {
              final List<Abnormality> unlocked =
                  list.where((a) => a.isUnlocked).toList(growable: false);
              if (unlocked.isEmpty) {
                return const _EmptyComms();
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: unlocked.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CommsTile(abnormality: unlocked[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyComms extends StatelessWidget {
  const _EmptyComms();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          '// NO OPEN COMMUNICATION CHANNELS',
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

class _CommsTile extends StatelessWidget {
  const _CommsTile({required this.abnormality});

  final Abnormality abnormality;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary, width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AttachmentChatPage(abnormalityId: abnormality.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.primary),
                ),
                child: AbnormalityImage(
                  assetPath: abnormality.iconAssetPath,
                  fallbackIcon: Icons.forum_outlined,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      abnormality.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFontFamily,
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${abnormality.id} / ${abnormality.grade}',
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFontFamily,
                        color: AppColors.hint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
