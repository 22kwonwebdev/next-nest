import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static const _downloadsChannel = MethodChannel('quotation_app/downloads');
  /// Captures the widget inside [boundaryKey] as PNG bytes.
  /// Returns null if the boundary is not attached to the render tree.
  Future<Uint8List?> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Converts PNG bytes to JPG bytes using the pure-Dart `image` package.
  Future<Uint8List> convertToJpg(Uint8List pngBytes, {int quality = 90}) async {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      throw StateError('Failed to decode PNG for JPG conversion');
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }

  /// Saves Android exports to the public Downloads folder. Other platforms use
  /// the app documents directory, which does not require external storage access.
  Future<File> saveToLocal(String fileName, Uint8List bytes) async {
    if (Platform.isAndroid) {
      final path = await _downloadsChannel.invokeMethod<String>(
        'saveToDownloads',
        {'fileName': fileName, 'bytes': bytes},
      );
      if (path == null) throw StateError('Android did not return saved file path');
      return File(path);
    }

    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String safeFileName(String quotationNo) {
    return quotationNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }
}
