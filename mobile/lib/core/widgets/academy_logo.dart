import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AcademyLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const AcademyLogo({
    super.key,
    this.size = 40.0,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = textColor ?? (isDark ? Colors.white : AppColors.textPrimaryLight);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLime.withOpacity(0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _HexagonPainter(),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chust One',
                style: TextStyle(
                  color: txtColor,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Academy',
                style: TextStyle(
                  color: AppColors.primaryLime,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = AppColors.primaryLime
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = AppColors.navy900
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60 - 30) * math.pi / 180;
      double x = center.dx + radius * 0.95 * math.cos(angle);
      double y = center.dy + radius * 0.95 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    final innerPath = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60 - 30) * math.pi / 180;
      double x = center.dx + radius * 0.5 * math.cos(angle);
      double y = center.dy + radius * 0.5 * math.sin(angle);
      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
