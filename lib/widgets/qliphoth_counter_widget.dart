import 'package:flutter/material.dart';

import '../core/theme.dart';

/// LED 风格逆卡巴拉计数器组件（Qliphoth Counter）。
///
/// 显示 [current]/[max] 个亮起的方格段，模拟分段式 LED 警示灯。
/// 当 [current] = 0 时整体闪烁红色，提醒突破即将发生。
class QliphothCounterWidget extends StatefulWidget {
  const QliphothCounterWidget({
    super.key,
    required this.current,
    required this.max,
    this.label = 'QLIPHOTH',
    this.compact = false,
  });

  final int current;
  final int max;
  final String label;

  /// 紧凑模式：仅显示方格 + 数字，不显示文字标签。
  final bool compact;

  @override
  State<QliphothCounterWidget> createState() => _QliphothCounterWidgetState();
}

class _QliphothCounterWidgetState extends State<QliphothCounterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int safeMax = widget.max <= 0 ? 1 : widget.max;
    final int safeCurrent = widget.current.clamp(0, safeMax);
    final bool dangerous = safeCurrent == 0;

    final Widget cells = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(safeMax, (i) {
        final bool lit = i < safeCurrent;
        return AnimatedBuilder(
          animation: _blink,
          builder: (_, _) {
            final Color base = dangerous
                ? Color.lerp(
                        AppColors.danger,
                        AppColors.alert,
                        _blink.value,
                      ) ??
                    AppColors.danger
                : AppColors.alert;
            return Container(
              width: 12,
              height: 16,
              margin: EdgeInsets.only(right: i == safeMax - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: lit ? base : base.withValues(alpha: 0.10),
                border: Border.all(color: base, width: 0.6),
              ),
            );
          },
        );
      }),
    );

    if (widget.compact) {
      return cells;
    }

    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.alert,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        cells,
        const SizedBox(width: 8),
        Text(
          '$safeCurrent/$safeMax',
          style: const TextStyle(
            fontFamily: AppTheme.monoFontFamily,
            color: AppColors.alert,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
