import 'package:flutter_test/flutter_test.dart';

import 'package:quotation_app/core/utils/formatters.dart';

void main() {
  test('currency formats with thousands separators', () {
    expect(AppFormatters.currency(1234.5), '1,234.5');
    expect(AppFormatters.currency(0), '0');
    expect(AppFormatters.currency(1000000), '1,000,000');
  });

  test('date formats ISO string', () {
    expect(AppFormatters.date('2026-11-13'), '13 Nov 2026');
    expect(AppFormatters.date('not-a-date'), 'not-a-date');
  });
}
