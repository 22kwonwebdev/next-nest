import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  /// Builds an A4 PDF page containing the captured quotation image.
  Future<Uint8List> buildQuotationPdf(Uint8List imageBytes) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Center(
          child: pw.FittedBox(
            fit: pw.BoxFit.contain,
            child: pw.Image(pw.MemoryImage(imageBytes)),
          ),
        ),
      ),
    );

    return doc.save();
  }
}
