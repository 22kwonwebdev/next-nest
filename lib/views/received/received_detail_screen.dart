import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../models/received_model.dart';
import '../../repositories/received_repository.dart';
import '../../services/image_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/loading_widget.dart';
import 'received_document.dart';
import 'received_form_screen.dart';

class ReceivedDetailScreen extends StatefulWidget {
  const ReceivedDetailScreen({super.key, required this.receivedId});

  final int receivedId;

  @override
  State<ReceivedDetailScreen> createState() => _ReceivedDetailScreenState();
}

class _ReceivedDetailScreenState extends State<ReceivedDetailScreen> {
  final ReceivedRepository _repository = ReceivedRepository();
  final GlobalKey _documentKey = GlobalKey();
  final ImageService _imageService = ImageService();
  final PdfService _pdfService = PdfService();
  final TransformationController _transformController =
      TransformationController();
  late Future<ReceivedModel?> _recordFuture;
  bool _transformInitialized = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _recordFuture = _repository.getById(widget.receivedId);
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceivedFormScreen(receivedId: widget.receivedId),
      ),
    );
    if (mounted) {
      setState(() {
        _reload();
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete received document?'),
        content: const Text('This document will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.delete(widget.receivedId);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<Uint8List> _captureDocument() async {
    await WidgetsBinding.instance.endOfFrame;
    final png = await _imageService.capturePng(_documentKey);
    if (png == null) throw StateError('Could not capture received document');
    return png;
  }

  Future<Uint8List> _createBytes(_ReceivedExportFormat format) async {
    final png = await _captureDocument();
    return switch (format) {
      _ReceivedExportFormat.pdf => _pdfService.buildQuotationPdf(png),
      _ReceivedExportFormat.png => png,
      _ReceivedExportFormat.jpg => _imageService.convertToJpg(png),
    };
  }

  String _fileName(ReceivedModel record, _ReceivedExportFormat format) {
    final base = _imageService.safeFileName(record.receivedNo);
    return 'Received_$base.${format.extension}';
  }

  Future<void> _saveFormat(
    ReceivedModel record,
    _ReceivedExportFormat format,
  ) async {
    await _runExport(() async {
      final bytes = await _createBytes(format);
      final fileName = _fileName(record, format);
      if (format == _ReceivedExportFormat.pdf) {
        final location = await _imageService.saveToDownloads(fileName, bytes);
        return 'PDF saved to $location';
      }
      final location = await _imageService.saveImageToGallery(fileName, bytes);
      return '${format.label} saved to Photos/Gallery: $location';
    });
  }

  Future<void> _shareFormat(
    ReceivedModel record,
    _ReceivedExportFormat format,
  ) async {
    await _runExport(() async {
      final bytes = await _createBytes(format);
      final file = await _imageService.saveToLocal(
        _fileName(record, format),
        bytes,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${record.projectTitle} — ${record.subject}',
        ),
      );
      return '${format.label} ready to share';
    });
  }

  Future<void> _runExport(Future<String> Function() action) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final message = await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Received document export failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Document'),
        actions: [
          IconButton(
            onPressed: _edit,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _delete,
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
      body: FutureBuilder<ReceivedModel?>(
        future: _recordFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Received document not found.'));
          }
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (!_transformInitialized) {
                      _transformInitialized = true;
                      final scale =
                          constraints.maxWidth / ReceivedDocument.documentWidth;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _transformController.value =
                              Matrix4.diagonal3Values(scale, scale, 1);
                        }
                      });
                    }
                    return InteractiveViewer(
                      transformationController: _transformController,
                      constrained: false,
                      minScale: 0.15,
                      maxScale: 4,
                      boundaryMargin: const EdgeInsets.all(100),
                      child: RepaintBoundary(
                        key: _documentKey,
                        child: ReceivedDocument(record: snapshot.data!),
                      ),
                    );
                  },
                ),
              ),
              _buildExportBar(snapshot.data!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExportBar(ReceivedModel record) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _exportAction(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Save PDF',
                onPressed: _isExporting
                    ? null
                    : () => _saveFormat(record, _ReceivedExportFormat.pdf),
              ),
              _exportAction(
                icon: Icons.image_outlined,
                label: 'Save PNG',
                onPressed: _isExporting
                    ? null
                    : () => _saveFormat(record, _ReceivedExportFormat.png),
              ),
              _exportAction(
                icon: Icons.photo_outlined,
                label: 'Save JPG',
                onPressed: _isExporting
                    ? null
                    : () => _saveFormat(record, _ReceivedExportFormat.jpg),
              ),
              Expanded(
                child: PopupMenuButton<_ReceivedExportFormat>(
                  enabled: !_isExporting,
                  onSelected: (format) => _shareFormat(record, format),
                  itemBuilder: (context) => [
                    for (final format in _ReceivedExportFormat.values)
                      PopupMenuItem(
                        value: format,
                        child: Text('Share ${format.label}'),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 22,
                          color: _isExporting
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        const Text('Share', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
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
                color: onPressed == null
                    ? AppColors.textSecondary
                    : AppColors.primary,
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ReceivedExportFormat {
  pdf('PDF', 'pdf'),
  png('PNG', 'png'),
  jpg('JPG', 'jpg');

  const _ReceivedExportFormat(this.label, this.extension);
  final String label;
  final String extension;
}
