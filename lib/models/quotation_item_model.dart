class QuotationItemModel {
  final int? id;
  final int quotationId;
  final int? categoryId;
  final String? serialNumber;
  final String itemName;
  final String categoryName;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double amount;
  final double? categoryAmount;
  final String? remark;

  const QuotationItemModel({
    this.id,
    required this.quotationId,
    this.categoryId,
    this.serialNumber,
    required this.itemName,
    this.categoryName = 'General',
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.amount,
    this.categoryAmount,
    this.remark,
  });

  double get computedAmount => quantity * unitPrice;

  factory QuotationItemModel.fromMap(Map<String, dynamic> map) {
    return QuotationItemModel(
      id: map['id'] as int?,
      quotationId: map['quotation_id'] as int,
      categoryId: map['category_id'] as int?,
      serialNumber: map['serial_number'] as String?,
      itemName: map['item_name'] as String,
      categoryName: map['category_name'] as String? ?? 'General',
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String?,
      unitPrice: (map['unit_price'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      categoryAmount: (map['category_amount'] as num?)?.toDouble(),
      remark: map['remark'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotation_id': quotationId,
      'category_id': categoryId,
      'serial_number': serialNumber,
      'item_name': itemName,
      'category_name': categoryName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'amount': amount,
      'category_amount': categoryAmount,
      'remark': remark,
    };
  }

  QuotationItemModel copyWith({
    int? id,
    int? quotationId,
    int? categoryId,
    String? serialNumber,
    String? itemName,
    String? categoryName,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? amount,
    double? categoryAmount,
    String? remark,
  }) {
    return QuotationItemModel(
      id: id ?? this.id,
      quotationId: quotationId ?? this.quotationId,
      categoryId: categoryId ?? this.categoryId,
      serialNumber: serialNumber ?? this.serialNumber,
      itemName: itemName ?? this.itemName,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      amount: amount ?? this.amount,
      categoryAmount: categoryAmount ?? this.categoryAmount,
      remark: remark ?? this.remark,
    );
  }
}
