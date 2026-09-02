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
                color: AppColors.primaryLime.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
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
