import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Subtle neutral backdrop that keeps screens close to the shared theme.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppColors.darkBackground, AppColors.darkBackdropEnd]
              : [AppColors.lightBackground, AppColors.lightBackdropEnd],
        ),
      ),
      child: child,
    );
  }
}
