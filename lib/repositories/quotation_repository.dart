import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/dashboard_stats.dart';
import '../models/quotation_item_model.dart';
import '../models/quotation_model.dart';

class QuotationRepository {
  final DatabaseHelper _dbHelper;

  QuotationRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const String _dateFormat = 'yyyy-MM-dd';
  static const String _dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  String _now() => DateFormat(_dateTimeFormat).format(DateTime.now());

  Future<List<QuotationModel>> getAllQuotations({String? search}) async {
    final db = await _dbHelper.database;

    final where = <String>[];
    final args = <Object>[];

    if (search != null && search.trim().isNotEmpty) {
      where.add('(quotation_no LIKE ? OR customer_name LIKE ?)');
      final pattern = '%${search.trim()}%';
      args.add(pattern);
      args.add(pattern);
    }

    final rows = await db.query(
      'quotations',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'quotation_date DESC, id DESC',
    );

    return rows.map(QuotationModel.fromMap).toList();
  }

  /// Aggregate dashboard statistics computed in SQL (no row loading).
  Future<DashboardStats> getDashboardStats() async {
    final db = await _dbHelper.database;
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total, '
      'COALESCE(SUM(total_amount), 0) AS total_value, '
      "SUM(CASE WHEN strftime('%Y-%m', created_at) = ? THEN 1 ELSE 0 END) "
      'AS this_month, '
      "SUM(CASE WHEN created_at >= datetime('now', '-7 days') "
      'THEN 1 ELSE 0 END) AS last_7d '
      'FROM quotations',
      [currentMonth],
    );

    return rows.isEmpty
        ? DashboardStats.empty
        : DashboardStats.fromMap(rows.first);
  }

  Future<List<QuotationModel>> getRecentQuotations({int limit = 5}) async {
    final db = await _dbHelper.database;

    final rows = await db.query(
      'quotations',
      orderBy: 'quotation_date DESC, id DESC',
      limit: limit,
    );

    return rows.map(QuotationModel.fromMap).toList();
  }

  /// Total quotation value grouped by month (yyyy-MM), newest first.
  Future<List<({String month, double total})>> getMonthlyTotals({
    int months = 6,
  }) async {
    final db = await _dbHelper.database;

    final rows = await db.rawQuery(
      "SELECT strftime('%Y-%m', quotation_date) AS month, "
      'COALESCE(SUM(total_amount), 0) AS total '
      'FROM quotations '
      "WHERE quotation_date >= date('now', ?) "
      'GROUP BY month '
      'ORDER BY month DESC '
      'LIMIT ?',
      ['-${months * 31} days', months],
    );

    return rows
        .map(
          (row) => (
            month: row['month'] as String,
            total: (row['total'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<QuotationModel?> getQuotationById(int id) async {
    final db = await _dbHelper.database;

    final rows = await db.query(
      'quotations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final quotation = QuotationModel.fromMap(rows.first);
    final items = await _getItemsForQuotation(db, id);
    return quotation.copyWith(items: items);
  }

  Future<List<QuotationItemModel>> _getItemsForQuotation(
    Database db,
    int quotationId,
  ) async {
    final rows = await db.query(
      'quotation_items',
      where: 'quotation_id = ?',
      whereArgs: [quotationId],
      orderBy: 'id ASC',
    );
    return _groupItemsByCategory(rows.map(QuotationItemModel.fromMap).toList());
  }

  List<QuotationItemModel> _groupItemsByCategory(List<QuotationItemModel> items) {
    final groups = <String, List<QuotationItemModel>>{};
    final labels = <String, String>{};
    for (final item in items) {
      final label = item.categoryName.trim().replaceAll(RegExp(r'\s+'), ' ');
      final key = label.toLowerCase();
      final canonicalLabel = labels.putIfAbsent(key, () => label);
      groups
          .putIfAbsent(key, () => [])
          .add(item.copyWith(categoryName: canonicalLabel));
    }
    return groups.values.expand((group) => group).toList();
  }

  Future<String> generateQuotationNo() async {
    final db = await _dbHelper.database;
    return _nextQuotationNo(db);
  }

  Future<String> _nextQuotationNo(DatabaseExecutor executor) async {
    final prefix = 'QT-${DateFormat('yyyyMMdd').format(DateTime.now())}-';

    final rows = await executor.query(
      'quotations',
      columns: ['quotation_no'],
      where: 'quotation_no LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'quotation_no DESC',
      limit: 1,
    );

    var next = 1;
    if (rows.isNotEmpty) {
      final last = rows.first['quotation_no'] as String;
      final suffix = last.substring(prefix.length);
      next = (int.tryParse(suffix) ?? 0) + 1;
    }

    return '$prefix${next.toString().padLeft(4, '0')}';
  }

  Future<int> insertQuotation(QuotationModel quotation) async {
    final now = _now();

    return _dbHelper.transaction((txn) async {
      final quotationNo = await _ensureUniqueQuotationNo(
        txn,
        quotation.quotationNo,
      );

      final quotationToInsert = quotation.copyWith(
        quotationNo: quotationNo,
        createdAt: now,
        updatedAt: now,
      );

      final quotationId = await txn.insert(
        'quotations',
        quotationToInsert.toMap()..remove('id'),
      );

      await _insertItems(txn, quotationId, quotation.items);
      return quotationId;
    });
  }

  Future<String> _ensureUniqueQuotationNo(
    Transaction txn,
    String preferredNo,
  ) async {
    final rows = await txn.query(
      'quotations',
      columns: ['id'],
      where: 'quotation_no = ?',
      whereArgs: [preferredNo],
      limit: 1,
    );
    if (rows.isEmpty) return preferredNo;
    return _nextQuotationNo(txn);
  }

  Future<int> updateQuotation(QuotationModel quotation) async {
    if (quotation.id == null) {
      throw ArgumentError('Quotation id is required for update');
    }

    final updated = quotation.copyWith(updatedAt: _now());

    return _dbHelper.transaction((txn) async {
      await txn.update(
        'quotations',
        updated.toMap()
          ..remove('id')
          ..remove('created_at'),
        where: 'id = ?',
        whereArgs: [quotation.id],
      );

      await txn.delete(
        'quotation_items',
        where: 'quotation_id = ?',
        whereArgs: [quotation.id],
      );

      await _insertItems(txn, quotation.id!, quotation.items);
      return quotation.id!;
    });
  }

  Future<int> deleteQuotation(int id) async {
    final db = await _dbHelper.database;
    return db.delete('quotations', where: 'id = ?', whereArgs: [id]);
  }

  String formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return DateFormat('dd MMM yyyy').format(date);
  }

  String todayString() => DateFormat(_dateFormat).format(DateTime.now());

  Future<void> _insertItems(
    Transaction txn,
    int quotationId,
    List<QuotationItemModel> items,
  ) async {
    for (final item in _groupItemsByCategory(items)) {
      await txn.insert('quotation_items', {
        'quotation_id': quotationId,
        'item_name': item.itemName,
        'category_name': item.categoryName,
        'quantity': item.quantity,
        'unit': item.unit,
        'unit_price': item.unitPrice,
        'amount': item.amount,
        'remark': item.remark,
      });
    }
  }

}
