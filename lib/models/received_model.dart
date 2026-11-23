import 'received_item_model.dart';

class ReceivedModel {
  final int? id;
  final String receivedNo;
  final String intentionTo;
  final String projectTitle;
  final String subject;
  final String receivedDate;
  final double totalAmount;
  final String createdAt;
  final String updatedAt;
  final List<ReceivedItemModel> items;

  const ReceivedModel({
    this.id,
    required this.receivedNo,
    required this.intentionTo,
    required this.projectTitle,
    required this.subject,
    required this.receivedDate,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory ReceivedModel.fromMap(Map<String, Object?> map) {
    return ReceivedModel(
      id: map['id'] as int?,
      receivedNo: map['received_no'] as String? ?? '',
      intentionTo: map['intention_to'] as String? ?? '',
      projectTitle: map['project_title'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      receivedDate: map['received_date'] as String? ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
