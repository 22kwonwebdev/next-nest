class ReceivedItemModel {
  final int? id;
  final int? receivedId;
  final int position;
  final String particular;
  final double quantity;
  final String? unit;
  final double rate;
  final double amount;
  final String? remark;

  const ReceivedItemModel({
    this.id,
    this.receivedId,
    required this.position,
    required this.particular,
    required this.quantity,
    this.unit,
    required this.rate,
    required this.amount,
    this.remark,
  });

  factory ReceivedItemModel.fromMap(Map<String, Object?> map) {
    return ReceivedItemModel(
      id: map['id'] as int?,
      receivedId: map['received_id'] as int?,
      position: map['position'] as int? ?? 0,
      particular: map['particular'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] as String?,
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      remark: map['remark'] as String?,
    );
  }
}
