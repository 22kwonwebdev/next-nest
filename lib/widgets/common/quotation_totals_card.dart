import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class QuotationTotalsCard extends StatelessWidget {
  const QuotationTotalsCard({
    super.key,
    required this.itemsAmount,
    required this.supervisionCharge,
    required this.safetyCharge,
    required this.grandTotal,
    this.sayAmount,
    this.footer,
  });

  final double itemsAmount;
  final double supervisionCharge;
  final double safetyCharge;
  final double grandTotal;
  final double? sayAmount;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _line('Total amount', itemsAmount),
          const Divider(height: 1),
          _line('Supervision charge (5%)', supervisionCharge),
          _line('Safety charge (3%)', safetyCharge),
          const Divider(height: 1),
          Container(
            color: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  AppFormatters.currency(grandTotal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (sayAmount != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Say amount:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${AppFormatters.currency(sayAmount!)} MMK',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: footer!,
            ),
        ],
      ),
    );
  }

  Widget _line(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            AppFormatters.currency(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
