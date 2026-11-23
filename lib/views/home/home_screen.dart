import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard_stats.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_quotations.dart';
import 'widgets/summary_card.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onQuotationsTab;
  final VoidCallback? onSettingsTab;

  const HomeScreen({super.key, this.onQuotationsTab, this.onSettingsTab});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final stats = viewModel.stats;

    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            Positioned(
              top: 48,
              right: -80,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.045,
                    child: Image.asset(
                      CompanyInfo.logoAsset,
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: viewModel.isLoading
                  ? const LoadingWidget()
                  : viewModel.errorMessage != null
                  ? AppErrorWidget(
                      message: viewModel.errorMessage!,
                      onRetry: viewModel.refresh,
                    )
                  : RefreshIndicator(
                      onRefresh: viewModel.refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          DashboardHeader(onSettingsTap: onSettingsTab),
                          const SizedBox(height: 20),
                          _statsGrid(stats),
                          const SizedBox(height: 20),
                          QuickActions(
                            onViewQuotations: onQuotationsTab,
                            onSearchQuotations: onQuotationsTab,
                            onSettings: onSettingsTab,
                          ),
                          const SizedBox(height: 20),
                          RecentQuotations(onViewAll: onQuotationsTab),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        SummaryCard(
          icon: Icons.description_outlined,
          label: 'Total Quotations',
          value: '${stats.totalQuotations}',
          iconColor: AppColors.primary,
        ),
        SummaryCard(
          icon: Icons.calendar_month_outlined,
          label: 'This Month',
          value: '${stats.thisMonthCount}',
          iconColor: AppColors.info,
        ),
        SummaryCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Total Value',
          value: stats.totalValue >= 1000000
              ? _compact(stats.totalValue)
              : AppFormatters.currency(stats.totalValue),
          iconColor: AppColors.success,
        ),
        SummaryCard(
          icon: Icons.schedule_outlined,
          label: 'Last 7 Days',
          value: '${stats.last7DaysCount}',
          iconColor: AppColors.warning,
        ),
      ],
    );
  }

  String _compact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}
