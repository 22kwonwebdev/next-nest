import 'package:flutter/foundation.dart';

import '../models/quotation_model.dart';
import '../repositories/quotation_repository.dart';

class QuotationListViewModel extends ChangeNotifier {
  final QuotationRepository _repository;

  QuotationListViewModel({QuotationRepository? repository})
    : _repository = repository ?? QuotationRepository();

  List<QuotationModel> _quotations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<QuotationModel> get quotations => _quotations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  Future<void> loadQuotations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quotations = await _repository.getAllQuotations(
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    } catch (e) {
      _errorMessage = 'Failed to load quotations';
      if (kDebugMode) debugPrint('Load quotations error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await loadQuotations();
  }

  Future<void> deleteQuotation(int id) async {
    try {
      await _repository.deleteQuotation(id);
      _quotations.removeWhere((q) => q.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete quotation';
      notifyListeners();
      if (kDebugMode) debugPrint('Delete quotation error: $e');
    }
  }

  Future<String> generateQuotationNo() => _repository.generateQuotationNo();
}
