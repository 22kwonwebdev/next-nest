import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/quotation_model.dart';
import '../../../widgets/common/quotation_totals_card.dart';

/// Renders the quotation exactly as it should appear in exports.
/// Wrapped in a RepaintBoundary by the preview screen for image capture.
class QuotationDocument extends StatelessWidget {
  final QuotationModel quotation;

  const QuotationDocument({super.key, required this.quotation});

  static const double documentWidth = 794; // design width, scaled to fit screen
  static const double documentHeight = 1123; // A4 portrait at 96 dpi

  static const Color _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: documentWidth,
      height: documentHeight,
      child: ColoredBox(
        color: Colors.white,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: Container(
            width: documentWidth,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildItemsTable(context),
                const SizedBox(height: 12),
                _buildTotals(context),
                _buildQrFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              CompanyInfo.logoAsset,
              height: 72,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.business, size: 48, color: _primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CompanyInfo.name,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CompanyInfo.info,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // _contactLine('Email: ${CompanyInfo.email}'),
        _contactLine('Phone: ${CompanyInfo.phone}'),
        _contactLine('Address: ${CompanyInfo.address}'),
        const SizedBox(height: 8),
        _buildBillToBox(context),
        const SizedBox(height: 8),
        _buildMetaRow(context),
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Quotation No: ${quotation.quotationNo}',
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            'Date: ${AppFormatters.date(quotation.quotationDate)}',
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _contactLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildBillToBox(BuildContext context) {
    final theme = Theme.of(context);
    final lines = <String>[
      quotation.customerName,
      if (quotation.customerPhone != null &&
          quotation.customerPhone!.isNotEmpty)
        'Phone: ${quotation.customerPhone}',
      if (quotation.customerAddress != null &&
          quotation.customerAddress!.isNotEmpty)
        quotation.customerAddress!,
    ];
    return _infoBox(theme, 'BILL TO', lines, emphasizeFirst: true);
  }

  Widget _infoBox(
    ThemeData theme,
    String title,
    List<String> lines, {
    bool emphasizeFirst = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                lines[i],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: emphasizeFirst && i == 0 ? FontWeight.w700 : null,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context) {
    final theme = Theme.of(context);
    const columnWidths = <int, TableColumnWidth>{
      0: FlexColumnWidth(1),
      1: FlexColumnWidth(4),
      2: FlexColumnWidth(1),
      3: FlexColumnWidth(1),
      4: FlexColumnWidth(2),
      5: FlexColumnWidth(2),
      6: FlexColumnWidth(2),
    };

    Widget headerCell(String text, {TextAlign align = TextAlign.left}) {
      return TableCell(
        child: Container(
          color: AppColors.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textPrimary,
            ),
            textAlign: align,
          ),
        ),
      );
    }

    Widget cell(String text, {TextAlign align = TextAlign.left, bool bold = false}) {
      return TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : null,
            ),
            textAlign: align,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        children: [
          headerCell('SN', align: TextAlign.center),
          headerCell('ITEM NAME'),
          headerCell('QTY', align: TextAlign.center),
          headerCell('UNIT', align: TextAlign.center),
          headerCell('RATE', align: TextAlign.right),
          headerCell('AMOUNT', align: TextAlign.right),
          headerCell('REMARK'),
        ],
      ),
    ];

    if (quotation.items.isEmpty) {
      rows.add(
        TableRow(
          children: [
            for (var i = 0; i < 7; i++)
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    i == 1 ? 'No items' : '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    String? lastCategory;
    var categoryNumber = 0;
    for (var i = 0; i < quotation.items.length; i++) {
      final item = quotation.items[i];
      final category = quotation.categories.where((value) =>
        item.categoryId != null ? value.id == item.categoryId : value.categoryName == item.categoryName,
      ).firstOrNull;
      final categoryKey = item.categoryId?.toString() ?? item.categoryName;
      if (categoryKey != lastCategory) {
        lastCategory = categoryKey;
        categoryNumber++;
        rows.add(
          TableRow(children: [
            cell('$categoryNumber', align: TextAlign.center),
            cell(item.categoryName, bold: true),
            cell(category == null ? '' : _formatQty(category.quantity), align: TextAlign.center),
            cell(category?.unit ?? '', align: TextAlign.center),
            cell('', align: TextAlign.right),
            cell('', align: TextAlign.right),
            cell(category?.remark ?? ''),
          ]),
        );
      }
      rows.add(
        TableRow(
          children: [
            cell('', align: TextAlign.center),
            cell(item.itemName),
            cell(_formatQty(item.quantity), align: TextAlign.center),
            cell(item.unit ?? '', align: TextAlign.center),
            cell(
              AppFormatters.currency(item.unitPrice),
              align: TextAlign.right,
            ),
            cell(AppFormatters.currency(item.amount), align: TextAlign.right),
            cell(item.remark ?? ''),
          ],
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: AppColors.border),
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }


  Widget _buildTotals(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: QuotationTotalsCard(
          itemsAmount: baseAmount,
          supervisionCharge: baseAmount * 0.05,
          safetyCharge: baseAmount * 0.03,
          grandTotal: quotation.totalAmount,
          sayAmount: quotation.sayAmount,
        ),
      ),
    );
  }

  double get baseAmount => quotation.categories.isNotEmpty
      ? quotation.categories.fold(0, (sum, category) => sum + category.amount)
      : quotation.items.fold(0, (sum, item) => sum + item.amount);

  Widget _buildQrFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Column(
          children: [
            Text(
              'Scan to chat with us on Viber',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(
                data: CompanyInfo.viberUrl,
                size: 110,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
