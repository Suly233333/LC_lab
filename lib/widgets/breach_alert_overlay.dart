import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 突破警报全屏遮罩。
///
/// 表现：
/// - 全屏背景在黑 / 黄之间快速交替闪烁；
/// - 中央 "ERROR" 像素化文字带随机抖动；
/// - 下方显示突破描述与确认按钮（[onAck]）。
///
/// 用法：
/// ```dart
/// showDialog(
///   context: context,
///   barrierColor: Colors.transparent,
///   builder: (_) => BreachAlertOverlay(
///     title: 'CONTAINMENT BREACH',
///     description: '“一罪与百善” 已重置。',
///     onAck: () => Navigator.of(context).pop(),
///   ),
/// );
/// ```
class BreachAlertOverlay extends StatefulWidget {
  const BreachAlertOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.onAck,
    this.acknowledgeLabel = 'ACKNOWLEDGE',
    this.flashDuration = const Duration(milliseconds: 220),
    this.shakeDuration = const Duration(milliseconds: 90),
  });

  final String title;
  final String description;
  final VoidCallback onAck;
  final String acknowledgeLabel;
  final Duration flashDuration;
  final Duration shakeDuration;

  @override
  State<BreachAlertOverlay> createState() => _BreachAlertOverlayState();
}

class _BreachAlertOverlayState extends State<BreachAlertOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _flash;
  late final AnimationController _shake;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(vsync: this, duration: widget.flashDuration)
      ..repeat(reverse: true);
    _shake = AnimationController(vsync: this, duration: widget.shakeDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _flash.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flash,
      builder: (context, child) {
        final bool yellowPhase = _flash.value > 0.5;
        final Color bg =
            yellowPhase ? AppColors.cautionStripe : AppColors.background;
        final Color fg =
            yellowPhase ? AppColors.background : AppColors.alert;
        return Material(
          color: bg,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (_, _) {
                        final double dx = (_rng.nextDouble() - 0.5) * 6;
                        final double dy = (_rng.nextDouble() - 0.5) * 6;
                        return Transform.translate(
                          offset: Offset(dx, dy),
                          child: Text(
                            'ERROR',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFontFamily,
                              color: fg,
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8.0,
                              height: 1.0,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      color: fg,
                      child: Text(
                        widget.title.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTheme.monoFontFamily,
                          color: bg,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFontFamily,
                        color: fg,
                        fontSize: 13,
                        height: 1.5,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: fg, width: 2),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: fg,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                        ),
                        onPressed: widget.onAck,
                        child: Text(
                          widget.acknowledgeLabel,
                          style: TextStyle(
                            fontFamily: AppTheme.monoFontFamily,
                            color: fg,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
