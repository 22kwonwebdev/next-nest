import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/quotation_form_viewmodel.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/section_header.dart';
import 'widgets/quotation_item_card.dart';

class QuotationFormScreen extends StatefulWidget {
  final int? quotationId;

  const QuotationFormScreen({super.key, this.quotationId});

  @override
  State<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends State<QuotationFormScreen> {
  late final QuotationFormViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = QuotationFormViewModel(quotationId: widget.quotationId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.load());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current =
        DateTime.tryParse(_viewModel.quotationDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _viewModel.setDate(picked);
    }
  }

  Future<void> _save() async {
    final saved = await _viewModel.save();
    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop(true);
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QuotationFormViewModel>.value(
      value: _viewModel,
      child: Consumer<QuotationFormViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                viewModel.isEdit ? 'Edit Quotation' : 'New Quotation',
              ),
            ),
            body: viewModel.isLoading
                ? const LoadingWidget()
                : _buildForm(context, viewModel),
            bottomNavigationBar: viewModel.isLoading
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: AppButton(
                        label: viewModel.isEdit ? 'Update' : 'Save Quotation',
                        icon: Icons.save_outlined,
                        isLoading: viewModel.isSaving,
                        onPressed: _save,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, QuotationFormViewModel vm) {
    return AppBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SectionHeader(title: 'Quotation Information'),
          const SizedBox(height: 8),
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: vm.quotationNoController,
                    labelText: 'Quotation No',
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                      ),
                      child: Text(
                        vm.quotationDate.isEmpty
                            ? 'Select date'
                            : AppFormatters.date(vm.quotationDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionHeader(title: 'Customer Information'),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              children: [
                AppTextField(
                  controller: vm.customerNameController,
                  labelText: 'Customer name *',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: vm.customerPhoneController,
                  labelText: 'Phone (optional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: vm.customerAddressController,
                  labelText: 'Address (optional)',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SectionHeader(
            title: 'Items',
            trailing: TextButton.icon(
              onPressed: vm.addItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < vm.items.length; i++) ...[
            QuotationItemCard(
              item: vm.items[i],
              index: i,
              canRemove: vm.items.length > 1,
              onChanged: vm.notifyItemChanged,
              onRemove: () => vm.removeItem(i),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),

          const SectionHeader(title: 'Charges & Grand Total'),
          const SizedBox(height: 8),
          GlassCard(
            tint: AppColors.primary.withValues(alpha: 0.08),
            child: Column(
              children: [
                  _summaryLine('Items amount', vm.baseAmount),
                  _summaryLine('Supervision charge (5%)', vm.supervisionCharge),
                  _summaryLine('Safety charge (3%)', vm.safetyCharge),
                  const Divider(),
                  _summaryLine('Grand total', vm.totalAmount, bold: true),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: vm.sayAmountController,
                    labelText: 'Say amount (optional)',
                    hintText: 'Enter the amount to quote to the client',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(
            AppFormatters.currency(amount),
            style: TextStyle(
              fontSize: bold ? 20 : 16,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
