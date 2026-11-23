import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/received_item_model.dart';
import '../models/received_model.dart';

class ReceivedRepository {
  ReceivedRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<List<ReceivedModel>> getAll() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'received_documents',
      orderBy: 'received_date DESC, id DESC',
    );
    return rows.map(ReceivedModel.fromMap).toList();
  }

  Future<ReceivedModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'received_documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final items = await db.query(
      'received_items',
      where: 'received_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC, id ASC',
    );
    return ReceivedModel.fromMap(rows.first).withItems(
      items.map(ReceivedItemModel.fromMap).toList(),
    );
  }

  Future<int> save(ReceivedModel received) async {
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    return _databaseHelper.transaction((txn) async {
      final id = received.id;
      late final int savedId;
      if (id == null) {
        final receivedNo = await _nextNumber(txn);
        savedId = await txn.insert('received_documents', {
          'received_no': receivedNo,
          'intention_to': received.intentionTo,
          'project_title': received.projectTitle,
          'subject': received.subject,
          'received_date': received.receivedDate,
          'total_amount': received.totalAmount,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        savedId = id;
        await txn.update(
          'received_documents',
          {
            'intention_to': received.intentionTo,
            'project_title': received.projectTitle,
            'subject': received.subject,
            'received_date': received.receivedDate,
            'total_amount': received.totalAmount,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.delete(
          'received_items',
          where: 'received_id = ?',
          whereArgs: [id],
        );
      }

      for (var position = 0; position < received.items.length; position++) {
        final item = received.items[position];
        await txn.insert('received_items', {
          'received_id': savedId,
          'position': position,
          'particular': item.particular,
          'quantity': item.quantity,
          'unit': item.unit,
          'rate': item.rate,
          'amount': item.amount,
          'remark': item.remark,
        });
      }
      return savedId;
    });
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return db.delete('received_documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> _nextNumber(DatabaseExecutor executor) async {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final prefix = 'RC-$date-';
    final rows = await executor.query(
      'received_documents',
      columns: ['received_no'],
      where: 'received_no LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'received_no DESC',
      limit: 1,
    );
    final next = rows.isEmpty
        ? 1
        : (int.tryParse(
                (rows.first['received_no'] as String).substring(prefix.length),
              ) ??
              0) +
            1;
    return '$prefix${next.toString().padLeft(4, '0')}';
  }
}

extension on ReceivedModel {
  ReceivedModel withItems(List<ReceivedItemModel> items) => ReceivedModel(
    id: id,
    receivedNo: receivedNo,
    intentionTo: intentionTo,
    projectTitle: projectTitle,
    subject: subject,
    receivedDate: receivedDate,
    totalAmount: totalAmount,
    createdAt: createdAt,
    updatedAt: updatedAt,
    items: items,
  );
}
