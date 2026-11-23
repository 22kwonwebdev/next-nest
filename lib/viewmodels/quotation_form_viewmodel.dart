import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/quotation_item_model.dart';
import '../models/quotation_category_model.dart';
import '../models/quotation_model.dart';
import '../repositories/quotation_repository.dart';

class QuotationItemForm {
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController serialController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController categoryAmountController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  QuotationItemForm({
    String name = '',
    String category = 'General',
    String quantity = '1',
    String unit = '',
    String price = '0',
    String remark = '',
    String serial = '',
    String categoryAmount = '',
  }) {
    categoryController.text = category;
    nameController.text = name;
    quantityController.text = quantity;
    unitController.text = unit;
    priceController.text = price;
    remarkController.text = remark;
    serialController.text = serial;
    categoryAmountController.text = categoryAmount;
  }

  double get quantity => double.tryParse(quantityController.text.trim()) ?? 0;

  double get unitPrice => double.tryParse(priceController.text.trim()) ?? 0;

  double get amount =>
      double.tryParse(categoryAmountController.text.trim()) ?? quantity * unitPrice;

  bool get hasName => nameController.text.trim().isNotEmpty;

  QuotationItemModel toModel(int quotationId) {
    return QuotationItemModel(
      quotationId: quotationId,
      serialNumber: serialController.text.trim().isEmpty ? null : serialController.text.trim(),
      itemName: nameController.text.trim(),
      categoryName: categoryController.text.trim(),
      quantity: quantity,
      unit: unitController.text.trim().isEmpty
          ? null
          : unitController.text.trim(),
      unitPrice: unitPrice,
      amount: quantity * unitPrice,
      categoryAmount: double.tryParse(categoryAmountController.text.trim()) ?? amount,
      remark: remarkController.text.trim().isEmpty
          ? null
          : remarkController.text.trim(),
    );
  }

  void dispose() {
    categoryController.dispose();
    serialController.dispose();
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
    categoryAmountController.dispose();
    remarkController.dispose();
  }
}

class QuotationCategoryForm {
  final nameController = TextEditingController();
  final rateController = TextEditingController(text: '0');
  final unitController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final amountController = TextEditingController(text: '0');
  final remarkController = TextEditingController();
  final List<QuotationItemForm> items = [];

  double get rate => double.tryParse(rateController.text.trim()) ?? 0;
  double get quantity => double.tryParse(quantityController.text.trim()) ?? 0;
  double get amount => items.fold(0, (sum, item) => sum + item.amount);

  void dispose() {
    nameController.dispose(); rateController.dispose(); unitController.dispose();
    quantityController.dispose(); amountController.dispose(); remarkController.dispose();
    for (final item in items) { item.dispose(); }
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

  final List<QuotationCategoryForm> categories = [];
  List<QuotationItemForm> get items => categories.expand((category) => category.items).toList();

  String _quotationDate = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  String get quotationDate => _quotationDate;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isEdit => quotationId != null;

  double get baseAmount {
    return categories.fold(0, (sum, category) => sum + category.amount);
  }
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
        addCategory();
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

    for (final category in categories) { category.dispose(); }
    categories.clear();
    final savedCategories = quotation.categories;
    if (savedCategories.isNotEmpty) {
      for (final saved in savedCategories) {
        final category = QuotationCategoryForm()
          ..nameController.text = saved.categoryName
          ..rateController.text = _formatNumber(saved.rate)
          ..unitController.text = saved.unit ?? ''
          ..quantityController.text = _formatNumber(saved.quantity)
          ..amountController.text = _formatNumber(saved.amount)
          ..remarkController.text = saved.remark ?? '';
        category.items.addAll(saved.items.map(_itemForm));
        categories.add(category);
      }
    } else {
      final grouped = <String, List<QuotationItemModel>>{};
      for (final item in quotation.items) { grouped.putIfAbsent(item.categoryName, () => []).add(item); }
      for (final entry in grouped.entries) {
        final first = entry.value.first;
        final category = QuotationCategoryForm()
          ..nameController.text = entry.key
          ..rateController.text = _formatNumber(first.unitPrice)
          ..unitController.text = first.unit ?? ''
          ..quantityController.text = _formatNumber(first.quantity)
          ..amountController.text = _formatNumber(first.categoryAmount ?? first.amount)
          ..remarkController.text = first.remark ?? '';
        category.items.addAll(entry.value.map(_itemForm));
        categories.add(category);
      }
    }
  }

