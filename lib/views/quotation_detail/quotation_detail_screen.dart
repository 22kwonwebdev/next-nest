import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/quotation_item_model.dart';
import '../../models/quotation_model.dart';
import '../../viewmodels/quotation_detail_viewmodel.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/section_header.dart';
import '../quotation_form/quotation_form_screen.dart';
import '../quotation_preview/quotation_preview_screen.dart';

class QuotationDetailScreen extends StatefulWidget {
  final int quotationId;

  const QuotationDetailScreen({super.key, required this.quotationId});

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  late final QuotationDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = QuotationDetailViewModel(quotationId: widget.quotationId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.load());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuotationFormScreen(quotationId: widget.quotationId),
      ),
    );
    if (updated == true && mounted) {
      _viewModel.load();
    }
  }

  void _openPreview(QuotationModel quotation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuotationPreviewScreen(quotation: quotation),
      ),
    );
  }

  Future<void> _confirmDelete(QuotationModel quotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text(
          'Delete quotation ${quotation.quotationNo} for '
          '${quotation.customerName}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deleted = await _viewModel.delete();
      if (deleted && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QuotationDetailViewModel>.value(
      value: _viewModel,
      child: Consumer<QuotationDetailViewModel>(
        builder: (context, viewModel, _) {
          final quotation = viewModel.quotation;

          return Scaffold(
            appBar: AppBar(
              title: Text(quotation?.quotationNo ?? 'Quotation Details'),
              actions: [
                if (quotation != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(quotation),
                  ),
                ],
              ],
            ),
            body: _buildBody(context, viewModel),
            bottomNavigationBar: quotation == null
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Edit',
                              icon: Icons.edit_outlined,
                              variant: AppButtonVariant.secondary,
                              onPressed: _edit,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: AppButton(
                              label: 'Preview & Export',
                              icon: Icons.visibility_outlined,
                              onPressed: () => _openPreview(quotation),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuotationDetailViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingWidget();
    }

    final quotation = viewModel.quotation;
    if (quotation == null) {
      return EmptyState(
        icon: Icons.description_outlined,
        title: viewModel.errorMessage ?? 'Quotation not found',
      );
    }

    return AppBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SectionHeader(title: 'Customer Information'),
          const SizedBox(height: 8),
          _buildCustomerCard(context, quotation),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Quotation Information'),
          const SizedBox(height: 8),
          _buildInfoCard(context, quotation),
          const SizedBox(height: 20),
          SectionHeader(title: 'Items (${quotation.items.length})'),
          const SizedBox(height: 8),
          _buildItemsCard(context, quotation.items),
          const SizedBox(height: 20),
          _buildTotalCard(context, quotation),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, QuotationModel q) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.customerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (q.customerPhone != null && q.customerPhone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _contactRow(Icons.phone_outlined, q.customerPhone!),
          ],
          if (q.customerAddress != null && q.customerAddress!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _contactRow(Icons.location_on_outlined, q.customerAddress!),
          ],
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, QuotationModel q) {
    return GlassCard(
      child: Column(
        children: [
          _infoRow('Quotation No', q.quotationNo),
          _infoRow('Date', AppFormatters.date(q.quotationDate)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, List<QuotationItemModel> items) {
    if (items.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'No items',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _itemsHeader(),
          for (var i = 0; i < items.length; i++) ...[
            if (i == 0 || items[i].categoryName != items[i - 1].categoryName)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    items[i].categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ),
            _itemRow(items[i], i),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _itemsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'ITEM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'AMOUNT',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(QuotationItemModel item, int index) {
    final subtitle =
        '${_formatQty(item.quantity)}'
        '${item.unit != null ? ' ${item.unit}' : ''}'
        '  ×  ${AppFormatters.currency(item.unitPrice)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.remark != null && item.remark!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Remark: ${item.remark}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              AppFormatters.currency(item.amount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, QuotationModel q) {
    final base = q.items.fold<double>(0, (sum, item) => sum + item.amount);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      tint: AppColors.primary.withValues(alpha: 0.10),
      child: Column(
        children: [
          _totalLine('Items amount', base),
          _totalLine('Supervision charge (5%)', base * 0.05),
          _totalLine('Safety charge (3%)', base * 0.03),
          const Divider(),
          _totalLine('Grand total', q.totalAmount, bold: true),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              q.sayAmount == null
                  ? 'Say: — MMK'
                  : 'Say: ${AppFormatters.currency(q.sayAmount!)} MMK',
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalLine(String label, double amount, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      Text(AppFormatters.currency(amount), style: TextStyle(fontWeight: FontWeight.w700, color: bold ? AppColors.primary : AppColors.textPrimary)),
    ]),
  );

  String _formatQty(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
