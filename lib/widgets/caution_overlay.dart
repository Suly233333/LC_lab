import 'package:flutter/material.dart';

import '../core/theme.dart';

/// L-Corp 黄黑斜纹「机密」遮盖板（CAUTION）。
///
/// 用于覆盖未解锁异想体的档案区域。带有可选的中央文字标签。
class CautionOverlay extends StatelessWidget {
  const CautionOverlay({
    super.key,
    this.label = 'CLASSIFIED',
    this.stripeWidth = 16,
    this.opacity = 0.95,
  });

  /// 中央显示文字。空字符串则不显示文字。
  final String label;

  /// 单条斜纹宽度。
  final double stripeWidth;

  /// 整体不透明度，0~1。
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: _DiagonalStripesPainter(stripeWidth: stripeWidth),
          child: Center(
            child: label.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    color: AppColors.background,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFontFamily,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  _DiagonalStripesPainter({required this.stripeWidth});
  final double stripeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // 底色：暗炭灰
    final Paint base = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, base);

    final Paint yellow = Paint()..color = AppColors.cautionStripe;

    // 沿 -45° 方向铺满黄色斜条带
    final double step = stripeWidth * 2;
    final double diag = size.width + size.height;
    for (double offset = -size.height;
        offset < diag;
        offset += step) {
      final Path p = Path()
        ..moveTo(offset, 0)
        ..lineTo(offset + stripeWidth, 0)
        ..lineTo(offset + stripeWidth + size.height, size.height)
        ..lineTo(offset + size.height, size.height)
        ..close();
      canvas.drawPath(p, yellow);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter oldDelegate) {
    return oldDelegate.stripeWidth != stripeWidth;
  }
}
