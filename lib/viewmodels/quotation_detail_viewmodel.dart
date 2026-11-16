import 'package:flutter/foundation.dart';

import '../models/quotation_model.dart';
import '../repositories/quotation_repository.dart';

class QuotationDetailViewModel extends ChangeNotifier {
  final QuotationRepository _repository;
  final int quotationId;

  QuotationDetailViewModel({
    required this.quotationId,
    QuotationRepository? repository,
  }) : _repository = repository ?? QuotationRepository();

  QuotationModel? _quotation;
  bool _isLoading = false;
  String? _errorMessage;

  QuotationModel? get quotation => _quotation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quotation = await _repository.getQuotationById(quotationId);
      if (_quotation == null) {
        _errorMessage = 'Quotation not found';
      }
    } catch (e) {
      _errorMessage = 'Failed to load quotation';
      if (kDebugMode) debugPrint('Load quotation detail error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> delete() async {
    try {
      await _repository.deleteQuotation(quotationId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete quotation';
      notifyListeners();
      if (kDebugMode) debugPrint('Delete quotation error: $e');
      return false;
    }
  }
}
