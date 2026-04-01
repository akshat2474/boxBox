import 'package:flutter/material.dart';
import '../core/theme/liquid_glass_theme.dart';

/// Replaces the old LiquidGlassContainer with a clean F1 TV-style card.
/// Still named LiquidGlassContainer so no imports need updating.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Color? color;
  final Color? borderColor;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.width,
    this.height,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.border,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}
