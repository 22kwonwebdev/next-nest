import 'quotation_item_model.dart';

class QuotationModel {
  final int? id;
  final String quotationNo;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String quotationDate;
  final double totalAmount;
  final double? sayAmount;
  final String createdAt;
  final String updatedAt;
  final List<QuotationItemModel> items;

  const QuotationModel({
    this.id,
    required this.quotationNo,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.quotationDate,
    required this.totalAmount,
    this.sayAmount,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory QuotationModel.fromMap(Map<String, dynamic> map) {
    return QuotationModel(
      id: map['id'] as int?,
      quotationNo: map['quotation_no'] as String,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      customerAddress: map['customer_address'] as String?,
      quotationDate: map['quotation_date'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      sayAmount: (map['say_amount'] as num?)?.toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotation_no': quotationNo,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'quotation_date': quotationDate,
      'total_amount': totalAmount,
      'say_amount': sayAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  QuotationModel copyWith({
    int? id,
    String? quotationNo,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? quotationDate,
    double? totalAmount,
    double? sayAmount,
    String? createdAt,
    String? updatedAt,
    List<QuotationItemModel>? items,
  }) {
    return QuotationModel(
      id: id ?? this.id,
      quotationNo: quotationNo ?? this.quotationNo,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      quotationDate: quotationDate ?? this.quotationDate,
      totalAmount: totalAmount ?? this.totalAmount,
      sayAmount: sayAmount ?? this.sayAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
