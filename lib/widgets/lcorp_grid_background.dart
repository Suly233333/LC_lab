import 'package:flutter/material.dart';

import '../core/theme.dart';

/// L-Corp 风格网格背景。
///
/// 在深色背景上叠加极细的暗黄网格线，营造工业/终端氛围。
/// 用法：将其作为页面 Scaffold body 的最底层 Stack child，或作为
/// 任意区域的装饰底层。
class LCorpGridBackground extends StatelessWidget {
  /// 网格单元尺寸（像素）。
  final double cellSize;

  /// 网格线宽度。
  final double lineWidth;

  /// 网格线颜色，默认半透明警戒黄。
  final Color lineColor;

  /// 背景色，默认深碳黑。
  final Color backgroundColor;

  /// 包裹的子组件（可选）。如未提供则该组件填充父级 constraints。
  final Widget? child;

  const LCorpGridBackground({
    super.key,
    this.cellSize = 24.0,
    this.lineWidth = 0.5,
    this.lineColor = AppColors.gridLine,
    this.backgroundColor = AppColors.background,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: CustomPaint(
        painter: _GridPainter(
          cellSize: cellSize,
          lineWidth: lineWidth,
          lineColor: lineColor,
        ),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double cellSize;
  final double lineWidth;
  final Color lineColor;

  _GridPainter({
    required this.cellSize,
    required this.lineWidth,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // 垂直线
    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // 水平线
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.cellSize != cellSize ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.lineColor != lineColor;
  }
}
