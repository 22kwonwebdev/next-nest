import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../viewmodels/quotation_form_viewmodel.dart';
import '../../../widgets/common/glass_card.dart';
import '../../../widgets/common/app_text_field.dart';

class QuotationItemCard extends StatelessWidget {
  final QuotationItemForm item;
  final int index;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final Widget? dragHandle;

  const QuotationItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ?dragHandle,
              if (canRemove)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.error,
                    size: 22,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Remove item',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          AppTextField(
            controller: item.nameController,
            onChanged: (_) => onChanged(),
            labelText: 'Item name *',
            hintText: 'e.g. Cement bag',
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: item.quantityController,
                  onChanged: (_) => onChanged(),
                  labelText: 'Qty',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: item.unitController,
                  onChanged: (_) => onChanged(),
                  labelText: 'Unit',
                  hintText: 'pcs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: item.priceController,
                  onChanged: (_) => onChanged(),
                  labelText: 'Rate',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  controller: item.remarkController,
                  labelText: 'Remark (optional)',
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  AppFormatters.currency(item.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
