import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(userWalletProvider);
    final ledgerAsync = ref.watch(userLedgerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'My Wallet',
            subtitle:
                'Double-entry ledger backed balances. Capital and profit are tracked independently.',
            trailing: Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/transactions'),
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Full Ledger'),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/withdraw'),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Withdraw Money'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          walletAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (wallet) {
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 240,
                    child: KpiStatCard(
                      title: 'Available Balance',
                      value: AppFormatters.pkr(wallet.availableBalance),
                      icon: Icons.account_balance_wallet_outlined,
                      accentColor: AppColors.emeraldAccent,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: KpiStatCard(
                      title: 'Pending Balance',
                      value: AppFormatters.pkr(wallet.pendingBalance),
                      icon: Icons.hourglass_bottom_outlined,
                      accentColor: AppColors.warningAmber,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: KpiStatCard(
                      title: 'Invested Capital',
                      value: AppFormatters.pkr(wallet.investedCapital),
                      icon: Icons.inventory_2_outlined,
                      accentColor: AppColors.navyPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: KpiStatCard(
                      title: 'Realized Profit',
                      value: AppFormatters.pkr(wallet.realizedProfit),
                      icon: Icons.trending_up,
                      accentColor: AppColors.emeraldDark,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: KpiStatCard(
                      title: 'Buyback Proceeds',
                      value: AppFormatters.pkr(wallet.buybackProceeds),
                      icon: Icons.swap_horiz,
                      accentColor: AppColors.infoBlue,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Recent Ledger Entries',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ledgerAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (entries) {
              if (entries.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No ledger activity recorded yet.'),
                  ),
                );
              }
              return Card(
                child: Column(
                  children: entries.take(10).map((e) {
                    final isCredit = e.entryType == 'credit';
                    return ListTile(
                      leading: Icon(
                        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isCredit
                            ? AppColors.emeraldDark
                            : AppColors.dangerRed,
                      ),
                      title: Text(e.description),
                      subtitle: Text(
                          '${e.category.replaceAll('_', ' ').toUpperCase()} • ${AppFormatters.dateTime(e.createdAt)}'),
                      trailing: Text(
                        '${isCredit ? '+' : '-'}${AppFormatters.pkr(e.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isCredit
                              ? AppColors.emeraldDark
                              : AppColors.dangerRed,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
