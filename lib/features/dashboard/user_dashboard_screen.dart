import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/ownership_model.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final walletAsync = ref.watch(userWalletProvider);
    final ownershipAsync = ref.watch(userOwnershipProvider);
    final paymentsAsync = ref.watch(userPaymentRequestsProvider);
    final subAsync = ref.watch(currentSubscriptionPeriodProvider);

    final profile = profileAsync.valueOrNull;
    final wallet = walletAsync.valueOrNull;
    final ownerships = ownershipAsync.valueOrNull ?? const [];
    final payments = paymentsAsync.valueOrNull ?? const [];
    final currentSub = subAsync.valueOrNull;

    final totalPurchased = ownerships.fold<double>(
        0, (sum, o) => sum + o.purchaseAmount);
    final activeOwnershipCount = ownerships
        .where((o) =>
            o.currentStatus == OwnershipStatus.active ||
            o.currentStatus == OwnershipStatus.partiallySold)
        .length;
    final soldCount = ownerships
        .where((o) => o.currentStatus == OwnershipStatus.sold)
        .length;
    final pendingPaymentsAmount = payments
        .where((p) => p.status == 'pending')
        .fold<double>(0, (sum, p) => sum + p.totalAmount);

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1200
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
          if (profile != null && !profile.emailVerified) ...[
            Card(
              color: AppColors.warningSoft,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warningAmber),
                title: const Text(
                  'Email Verification Pending',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                    'Verify your email to unlock withdrawals and eligible membership status.'),
                trailing: TextButton(
                  onPressed: () => context.go('/verify-email'),
                  child: const Text('Verify'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SectionHeader(
            title: 'Portfolio Overview',
            subtitle:
                'Welcome back, ${profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Member'}',
            trailing: FilledButton.icon(
              onPressed: () => context.go('/projects'),
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: const Text('Browse Projects'),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: crossAxisCount == 1 ? 2.4 : 1.75,
            children: [
              KpiStatCard(
                title: 'Total Purchased Amount',
                value: AppFormatters.pkr(totalPurchased),
                subtitle: '${ownerships.length} ownership records',
                icon: Icons.shopping_bag_outlined,
                accentColor: AppColors.navyPrimary,
                onTap: () => context.go('/my-ownership'),
              ),
              KpiStatCard(
                title: 'Active Product Ownership',
                value: '$activeOwnershipCount',
                subtitle: 'Active / partially sold packs',
                icon: Icons.inventory_2_outlined,
                accentColor: AppColors.infoBlue,
                onTap: () => context.go('/my-products'),
              ),
              KpiStatCard(
                title: 'Products Sold',
                value: '$soldCount',
                subtitle: 'Fully settled inventory lots',
                icon: Icons.sell_outlined,
                accentColor: AppColors.emeraldAccent,
                onTap: () => context.go('/sales-history'),
              ),
              KpiStatCard(
                title: 'Realized Profit',
                value: AppFormatters.pkr(wallet?.realizedProfit ?? 0),
                subtitle: 'Net after 10% platform fee',
                icon: Icons.trending_up_rounded,
                accentColor: AppColors.emeraldDark,
                onTap: () => context.go('/sales-history'),
              ),
              KpiStatCard(
                title: 'Available Balance',
                value: AppFormatters.pkr(wallet?.availableBalance ?? 0),
                subtitle: 'Ready for withdrawal',
                icon: Icons.account_balance_wallet_outlined,
                accentColor: AppColors.emeraldAccent,
                onTap: () => context.go('/wallet'),
              ),
              KpiStatCard(
                title: 'Pending Balance',
                value: AppFormatters.pkr(
                    (wallet?.pendingBalance ?? 0) + pendingPaymentsAmount),
                subtitle: 'Awaiting verification / settlement',
                icon: Icons.hourglass_top_rounded,
                accentColor: AppColors.warningAmber,
              ),
              KpiStatCard(
                title: 'Subscription Status',
                value: (profile?.subscriptionStatus ?? 'due').toUpperCase(),
                subtitle: currentSub != null
                    ? 'Current share: ${AppFormatters.pkr(currentSub.effectiveFee, showDecimals: true)}'
                    : 'Shared monthly expense model',
                icon: Icons.receipt_long_outlined,
                accentColor: profile?.subscriptionStatus == 'active'
                    ? AppColors.emeraldDark
                    : AppColors.warningAmber,
                onTap: () => context.go('/subscription'),
              ),
              KpiStatCard(
                title: 'Buyback Proceeds',
                value: AppFormatters.pkr(wallet?.buybackProceeds ?? 0),
                subtitle: 'Settled ownership buybacks',
                icon: Icons.swap_horiz_rounded,
                accentColor: AppColors.navyMuted,
                onTap: () => context.go('/wallet'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capital & Proceeds Allocation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Original capital is tracked and returned separately from realized profit.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 210,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                const labels = [
                                  'Capital',
                                  'Available',
                                  'Profit',
                                  'Pending'
                                ];
                                if (val.toInt() < 0 ||
                                    val.toInt() >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    labels[val.toInt()],
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          _bar(0, wallet?.investedCapital ?? 0,
                              AppColors.navyPrimary),
                          _bar(1, wallet?.availableBalance ?? 0,
                              AppColors.emeraldAccent),
                          _bar(2, wallet?.realizedProfit ?? 0,
                              AppColors.emeraldDark),
                          _bar(
                              3,
                              (wallet?.pendingBalance ?? 0) +
                                  pendingPaymentsAmount,
                              AppColors.warningAmber),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const RiskDisclaimerCard(),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    );
  }
}
