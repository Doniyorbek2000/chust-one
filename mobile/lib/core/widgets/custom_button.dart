import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline }

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? suffixIcon;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.suffixIcon,
    this.width,
    this.height = 54.0,
    this.borderRadius = 16.0,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.primaryLime;
      case ButtonVariant.secondary:
        return AppColors.navy800;
      case ButtonVariant.outline:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.navy900;
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.outline:
        return AppColors.primaryLime;
    }
  }

  Border? get _border {
    if (widget.variant == ButtonVariant.outline) {
      return Border.all(color: AppColors.primaryLime, width: 1.5);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onPressed != null ? _controller.forward() : null,
      onTapUp: (_) => widget.onPressed != null ? _controller.reverse() : null,
      onTapCancel: () => widget.onPressed != null ? _controller.reverse() : null,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.onPressed == null ? _backgroundColor.withValues(alpha: 0.5) : _backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: _border,
              boxShadow: widget.variant == ButtonVariant.primary && widget.onPressed != null
                  ? [
                      BoxShadow(
                        color: AppColors.primaryLime.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (widget.suffixIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(widget.suffixIcon, color: _textColor, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
