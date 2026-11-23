import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/received_model.dart';
import '../../repositories/received_repository.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/loading_widget.dart';
import 'received_detail_screen.dart';
import 'received_form_screen.dart';

class ReceivedListScreen extends StatefulWidget {
  const ReceivedListScreen({super.key});

  @override
  State<ReceivedListScreen> createState() => _ReceivedListScreenState();
}

class _ReceivedListScreenState extends State<ReceivedListScreen> {
  final ReceivedRepository _repository = ReceivedRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<ReceivedModel>> _records;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _records = _repository.getAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({int? id}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceivedFormScreen(receivedId: id)),
    );
    if (mounted) {
      setState(() {
        _reload();
      });
    }
  }

  Future<void> _delete(ReceivedModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete received document?'),
        content: Text('Delete ${record.receivedNo}? This cannot be undone.'),
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
      await _repository.delete(record.id!);
      if (mounted) {
        setState(() {
          _reload();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Received')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Received'),
      ),
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GlassContainer(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by received no, project, or subject',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ReceivedModel>>(
                future: _records,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _reload();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'Could not load received documents. Retry',
                        ),
                      ),
                    );
                  }
                  final allRecords = snapshot.data ?? const <ReceivedModel>[];
                  final query = _searchController.text.trim().toLowerCase();
                  final records = query.isEmpty
                      ? allRecords
                      : allRecords.where((record) {
                          return record.receivedNo.toLowerCase().contains(query) ||
                              record.projectTitle.toLowerCase().contains(query) ||
                              record.subject.toLowerCase().contains(query) ||
                              record.intentionTo.toLowerCase().contains(query);
                        }).toList();
                  if (records.isEmpty) {
                    return EmptyState(
                      icon: Icons.move_to_inbox_outlined,
                      title: query.isEmpty
                          ? 'No received documents yet'
                          : 'No received documents found',
                      subtitle: query.isEmpty
                          ? 'Create a received document to keep a local record.'
                          : 'Try a different search term.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReceivedDetailScreen(
                                receivedId: record.id!,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) {
                              setState(() {
                                _reload();
                              });
                            }
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.projectTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${record.receivedNo} · ${AppFormatters.date(record.receivedDate)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      record.subject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') _openForm(id: record.id);
                                  if (action == 'delete') _delete(record);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
