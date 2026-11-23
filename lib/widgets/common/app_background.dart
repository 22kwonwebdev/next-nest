import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Subtle neutral backdrop that keeps screens close to the shared theme.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: child,
    );
  }
}
