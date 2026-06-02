import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 突破事件提示卡片。
///
/// 仅用于"出逃（escape）"等需要主管介入的事件。
/// 风格克制：无闪烁、无抖动；居中卡片，警报红描边 + 醒目标题，
/// 配合 [onAck] 关闭。其他不需要介入的突破（none / penaltyBox）
/// 应改用 SnackBar 短提示，不要弹此组件。
///
/// 用法：
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => BreachAlertOverlay(
///     title: 'CONTAINMENT BREACH',
///     description: '“老妇人” 已脱离收容。',
///     onAck: () => Navigator.of(context).pop(),
///   ),
/// );
/// ```
class BreachAlertOverlay extends StatelessWidget {
  const BreachAlertOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.onAck,
    this.acknowledgeLabel = 'ACKNOWLEDGE',
  });

  final String title;
  final String description;
  final VoidCallback onAck;
  final String acknowledgeLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.alert, width: 1.5),
        borderRadius: AppTheme.borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.alert,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.alert,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                color: AppColors.onBackground,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadius,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                ),
                onPressed: onAck,
                child: Text(
                  acknowledgeLabel,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
