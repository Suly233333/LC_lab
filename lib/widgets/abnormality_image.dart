import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 异想体图片（图标 / 立绘）通用加载器。
///
/// 优先尝试加载 [assetPath]；asset 缺失时回退到 [fallbackIcon]。
/// 由于 `Image.asset` 的资源缺失错误是同步抛出的，使用 [errorBuilder]
/// 在捕获异常时呈现回退占位。
class AbnormalityImage extends StatelessWidget {
  const AbnormalityImage({
    super.key,
    required this.assetPath,
    this.fallbackIcon = Icons.visibility_outlined,
    this.iconSize = 48,
    this.fit = BoxFit.cover,
    this.color,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double iconSize;
  final BoxFit fit;

  /// 仅用于 fallback 图标的颜色；图片本身按原色绘制。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = color ?? AppColors.primary;
    return Image.asset(
      assetPath,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Center(
        child: Icon(
          fallbackIcon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}
