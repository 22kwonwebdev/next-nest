import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_stats.dart';
import '../models/quotation_model.dart';
import '../repositories/quotation_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final QuotationRepository _repository;

  HomeViewModel({required QuotationRepository repository})
    : _repository = repository;

  DashboardStats _stats = DashboardStats.empty;
  List<QuotationModel> _recentQuotations = const [];
  List<({String month, double total})> _monthlyTotals = const [];

  bool _isLoading = true;
  String? _errorMessage;

  DashboardStats get stats => _stats;
  List<QuotationModel> get recentQuotations => _recentQuotations;
  List<({String month, double total})> get monthlyTotals => _monthlyTotals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Monthly totals aligned to the last [count] calendar months,
  /// including months with zero quotations.
  List<({String month, String label, double total})> get monthlyChartData {
    final now = DateTime.now();
    final byMonth = {
      for (final entry in _monthlyTotals) entry.month: entry.total,
    };
    final format = DateFormat('MMM');
    final keyFormat = DateFormat('yyyy-MM');

    return List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i));
      final key = keyFormat.format(date);
      return (month: key, label: format.format(date), total: byMonth[key] ?? 0);
    });
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getDashboardStats(),
        _repository.getRecentQuotations(limit: 5),
        _repository.getMonthlyTotals(months: 6),
      ]);

      _stats = results[0] as DashboardStats;
      _recentQuotations = results[1] as List<QuotationModel>;
      _monthlyTotals = results[2] as List<({String month, double total})>;
    } catch (e) {
      debugPrint('HomeViewModel load error: $e');
      _errorMessage = 'Failed to load dashboard';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}
