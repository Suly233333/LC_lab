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

/// L-Corp 风格静态按钮。
///
/// 方角描边 + 等宽大写文字 + 点击 ripple，无任何持续动画，
/// 保持冷峻克制的工业控制台观感。
class LCorpButton extends StatelessWidget {
  /// 按钮显示文字。
  final String label;

  /// 点击回调；为 null 时按钮被禁用。
  final VoidCallback? onPressed;

  /// 按钮宽度，null 表示按文字自适应。
  final double? width;

  /// 按钮高度。
  final double height;

  /// 主色（边框 / 文字）。
  final Color color;

  /// 表面填充色（深色面板感）。
  final Color surfaceColor;

  /// 兼容旧调用：扫描线动画已移除，此参数保留但不再生效。
  final bool enableScanline;

  /// 兼容旧调用：扫描线动画已移除，此参数保留但不再生效。
  final Duration scanDuration;

  const LCorpButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 44.0,
    this.color = AppColors.primary,
    this.surfaceColor = AppColors.surface,
    this.enableScanline = false,
    this.scanDuration = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color fillColor =
        enabled ? color : color.withValues(alpha: 0.35);
    final Color textColor = AppColors.background;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: fillColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColors.background.withValues(alpha: 0.18),
          highlightColor: AppColors.background.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: TerminalText(
                label,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1.8,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
