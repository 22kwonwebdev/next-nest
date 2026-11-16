import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:quotation_app/core/database/database_helper.dart';
import 'package:quotation_app/models/quotation_item_model.dart';
import 'package:quotation_app/models/quotation_model.dart';
import 'package:quotation_app/repositories/quotation_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late QuotationRepository repository;

  QuotationModel buildQuotation({List<QuotationItemModel>? items}) {
    return QuotationModel(
      quotationNo: 'QT-TEST-0001',
      customerName: 'Test Customer',
      customerPhone: '0912345678',
      customerAddress: 'Yangon',
      quotationDate: '2026-11-13',
      totalAmount: 0,
      createdAt: '',
      updatedAt: '',
      items: items ??
          [
            QuotationItemModel(
              quotationId: 0,
              itemName: 'Widget A',
              quantity: 2,
              unit: 'pcs',
              unitPrice: 1500,
              amount: 3000,
            ),
            QuotationItemModel(
              quotationId: 0,
              itemName: 'Widget B',
              quantity: 1.5,
              unit: 'kg',
              unitPrice: 2000,
              amount: 3000,
            ),
          ],
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quotation_test_');
    final dbPath = p.join(tempDir.path, 'test_quotation.db');
    final helper = DatabaseHelper.test(dbPath);
    repository = QuotationRepository(dbHelper: helper);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('insert and get quotation with items', () async {
    final id = await repository.insertQuotation(buildQuotation());
    expect(id, greaterThan(0));

    final fetched = await repository.getQuotationById(id);
    expect(fetched, isNotNull);
    expect(fetched!.customerName, 'Test Customer');
    expect(fetched.customerPhone, '0912345678');
    expect(fetched.items.length, 2);
    expect(fetched.items.first.itemName, 'Widget A');
    expect(fetched.items.first.amount, 3000);
    expect(fetched.items.last.quantity, 1.5);
  });

  test('list quotations and search', () async {
    await repository.insertQuotation(buildQuotation());

    var all = await repository.getAllQuotations();
    expect(all.length, 1);

    var searched = await repository.getAllQuotations(search: 'Widget');
    expect(searched.length, 0);

    searched = await repository.getAllQuotations(search: 'Test');
    expect(searched.length, 1);
  });

  test('generate unique quotation numbers', () async {
    final no1 = await repository.generateQuotationNo();
    expect(no1, startsWith('QT-'));

    // Insert with that number, next generated number must differ
    final q = buildQuotation();
    await repository.insertQuotation(q.copyWith(quotationNo: no1));

    final no2 = await repository.generateQuotationNo();
    expect(no2, isNot(equals(no1)));
  });

  test('insert resolves quotation number collision', () async {
    final q = buildQuotation(); // all use QT-TEST-0001
    final id1 = await repository.insertQuotation(q);
    final id2 = await repository.insertQuotation(q);

    final first = await repository.getQuotationById(id1);
    final second = await repository.getQuotationById(id2);
    expect(first!.quotationNo, isNot(equals(second!.quotationNo)));
  });

  test('update quotation replaces items', () async {
    final id = await repository.insertQuotation(buildQuotation());
    final fetched = await repository.getQuotationById(id);

    final updated = fetched!.copyWith(
      customerName: 'Updated Name',
      items: [
        QuotationItemModel(
          quotationId: id,
          itemName: 'Only Item',
          quantity: 1,
          unitPrice: 500,
          amount: 500,
        ),
      ],
    );
    await repository.updateQuotation(updated);

    final refetched = await repository.getQuotationById(id);
    expect(refetched!.customerName, 'Updated Name');
    expect(refetched.items.length, 1);
    expect(refetched.items.first.itemName, 'Only Item');
    expect(refetched.createdAt, fetched.createdAt);
    expect(refetched.createdAt, isNotEmpty);
    expect(refetched.updatedAt, isNotEmpty);
  });

  test('delete quotation cascades items', () async {
    final id = await repository.insertQuotation(buildQuotation());

    // verify items exist before delete via raw query
    final db = await DatabaseHelper.test(
      p.join(tempDir.path, 'test_quotation.db'),
    ).database;
    var items = await db.query('quotation_items');
    expect(items.length, 2);

    await repository.deleteQuotation(id);

    final fetched = await repository.getQuotationById(id);
    expect(fetched, isNull);

    items = await db.query('quotation_items');
    expect(items.length, 0);
  });
}
