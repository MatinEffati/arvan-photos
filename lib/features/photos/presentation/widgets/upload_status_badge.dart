import 'dart:math';
import 'package:flutter/material.dart';
import 'package:arvan_photos/core/theme/app_colors.dart';

class UploadStatusBadge extends StatelessWidget {
  const UploadStatusBadge({
    required this.isBackedUp,
    this.progress,
    super.key,
  });

  final bool isBackedUp;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    if (!isBackedUp && (progress == null || progress! <= 0)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: isBackedUp
            ? CustomPaint(
          size: const Size(18, 18),
          painter: CloudCheckPainter(color: AppColors.white),
        )
            : Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(20, 20),
              painter: DashedArcPainter(
                progress: progress ?? 0.0,
                color: AppColors.white,
                unfilledColor: AppColors.white.withValues(alpha: 0.6),
              ),
            ),
            const Icon(
              Icons.file_upload_outlined,
              color: AppColors.white,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

/// دایره‌ی پیشرفت: قسمت پرشده خط‌توپر سفید، قسمت باقیمانده نقطه‌چین سفید
class DashedArcPainter extends CustomPainter {
  DashedArcPainter({
    required this.progress,
    required this.color,
    required this.unfilledColor,
  });

  final double progress;
  final Color color;
  final Color unfilledColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    final dashPaint = Paint()
      ..color = unfilledColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final remainingSweepAngle = 2 * pi * (1 - progress);
    final dashOffset = sweepAngle;

    _drawDashedArc(
      canvas,
      rect,
      startAngle + dashOffset,
      remainingSweepAngle,
      dashPaint,
      dashLength: 2,
      gapLength: 2,
    );
  }

  void _drawDashedArc(
      Canvas canvas,
      Rect rect,
      double startAngle,
      double sweepAngle,
      Paint paint, {
        double dashLength = 2,
        double gapLength = 2,
      }) {
    final radius = rect.width / 2;
    final circumference = 2 * pi * radius;
    final totalDashLength = dashLength + gapLength;

    final linearSweep = sweepAngle.abs() * radius;
    final numberOfDashes = (linearSweep / totalDashLength).floor();

    for (var i = 0; i < numberOfDashes; i++) {
      final dashStartLinear = i * totalDashLength;
      final dashStartAngle = startAngle + (dashStartLinear / radius);
      final dashSweepAngle = dashLength / radius;

      canvas.drawArc(rect, dashStartAngle, dashSweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.unfilledColor != unfilledColor;
  }
}

/// ابر خطی (outline) با تیک داخلش، دقیقاً استایل گوگل‌فوتوز بعد از اتمام آپلود
class CloudCheckPainter extends CustomPainter {
  CloudCheckPainter({required this.color, this.strokeWidth = 1.6});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // مسیر ابر (outline) - نسبت‌ها بر اساس یک باکس 18x18
    final w = size.width;
    final h = size.height;
    final cloudPath = Path()
      ..moveTo(w * 0.28, h * 0.72)
      ..cubicTo(w * 0.10, h * 0.72, w * 0.02, h * 0.58, w * 0.08, h * 0.44)
      ..cubicTo(w * 0.11, h * 0.36, w * 0.19, h * 0.31, w * 0.27, h * 0.31)
      ..cubicTo(w * 0.30, h * 0.16, w * 0.44, h * 0.06, w * 0.58, h * 0.10)
      ..cubicTo(w * 0.68, h * 0.13, w * 0.75, h * 0.22, w * 0.76, h * 0.32)
      ..cubicTo(w * 0.90, h * 0.34, w * 0.98, h * 0.48, w * 0.94, h * 0.60)
      ..cubicTo(w * 0.90, h * 0.70, w * 0.80, h * 0.72, w * 0.72, h * 0.72)
      ..lineTo(w * 0.28, h * 0.72);

    canvas.drawPath(cloudPath, paint);

    // تیک وسط ابر
    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(w * 0.32, h * 0.50)
      ..lineTo(w * 0.45, h * 0.62)
      ..lineTo(w * 0.70, h * 0.36);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CloudCheckPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}