class QuotationItemModel {
  final int? id;
  final int quotationId;
  final String itemName;
  final String categoryName;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double amount;
  final String? remark;

  const QuotationItemModel({
    this.id,
    required this.quotationId,
    required this.itemName,
    this.categoryName = 'General',
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.amount,
    this.remark,
  });

  double get computedAmount => quantity * unitPrice;

  factory QuotationItemModel.fromMap(Map<String, dynamic> map) {
    return QuotationItemModel(
      id: map['id'] as int?,
      quotationId: map['quotation_id'] as int,
      itemName: map['item_name'] as String,
      categoryName: map['category_name'] as String? ?? 'General',
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String?,
      unitPrice: (map['unit_price'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      remark: map['remark'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotation_id': quotationId,
      'item_name': itemName,
      'category_name': categoryName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'amount': amount,
      'remark': remark,
    };
  }

  QuotationItemModel copyWith({
    int? id,
    int? quotationId,
    String? itemName,
    String? categoryName,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? amount,
    String? remark,
  }) {
    return QuotationItemModel(
      id: id ?? this.id,
      quotationId: quotationId ?? this.quotationId,
      itemName: itemName ?? this.itemName,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      amount: amount ?? this.amount,
      remark: remark ?? this.remark,
    );
  }
}
