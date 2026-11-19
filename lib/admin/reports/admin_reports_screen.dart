import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(allSalesProvider).valueOrNull ?? const [];
    final ownerships =
        ref.watch(allOwnershipProvider).valueOrNull ?? const [];
    final logsAsync = ref.watch(auditLogsProvider);

    final grossSales =
        sales.fold<double>(0, (s, e) => s + e.grossRevenue);
    final totalCommission =
        sales.fold<double>(0, (s, e) => s + e.platformCommission);
    final totalInvestorProfit =
        sales.fold<double>(0, (s, e) => s + e.investorProfitPool);
    final activeCapital =
        ownerships.fold<double>(0, (s, e) => s + e.remainingCapital);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Financial Reports & Audit Logs',
            subtitle:
                'Real-time summary of active capital, sales revenue, platform commissions, and immutable backend audit logs.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 240,
                child: KpiStatCard(
                  title: 'Active Product Capital',
                  value: AppFormatters.pkr(activeCapital),
                  icon: Icons.account_balance_wallet,
                  accentColor: AppColors.navyPrimary,
                ),
              ),
              SizedBox(
                width: 240,
                child: KpiStatCard(
                  title: 'Cumulative Sales',
                  value: AppFormatters.pkr(grossSales),
                  icon: Icons.point_of_sale,
                  accentColor: AppColors.emeraldAccent,
                ),
              ),
              SizedBox(
                width: 240,
                child: KpiStatCard(
                  title: '10% Platform Fee',
                  value: AppFormatters.pkr(totalCommission),
                  icon: Icons.percent,
                  accentColor: AppColors.infoBlue,
                ),
              ),
              SizedBox(
                width: 240,
                child: KpiStatCard(
                  title: 'Investor Profit Distributed',
                  value: AppFormatters.pkr(totalInvestorProfit),
                  icon: Icons.trending_up,
                  accentColor: AppColors.emeraldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('System Audit Logs',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          logsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (logs) {
              if (logs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No audit log entries recorded yet.'),
                  ),
                );
              }
              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final log = logs[i];
                    return ListTile(
                      leading: const Icon(Icons.security_outlined,
                          color: AppColors.navyPrimary),
                      title: Text('${log.action} • ${log.targetCollection}'),
                      subtitle: Text(
                          '${log.summary}\nActor: ${log.actorId} • ${AppFormatters.dateTime(log.createdAt)}'),
                      isThreeLine: true,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
