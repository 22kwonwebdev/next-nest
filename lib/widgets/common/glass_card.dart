import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Reusable rounded surface styled from the shared app palette.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? tint;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 20,
    this.blur = 12,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return glass;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: glass,
      ),
    );
  }
}

/// Rounded themed card used for content sections across screens.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      borderRadius: 16,
      tint: tint,
      onTap: onTap,
      child: child,
    );
  }
}
