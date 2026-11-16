import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../widgets/common/glass_card.dart';

class MonthlyOverview extends StatelessWidget {
  const MonthlyOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HomeViewModel>().monthlyChartData;
    final maxValue = data.fold<double>(
      0,
      (max, e) => e.total > max ? e.total : max,
    );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quotation value - last 6 months',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in data)
                  Expanded(child: _bar(entry.label, entry.total, maxValue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, double value, double maxValue) {
    final ratio = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.04, 1.0);
    final hasValue = value > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (hasValue)
            Text(
              _compact(value),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          else
            const SizedBox(height: 14),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            height: 90 * ratio,
            decoration: BoxDecoration(
              color: hasValue
                  ? AppColors.primary.withValues(alpha: 0.75)
                  : AppColors.border,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _compact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}
