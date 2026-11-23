import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/quotation_form_viewmodel.dart';
import '../quotation_preview/quotation_preview_screen.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/quotation_totals_card.dart';
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
    final quotation = await _viewModel.save();
    if (!mounted) return;

    if (quotation != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuotationPreviewScreen(quotation: quotation),
        ),
      );
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
            title: 'Categories',
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: vm.categories.length,
            onReorder: vm.reorderCategories,
            itemBuilder: (context, index) => Padding(
              key: ValueKey(vm.categories[index]),
              padding: const EdgeInsets.only(bottom: 12),
              child: _categoryCard(vm, index),
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: vm.addCategory,
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
          const SizedBox(height: 16),

          const SectionHeader(title: 'Charges & Grand Total'),
          const SizedBox(height: 8),
          QuotationTotalsCard(
            itemsAmount: vm.baseAmount,
            supervisionCharge: vm.supervisionCharge,
            safetyCharge: vm.safetyCharge,
            grandTotal: vm.totalAmount,
            footer: AppTextField(
              controller: vm.sayAmountController,
              labelText: 'Say amount (optional)',
              hintText: 'Enter the amount to quote to the client',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(QuotationFormViewModel vm, int index) {
    final category = vm.categories[index];
    final numberInput = const TextInputType.numberWithOptions(decimal: true);
    final decimalFilter = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: AppTextField(
            controller: category.nameController,
            onChanged: (_) => vm.notifyItemChanged(),
            labelText: 'Category name *',
            textCapitalization: TextCapitalization.sentences,
          )),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.drag_indicator, color: AppColors.textSecondary),
            ),
          ),
          if (vm.categories.length > 1)
            IconButton(
              onPressed: () => vm.removeCategory(index),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppTextField(controller: category.quantityController, onChanged: (_) => vm.notifyItemChanged(), labelText: 'Category qty', keyboardType: numberInput, inputFormatters: decimalFilter)),
          const SizedBox(width: 8),
          Expanded(child: AppTextField(controller: category.unitController, onChanged: (_) => vm.notifyItemChanged(), labelText: 'Category unit')),
        ]),
        const SizedBox(height: 12),
        AppTextField(controller: category.remarkController, onChanged: (_) => vm.notifyItemChanged(), labelText: 'Category remark (optional)'),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Items'),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: category.items.length,
          onReorder: (oldIndex, newIndex) =>
              vm.reorderItems(index, oldIndex, newIndex),
          itemBuilder: (context, itemIndex) {
            final item = category.items[itemIndex];
            return Padding(
              key: ValueKey(item),
              padding: const EdgeInsets.only(bottom: 10),
              child: QuotationItemCard(
                item: item,
                index: itemIndex,
                canRemove: category.items.length > 1,
                onChanged: vm.notifyItemChanged,
                onRemove: () => vm.removeItem(index, itemIndex),
                dragHandle: ReorderableDragStartListener(
                  index: itemIndex,
                  child: const Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => vm.addItem(index),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
          ),
        ),
      ]),
    );
  }

}
