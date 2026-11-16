import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../quotation_form/quotation_form_screen.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback? onViewQuotations;
  final VoidCallback? onSearchQuotations;
  final VoidCallback? onSettings;

  const QuickActions({
    super.key,
    this.onViewQuotations,
    this.onSearchQuotations,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _action(
          context,
          icon: Icons.add_circle_outline,
          label: 'Create',
          color: AppColors.primary,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
            );
            if (context.mounted) {
              context.read<HomeViewModel>().refresh();
            }
          },
        ),
        const SizedBox(width: 10),
        _action(
          context,
          icon: Icons.list_alt_outlined,
          label: 'Quotations',
          color: AppColors.info,
          onTap: onViewQuotations,
        ),
        const SizedBox(width: 10),
        _action(
          context,
          icon: Icons.search,
          label: 'Search',
          color: AppColors.success,
          onTap: onSearchQuotations,
        ),
        const SizedBox(width: 10),
        _action(
          context,
          icon: Icons.settings_outlined,
          label: 'Settings',
          color: AppColors.warning,
          onTap: onSettings,
        ),
      ],
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.38 : 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
