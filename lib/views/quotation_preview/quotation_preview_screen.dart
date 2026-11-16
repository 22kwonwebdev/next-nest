import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/quotation_model.dart';
import '../../services/image_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/glass_card.dart';
import 'widgets/quotation_document.dart';

class QuotationPreviewScreen extends StatefulWidget {
  final QuotationModel quotation;

  const QuotationPreviewScreen({super.key, required this.quotation});

  @override
  State<QuotationPreviewScreen> createState() => _QuotationPreviewScreenState();
}

class _QuotationPreviewScreenState extends State<QuotationPreviewScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final PdfService _pdfService = PdfService();
  final ImageService _imageService = ImageService();
  final TransformationController _transformController =
      TransformationController();
  bool _transformInitialized = false;

  bool _isExporting = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _initTransform(BoxConstraints constraints) {
    if (_transformInitialized) return;
    _transformInitialized = true;
    final scale = constraints.maxWidth / QuotationDocument.documentWidth;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transformController.value = Matrix4.diagonal3Values(scale, scale, 1);
    });
  }

  String get _baseName =>
      _imageService.safeFileName(widget.quotation.quotationNo);

  Future<void> _exportPdf() async {
    await _runExport(() async {
      final pngBytes = await _capturePng();
      final bytes = await _pdfService.buildQuotationPdf(pngBytes);
      final fileName = '$_baseName.pdf';
      final file = await _imageService.saveToLocal(fileName, bytes);
      await _shareFile(file);
      return 'PDF saved: ${file.path}';
    });
  }

  Future<void> _exportImage({required bool asJpg}) async {
    await _runExport(() async {
      final pngBytes = await _capturePng();
      final Uint8List bytes;
      final String ext;
      if (asJpg) {
        bytes = await _imageService.convertToJpg(pngBytes);
        ext = 'jpg';
      } else {
        bytes = pngBytes;
        ext = 'png';
      }
      final fileName = '$_baseName.$ext';
      final file = await _imageService.saveToLocal(fileName, bytes);
      await _shareFile(file);
      return 'Image saved: ${file.path}';
    });
  }

  Future<Uint8List> _capturePng() async {
    // Ensure the boundary has been laid out before capturing.
    await WidgetsBinding.instance.endOfFrame;
    final bytes = await _imageService.capturePng(_boundaryKey);
    if (bytes == null) {
      throw StateError('Could not capture quotation preview');
    }
    return bytes;
  }

  Future<void> _shareFile(File file) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  Future<void> _runExport(Future<String> Function() action) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final message = await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
      debugPrint('Export error: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quotation Preview')),
      body: Column(
        children: [
          Expanded(
            child: AppBackground(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _initTransform(constraints);
                  return InteractiveViewer(
                    transformationController: _transformController,
                    constrained: false,
                    minScale: 0.1,
                    maxScale: 5,
                    boundaryMargin: const EdgeInsets.all(200),
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: Material(
                        color: Colors.white,
                        child: SizedBox(
                          width: QuotationDocument.documentWidth,
                          child: QuotationDocument(quotation: widget.quotation),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildExportBar(context),
        ],
      ),
    );
  }

  Widget _buildExportBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _buildAction(
                icon: Icons.arrow_back,
                label: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              ),
              _buildAction(
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                onPressed: _isExporting ? null : _exportPdf,
              ),
              _buildAction(
                icon: Icons.image_outlined,
                label: 'PNG',
                onPressed: _isExporting
                    ? null
                    : () => _exportImage(asJpg: false),
              ),
              _buildAction(
                icon: Icons.photo_outlined,
                label: 'JPG',
                onPressed: _isExporting
                    ? null
                    : () => _exportImage(asJpg: true),
              ),
              _buildAction(
                icon: Icons.share_outlined,
                label: 'Share',
                onPressed: _isExporting ? null : _exportPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: enabled
                    ? theme.colorScheme.primary
                    : Colors.grey.shade400,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: enabled
                      ? theme.colorScheme.onSurface
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
