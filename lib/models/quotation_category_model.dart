import 'quotation_item_model.dart';

class QuotationCategoryModel {
  final int? id;
  final int quotationId;
  final String categoryName;
  final double rate;
  final String? unit;
  final double quantity;
  final double amount;
  final String? remark;
  final List<QuotationItemModel> items;

  const QuotationCategoryModel({
    this.id,
    required this.quotationId,
    required this.categoryName,
    required this.rate,
    this.unit,
    required this.quantity,
    required this.amount,
    this.remark,
    this.items = const [],
  });
}
