import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quotation_model.dart';
import '../../viewmodels/quotation_list_viewmodel.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../quotation_detail/quotation_detail_screen.dart';
import '../quotation_form/quotation_form_screen.dart';
import 'widgets/quotation_card.dart';

class QuotationListScreen extends StatefulWidget {
  const QuotationListScreen({super.key});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationListViewModel>().loadQuotations();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<QuotationListViewModel>().search(value);
    });
  }

  Future<void> _confirmDelete(QuotationModel quotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text(
          'Delete quotation ${quotation.quotationNo} for '
          '${quotation.customerName}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<QuotationListViewModel>().deleteQuotation(
        quotation.id!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<QuotationListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quotations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
          );
          if (context.mounted) {
            context.read<QuotationListViewModel>().loadQuotations();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Quotation'),
      ),
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GlassContainer(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextFormField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by quotation no or customer',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<QuotationListViewModel>().search('');
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
            Expanded(child: _buildBody(viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(QuotationListViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingWidget();
    }

    if (viewModel.errorMessage != null) {
      return AppErrorWidget(
        message: viewModel.errorMessage!,
        onRetry: () => viewModel.loadQuotations(),
      );
    }

    if (viewModel.quotations.isEmpty) {
      return EmptyState(
        icon: Icons.description_outlined,
        title: viewModel.searchQuery.isEmpty
            ? 'No quotations yet'
            : 'No quotations found',
        subtitle: viewModel.searchQuery.isEmpty
            ? 'Tap + New to create your first quotation'
            : 'Try a different search term',
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadQuotations(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
        itemCount: viewModel.quotations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final quotation = viewModel.quotations[index];
          return QuotationCard(
            quotation: quotation,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      QuotationDetailScreen(quotationId: quotation.id!),
                ),
              );
              if (context.mounted) viewModel.loadQuotations();
            },
            onDelete: () => _confirmDelete(quotation),
          );
        },
      ),
    );
  }
}
