import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(allProjectsProvider).valueOrNull ?? const [];
    final payments =
        ref.watch(allPaymentRequestsProvider).valueOrNull ?? const [];
    final withdrawals =
        ref.watch(allWithdrawalsProvider).valueOrNull ?? const [];
    final buybacks = ref.watch(allBuybacksProvider).valueOrNull ?? const [];
    final sales = ref.watch(allSalesProvider).valueOrNull ?? const [];
    final users = ref.watch(allUsersProvider).valueOrNull ?? const [];

    final pendingPayments =
        payments.where((p) => p.status == 'pending').length;
    final pendingWithdrawals =
        withdrawals.where((w) => w.status == 'pending').length;
    final pendingBuybacks =
        buybacks.where((b) => b.status == 'pending_admin').length;
    final totalSalesRev =
        sales.fold<double>(0, (sum, s) => sum + s.grossRevenue);
    final totalCommission =
        sales.fold<double>(0, (sum, s) => sum + s.platformCommission);

    final width = MediaQuery.of(context).size.width;
    final cols = width >= 1200
        ? 4
        : width >= 720
            ? 2
            : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoModeBanner(),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Admin Operations Dashboard',
            subtitle:
                'Manage product projects, manual payment approvals, sales accounting, buybacks, and monthly expense sharing.',
            trailing: FilledButton.icon(
              onPressed: () => context.go('/admin/projects'),
              icon: const Icon(Icons.add),
              label: const Text('Manage Projects'),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: cols == 1 ? 2.4 : 1.75,
            children: [
              KpiStatCard(
                title: 'Pending Payments',
                value: '$pendingPayments',
                subtitle: 'Require manual verification',
                icon: Icons.fact_check_outlined,
                accentColor: AppColors.warningAmber,
                onTap: () => context.go('/admin/payments'),
              ),
              KpiStatCard(
                title: 'Pending Withdrawals',
                value: '$pendingWithdrawals',
                subtitle: 'Awaiting payout approval',
                icon: Icons.payments_outlined,
                accentColor: AppColors.infoBlue,
                onTap: () => context.go('/admin/withdrawals'),
              ),
              KpiStatCard(
                title: 'Buyback Requests',
                value: '$pendingBuybacks',
                subtitle: 'Awaiting admin price review',
                icon: Icons.swap_horiz,
                accentColor: AppColors.navyPrimary,
                onTap: () => context.go('/admin/inventory'),
              ),
              KpiStatCard(
                title: 'Active Projects',
                value: '${projects.where((p) => p.status == 'active').length}',
                subtitle: '${projects.length} total projects',
                icon: Icons.inventory_2_outlined,
                accentColor: AppColors.emeraldAccent,
                onTap: () => context.go('/admin/projects'),
              ),
              KpiStatCard(
                title: 'Total Sales Revenue',
                value: AppFormatters.pkr(totalSalesRev),
                subtitle: '${sales.length} sales batches',
                icon: Icons.point_of_sale_outlined,
                accentColor: AppColors.emeraldDark,
                onTap: () => context.go('/admin/sales'),
              ),
              KpiStatCard(
                title: 'Platform Commission (10%)',
                value: AppFormatters.pkr(totalCommission),
                subtitle: 'On positive distributable profit',
                icon: Icons.account_balance,
                accentColor: AppColors.navySecondary,
                onTap: () => context.go('/admin/reports'),
              ),
              KpiStatCard(
                title: 'Registered Members',
                value: '${users.length}',
                subtitle:
                    '${users.where((u) => u.isEligibleMember).length} eligible paying',
                icon: Icons.people_outline,
                accentColor: AppColors.infoBlue,
                onTap: () => context.go('/admin/users'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
