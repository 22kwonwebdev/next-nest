import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/quotation_item_model.dart';
import '../models/quotation_model.dart';
import '../repositories/quotation_repository.dart';

class QuotationItemForm {
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  QuotationItemForm({
    String name = '',
    String category = 'General',
    String quantity = '1',
    String unit = '',
    String price = '0',
    String remark = '',
  }) {
    categoryController.text = category;
    nameController.text = name;
    quantityController.text = quantity;
    unitController.text = unit;
    priceController.text = price;
    remarkController.text = remark;
  }

  double get quantity => double.tryParse(quantityController.text.trim()) ?? 0;

  double get unitPrice => double.tryParse(priceController.text.trim()) ?? 0;

  double get amount => quantity * unitPrice;

  bool get hasName => nameController.text.trim().isNotEmpty;

  QuotationItemModel toModel(int quotationId) {
    return QuotationItemModel(
      quotationId: quotationId,
      itemName: nameController.text.trim(),
      categoryName: categoryController.text.trim(),
      quantity: quantity,
      unit: unitController.text.trim().isEmpty
          ? null
          : unitController.text.trim(),
      unitPrice: unitPrice,
      amount: amount,
      remark: remarkController.text.trim().isEmpty
          ? null
          : remarkController.text.trim(),
    );
  }

  void dispose() {
    categoryController.dispose();
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
    remarkController.dispose();
  }
}

class QuotationFormViewModel extends ChangeNotifier {
  final QuotationRepository _repository;

  QuotationFormViewModel({QuotationRepository? repository, this.quotationId})
    : _repository = repository ?? QuotationRepository();

  final int? quotationId;

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController customerAddressController =
      TextEditingController();
  final TextEditingController quotationNoController = TextEditingController();
  final TextEditingController sayAmountController = TextEditingController();

  final List<QuotationItemForm> items = [];

  String _quotationDate = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  String get quotationDate => _quotationDate;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isEdit => quotationId != null;

  double get baseAmount => items.fold(0, (sum, item) => sum + item.amount);
  double get supervisionCharge => baseAmount * 0.05;
  double get safetyCharge => baseAmount * 0.03;
  double get totalAmount => baseAmount + supervisionCharge + safetyCharge;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEdit) {
        final quotation = await _repository.getQuotationById(quotationId!);
        if (quotation == null) {
          _errorMessage = 'Quotation not found';
          return;
        }
        _populateFromQuotation(quotation);
      } else {
        quotationNoController.text = await _repository.generateQuotationNo();
        _quotationDate = _repository.todayString();
        addItem();
      }
    } catch (e) {
      _errorMessage = 'Failed to load quotation';
      if (kDebugMode) debugPrint('Load quotation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populateFromQuotation(QuotationModel quotation) {
    quotationNoController.text = quotation.quotationNo;
    customerNameController.text = quotation.customerName;
    customerPhoneController.text = quotation.customerPhone ?? '';
    customerAddressController.text = quotation.customerAddress ?? '';
    _quotationDate = quotation.quotationDate;
    sayAmountController.text = quotation.sayAmount == null
        ? ''
        : _formatNumber(quotation.sayAmount!);

    items
      ..clear()
      ..addAll(
        quotation.items.map(
          (item) => QuotationItemForm(
            name: item.itemName,
            category: item.categoryName,
            quantity: _formatNumber(item.quantity),
            unit: item.unit ?? '',
            price: _formatNumber(item.unitPrice),
            remark: item.remark ?? '',
          ),
        ),
      );
  }

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  void setDate(DateTime date) {
    _quotationDate =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void addItem() {
    items.add(QuotationItemForm());
    notifyListeners();
  }

  void removeItem(int index) {
    if (items.length <= 1) return;
    items.removeAt(index).dispose();
    notifyListeners();
  }

  void notifyItemChanged() => notifyListeners();

  /// Returns an error message, or null if input is valid.
  String? validate() {
    if (customerNameController.text.trim().isEmpty) {
      return 'Customer name is required';
    }
    if (_quotationDate.isEmpty) {
      return 'Quotation date is required';
    }
    if (items.isEmpty) {
      return 'Add at least one item';
    }

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.categoryController.text.trim().isEmpty) {
        return 'Item ${i + 1}: category is required';
      }
      if (!item.hasName) {
        return 'Item ${i + 1}: name is required';
      }
      if (item.quantity <= 0) {
        return 'Item ${i + 1}: quantity must be greater than 0';
      }
      if (item.unitPrice < 0) {
        return 'Item ${i + 1}: unit price cannot be negative';
      }
    }

    final sayAmount = sayAmountController.text.trim();
    if (sayAmount.isNotEmpty && (double.tryParse(sayAmount) == null || double.parse(sayAmount) < 0)) {
      return 'Say amount must be a valid non-negative number';
    }

    return null;
  }

  Future<bool> save() async {
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetId = quotationId ?? 0;
      final model = QuotationModel(
        id: quotationId,
        quotationNo: quotationNoController.text.trim(),
        customerName: customerNameController.text.trim(),
        customerPhone: customerPhoneController.text.trim().isEmpty
            ? null
            : customerPhoneController.text.trim(),
        customerAddress: customerAddressController.text.trim().isEmpty
            ? null
            : customerAddressController.text.trim(),
        quotationDate: _quotationDate,
        totalAmount: totalAmount,
        sayAmount: double.tryParse(sayAmountController.text.trim()),
        createdAt: '',
        updatedAt: '',
        items: items.map((item) => item.toModel(targetId)).toList(),
      );

      if (isEdit) {
        await _repository.updateQuotation(model);
      } else {
        await _repository.insertQuotation(model);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save quotation';
      if (kDebugMode) debugPrint('Save quotation error: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    customerNameController.dispose();
    customerPhoneController.dispose();
    customerAddressController.dispose();
    quotationNoController.dispose();
    sayAmountController.dispose();
    for (final item in items) {
      item.dispose();
    }
    super.dispose();
  }
}
