import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:quotation_app/services/pdf_service.dart';

void main() {
  // 1x1 transparent PNG used as a stand-in for the captured document image.
  final Uint8List pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  test('buildQuotationPdf returns valid PDF bytes', () async {
    final service = PdfService();
    final bytes = await service.buildQuotationPdf(pngBytes);

    expect(bytes.length, greaterThan(500));
    // PDF files start with %PDF
    expect(
      String.fromCharCodes(bytes.sublist(0, 4)),
      '%PDF',
    );
  });
}
