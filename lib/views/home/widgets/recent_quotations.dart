import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/quotation_model.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../widgets/common/glass_card.dart';
import '../../quotation_detail/quotation_detail_screen.dart';

class RecentQuotations extends StatelessWidget {
  final VoidCallback? onViewAll;

  const RecentQuotations({super.key, this.onViewAll});

  Future<void> _openDetail(BuildContext context, QuotationModel q) async {
    if (q.id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuotationDetailScreen(quotationId: q.id!),
      ),
    );
    if (context.mounted) {
      context.read<HomeViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotations = context.watch<HomeViewModel>().recentQuotations;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Quotations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 4),
          if (quotations.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No quotations yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            for (var i = 0; i < quotations.length; i++) ...[
              _item(context, quotations[i]),
              if (i < quotations.length - 1)
                Divider(height: 1, color: AppColors.border),
            ],
        ],
      ),
    );
  }

  Widget _item(BuildContext context, QuotationModel q) {
    return InkWell(
      onTap: () => _openDetail(context, q),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.quotationNo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${q.customerName}  •  ${AppFormatters.date(q.quotationDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppFormatters.currency(q.totalAmount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
