import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import 'abnormality_image.dart';

/// 提取仪式动画组件（Extraction Ceremony）。
///
/// 表现：黄色光栅扫描线在档案框内上下滚动，扫描完成后揭晓档案立绘与名称。
/// 用作模态对话内容（配合 showDialog 使用）。
class ExtractionCeremonyWidget extends StatefulWidget {
  const ExtractionCeremonyWidget({
    super.key,
    required this.abnormality,
    this.scanDuration = const Duration(milliseconds: 2400),
    this.onRevealed,
  });

  /// 被揭晓的异想体。
  final Abnormality abnormality;

  /// 扫描动画时长。
  final Duration scanDuration;

  /// 揭晓完成回调。
  final VoidCallback? onRevealed;

  @override
  State<ExtractionCeremonyWidget> createState() =>
      _ExtractionCeremonyWidgetState();
}

class _ExtractionCeremonyWidgetState extends State<ExtractionCeremonyWidget>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _revealController;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: widget.scanDuration,
    );
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scanController.forward();
    _scanController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_revealed) {
        setState(() => _revealed = true);
        _revealController.forward();
        widget.onRevealed?.call();
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: AppTheme.borderRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _revealed ? '// EXTRACTION COMPLETE' : '// EXTRACTING...',
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.alert,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.primary, width: 1),
                borderRadius: AppTheme.borderRadius,
              ),
              child: ClipRRect(
                borderRadius: AppTheme.borderRadius,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 揭晓的立绘（淡入）
                    FadeTransition(
                      opacity: _revealController,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: AbnormalityImage(
                          assetPath:
                              widget.abnormality.portraitAssetPath,
                          iconSize: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // 扫描线
                    if (!_revealed)
                      AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: _RasterScanPainter(
                              progress: _scanController.value,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _revealed ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Column(
              children: [
                Text(
                  _revealed ? widget.abnormality.name : '???',
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.abnormality.id}  /  ${widget.abnormality.grade}',
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    color: AppColors.hint,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_revealed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('SECURE'),
              ),
            ),
        ],
      ),
    );
  }
}

class _RasterScanPainter extends CustomPainter {
  _RasterScanPainter({required this.progress});

  /// 0.0 ~ 1.0，扫描线纵向往返。
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // 半透明黄色遮罩 + 极细横向光栅线
    final Paint mask = Paint()..color = AppColors.cautionStripe.withValues(alpha: 0.10);
    canvas.drawRect(Offset.zero & size, mask);

    final Paint raster = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), raster);
    }

    // 三角波往返
    final double t = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
    final double y = t * size.height;

    final Paint line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);

    final Rect glow = Rect.fromLTWH(0, y - 10, size.width, 20);
    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primary.withValues(alpha: 0.35),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(glow);
    canvas.drawRect(glow, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RasterScanPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
