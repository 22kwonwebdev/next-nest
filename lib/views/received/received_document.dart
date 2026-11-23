import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/received_model.dart';

class ReceivedDocument extends StatelessWidget {
  const ReceivedDocument({super.key, required this.record});

  final ReceivedModel record;

  static const double documentWidth = 794;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SizedBox(
        width: documentWidth,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanyHeader(),
              const SizedBox(height: 18),
              const SizedBox(height: 14),
              _infoLine('Intention To', record.intentionTo),
              _infoLine('Project Title', record.projectTitle),
              _infoLine('Subject', record.subject),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Date    ${AppFormatters.date(record.receivedDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 6),
              _buildItemsTable(),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      CompanyInfo.signatureAsset,
                      width: 180,
                      height: 86,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 180,
                        height: 86,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('U THIHA TUN TAUK', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Text('Project Engineer', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('${CompanyInfo.name} ${CompanyInfo.info}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Image.asset(
              CompanyInfo.logoAsset,
              width: 88,
              height: 88,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.business,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CompanyInfo.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CompanyInfo.info.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Address: ${CompanyInfo.address}', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        Text('Phone: ${CompanyInfo.phone}', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 12),
        Container(height: 2, color: AppColors.textPrimary),
      ],
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          const Text(':  ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    TableRow row(List<Widget> cells, {bool header = false}) => TableRow(
      decoration: header ? const BoxDecoration(color: Color(0xFFF2F5FA)) : null,
      children: cells
          .map(
            (child) => Container(
              constraints: const BoxConstraints(minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              alignment: Alignment.center,
              child: child,
            ),
          )
          .toList(),
    );

    final rows = <TableRow>[
      row(
        const [
          Text('Item', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('Particular', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('Unit', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('Rate', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('Amount (Kyat)', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('Remark', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
        header: true,
      ),
      for (var index = 0; index < record.items.length; index++)
        row([
          Text('${index + 1}'),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(record.items[index].particular),
          ),
          Text(record.items[index].quantity.toStringAsFixed(2)),
          Text(record.items[index].unit ?? ''),
          Text(AppFormatters.currency(record.items[index].rate)),
          Text(AppFormatters.currency(record.items[index].amount)),
          Text(record.items[index].remark ?? ''),
        ]),
      row([
        const Text('', style: TextStyle(fontWeight: FontWeight.w700)),
        const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
        const Text(''),
        const Text(''),
        const Text(''),
        Text(
          AppFormatters.currency(record.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const Text('MMK'),
      ]),
    ];

    return Table(
      border: TableBorder.all(color: const Color(0xFF252525), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(0.7),
        1: FlexColumnWidth(2.7),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(0.8),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1.35),
        6: FlexColumnWidth(1),
      },
      children: rows,
    );
  }
}
