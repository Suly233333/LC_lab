import 'package:flutter/material.dart';

import '../core/theme.dart';

/// L-Corp 风格等宽终端文本。
///
/// 使用 [AppTheme.monoFontFamily] 等宽字体族，配合可调字距、颜色与字号，
/// 用于终端化展示日志/标签/数据等。
class TerminalText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final double letterSpacing;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TerminalText(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color = AppColors.onBackground,
    this.letterSpacing = 1.0,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// 标题级（强调主色）。
  factory TerminalText.title(
    String text, {
    Key? key,
    double fontSize = 18,
    Color color = AppColors.primary,
  }) {
    return TerminalText(
      text,
      key: key,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color,
      letterSpacing: 1.5,
    );
  }

  /// 提示/灰文字。
  factory TerminalText.hint(
    String text, {
    Key? key,
    double fontSize = 12,
  }) {
    return TerminalText(
      text,
      key: key,
      fontSize: fontSize,
      color: AppColors.hint,
      letterSpacing: 1.0,
    );
  }

  /// 警示/活跃色。
  factory TerminalText.alert(
    String text, {
    Key? key,
    double fontSize = 14,
  }) {
    return TerminalText(
      text,
      key: key,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: AppColors.alert,
      letterSpacing: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: AppTheme.monoFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

/// 带扫描线动效的 L-Corp 风格按钮。
///
/// 在按下/悬浮时，按钮表面会有一条警戒黄横向扫描线持续上下扫过，
/// 营造终端 / 工业控制台的交互观感。
class LCorpButton extends StatefulWidget {
  /// 按钮显示文字。
  final String label;

  /// 点击回调；为 null 时按钮被禁用。
  final VoidCallback? onPressed;

  /// 按钮宽度，null 表示按文字自适应。
  final double? width;

  /// 按钮高度。
  final double height;

  /// 主色（边框 / 文字 / 扫描线）。
  final Color color;

  /// 表面填充色（深色面板感）。
  final Color surfaceColor;

  /// 是否启用扫描线动效（默认 true）。
  final bool enableScanline;

  /// 扫描线一次完整往返耗时。
  final Duration scanDuration;

  const LCorpButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 44.0,
    this.color = AppColors.primary,
    this.surfaceColor = AppColors.surface,
    this.enableScanline = true,
    this.scanDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<LCorpButton> createState() => _LCorpButtonState();
}

class _LCorpButtonState extends State<LCorpButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.scanDuration,
    );
    if (widget.enableScanline && widget.onPressed != null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LCorpButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool shouldAnimate =
        widget.enableScanline && widget.onPressed != null;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
    if (oldWidget.scanDuration != widget.scanDuration) {
      _controller.duration = widget.scanDuration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color activeColor =
        enabled ? widget.color : widget.color.withValues(alpha: 0.4);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: widget.surfaceColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: activeColor, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: InkWell(
          onTap: widget.onPressed,
          splashColor: widget.color.withValues(alpha: 0.18),
          highlightColor: widget.color.withValues(alpha: 0.08),
          child: ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.enableScanline && enabled)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ScanlinePainter(
                            progress: _controller.value,
                            color: widget.color,
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TerminalText(
                    widget.label,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  /// 0.0 ~ 1.0，控制扫描线纵向位置（往返）。
  final double progress;
  final Color color;

  _ScanlinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 三角波：0->1->0，让扫描线上下往返。
    final double t = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
    final double y = t * size.height;

    // 主扫描线
    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // 余晖（上下渐变带）
    final Rect glowRect = Rect.fromLTWH(0, y - 6, size.width, 12);
    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.20),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(glowRect);
    canvas.drawRect(glowRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
