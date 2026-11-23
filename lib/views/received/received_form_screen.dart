import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/received_item_model.dart';
import '../../models/received_model.dart';
import '../../repositories/received_repository.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/section_header.dart';
import 'received_detail_screen.dart';

class ReceivedFormScreen extends StatefulWidget {
  const ReceivedFormScreen({super.key, this.receivedId});

  final int? receivedId;

  @override
  State<ReceivedFormScreen> createState() => _ReceivedFormScreenState();
}

class _ReceivedFormScreenState extends State<ReceivedFormScreen> {
  final ReceivedRepository _repository = ReceivedRepository();
  final _intentionController = TextEditingController();
  final _projectController = TextEditingController();
  final _subjectController = TextEditingController();
  final List<_ReceivedItemDraft> _items = [];
  late String _date;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  ReceivedModel? _loadedRecord;

  bool get _isEditing => widget.receivedId != null;
  double get _total => _items.fold(0, (sum, item) => sum + item.amount);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = _dateString(now);
    _load();
  }

  Future<void> _load() async {
    try {
      if (_isEditing) {
        final record = await _repository.getById(widget.receivedId!);
        if (!mounted) return;
        if (record == null) {
          setState(() {
            _error = 'Received document not found.';
            _loading = false;
          });
          return;
        }
        _loadedRecord = record;
        _intentionController.text = record.intentionTo;
        _projectController.text = record.projectTitle;
        _subjectController.text = record.subject;
        _date = record.receivedDate;
        _items.addAll(record.items.map(_ReceivedItemDraft.fromModel));
      } else {
        _items.add(_ReceivedItemDraft());
      }
    } catch (error) {
      _error = 'Could not load received document.';
      debugPrint('Load received document error: $error');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = _dateString(picked));
  }

  Future<void> _save() async {
    if (_intentionController.text.trim().isEmpty ||
        _projectController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty) {
      setState(() => _error = 'Intention To, Project Title, and Subject are required.');
      return;
    }
    if (_items.isEmpty || _items.any((item) =>
        item.particularController.text.trim().isEmpty ||
        item.quantity <= 0 || item.rate < 0)) {
      setState(() => _error = 'Add an item with a description, valid quantity, and rate.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final record = ReceivedModel(
        id: _loadedRecord?.id,
        receivedNo: _loadedRecord?.receivedNo ?? '',
        intentionTo: _intentionController.text.trim(),
        projectTitle: _projectController.text.trim(),
        subject: _subjectController.text.trim(),
        receivedDate: _date,
        totalAmount: _total,
        createdAt: _loadedRecord?.createdAt ?? '',
        updatedAt: _loadedRecord?.updatedAt ?? '',
        items: [
          for (var index = 0; index < _items.length; index++)
            _items[index].toModel(index),
        ],
      );
      final id = await _repository.save(record);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ReceivedDetailScreen(receivedId: id)),
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save received document.');
      debugPrint('Save received document error: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(index).dispose());
  }

  void _reorderItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  @override
  void dispose() {
    _intentionController.dispose();
    _projectController.dispose();
    _subjectController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Received' : 'New Received'),
      ),
      body: _loading
          ? const LoadingWidget()
          : _error == 'Received document not found.' ||
                _error == 'Could not load received document.'
          ? Center(child: Text(_error!))
          : AppBackground(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const SectionHeader(title: 'Document Information'),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _intentionController,
                          labelText: 'Intention To *',
                          hintText: 'Recipient or organization',
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _projectController,
                          labelText: 'Project Title *',
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _subjectController,
                          labelText: 'Subject *',
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              suffixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(AppFormatters.date(_date)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Items'),
                  const SizedBox(height: 8),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _items.length,
                    onReorder: _reorderItems,
                    itemBuilder: (context, index) => Padding(
                      key: ValueKey(_items[index]),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _itemCard(index),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _items.add(_ReceivedItemDraft())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    tint: AppColors.primary.withValues(alpha: 0.08),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${AppFormatters.currency(_total)} MMK',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    label: _isEditing ? 'Save Changes' : 'Save Received',
                    icon: Icons.save_outlined,
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _itemCard(int index) {
    final item = _items[index];
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle, color: AppColors.textSecondary),
                ),
              ),
              if (_items.length > 1)
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
            ],
          ),
          AppTextField(
            controller: item.particularController,
            labelText: 'Particular *',
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: item.quantityController,
                  labelText: 'Quantity',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: item.unitController,
                  labelText: 'Unit',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: item.rateController,
                  labelText: 'Rate',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: item.remarkController,
                  labelText: 'Remark',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppFormatters.currency(item.amount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceivedItemDraft {
  _ReceivedItemDraft({
    String particular = '',
    String quantity = '1',
    String unit = '',
    String rate = '0',
    String remark = '',
  }) {
    particularController.text = particular;
    quantityController.text = quantity;
    unitController.text = unit;
    rateController.text = rate;
    remarkController.text = remark;
  }

  final particularController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  final rateController = TextEditingController();
  final remarkController = TextEditingController();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get rate => double.tryParse(rateController.text) ?? 0;
  double get amount => quantity * rate;

  factory _ReceivedItemDraft.fromModel(ReceivedItemModel model) =>
      _ReceivedItemDraft(
        particular: model.particular,
        quantity: model.quantity.toString(),
        unit: model.unit ?? '',
        rate: model.rate.toString(),
        remark: model.remark ?? '',
      );

  ReceivedItemModel toModel(int position) => ReceivedItemModel(
    position: position,
    particular: particularController.text.trim(),
    quantity: quantity,
    unit: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
    rate: rate,
    amount: amount,
    remark: remarkController.text.trim().isEmpty ? null : remarkController.text.trim(),
  );

  void dispose() {
    particularController.dispose();
    quantityController.dispose();
    unitController.dispose();
    rateController.dispose();
    remarkController.dispose();
  }
}

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