  QuotationItemForm _itemForm(QuotationItemModel item) => QuotationItemForm(
    name: item.itemName, serial: item.serialNumber ?? '', category: item.categoryName,
    quantity: _formatNumber(item.quantity), unit: item.unit ?? '',
    price: _formatNumber(item.unitPrice), remark: item.remark ?? '',
  );

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

  void addCategory() {
    final category = QuotationCategoryForm()..items.add(QuotationItemForm());
    categories.add(category);
    notifyListeners();
  }

  void addItem(int categoryIndex) {
    categories[categoryIndex].items.add(QuotationItemForm());
    notifyListeners();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    final category = categories.removeAt(oldIndex);
    categories.insert(newIndex, category);
    notifyListeners();
  }

  void reorderItems(int categoryIndex, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    final items = categories[categoryIndex].items;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    notifyListeners();
  }

  void removeCategory(int index) {
    if (categories.length <= 1) return;
    categories.removeAt(index).dispose();
    notifyListeners();
  }

  void removeItem(int categoryIndex, int index) {
    final category = categories[categoryIndex];
    if (category.items.length <= 1) return;
    category.items.removeAt(index).dispose();
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
    if (categories.isEmpty) {
      return 'Add at least one category';
    }

    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      if (category.nameController.text.trim().isEmpty) return 'Category ${i + 1}: name is required';
      if (category.quantity <= 0) {
        return 'Category ${i + 1}: enter a valid quantity';
      }
      if (category.items.isEmpty) return 'Category ${i + 1}: add at least one item';
      for (var j = 0; j < category.items.length; j++) {
        final item = category.items[j];
        if (!item.hasName) return 'Category ${i + 1}, item ${j + 1}: name is required';
        if (item.quantity <= 0 || item.unitPrice < 0) return 'Category ${i + 1}, item ${j + 1}: enter a valid quantity and rate';
      }
    }

    final sayAmount = sayAmountController.text.trim();
    if (sayAmount.isNotEmpty && (double.tryParse(sayAmount) == null || double.parse(sayAmount) < 0)) {
      return 'Say amount must be a valid non-negative number';
    }

    return null;
  }

  Future<QuotationModel?> save() async {
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return null;
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
        categories: categories.map((category) => QuotationCategoryModel(
          quotationId: targetId,
          categoryName: category.nameController.text.trim(),
          rate: 0,
          unit: category.unitController.text.trim().isEmpty ? null : category.unitController.text.trim(),
          quantity: category.quantity,
          amount: category.amount,
          remark: category.remarkController.text.trim().isEmpty ? null : category.remarkController.text.trim(),
          items: category.items.map((item) => item.toModel(targetId).copyWith(
            categoryName: category.nameController.text.trim(),
            categoryAmount: category.amount,
          )).toList(),
        )).toList(),
        items: categories.expand((category) => category.items.map((item) => item.toModel(targetId).copyWith(categoryName: category.nameController.text.trim()))).toList(),
      );

      final savedId = isEdit
          ? await _repository.updateQuotation(model)
          : await _repository.insertQuotation(model);
      final savedQuotation = await _repository.getQuotationById(savedId);
      if (savedQuotation == null) {
        _errorMessage = 'Quotation saved, but its preview could not be loaded';
      }
      return savedQuotation;
    } catch (e) {
      _errorMessage = 'Failed to save quotation';
      if (kDebugMode) debugPrint('Save quotation error: $e');
      return null;
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
    for (final category in categories) { category.dispose(); }
    super.dispose();
  }
}
