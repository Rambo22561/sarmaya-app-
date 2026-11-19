import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodAsync = ref.watch(currentSubscriptionPeriodProvider);
    final invoicesAsync = ref.watch(userSubscriptionInvoicesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Monthly Shared Expense Subscription',
            subtitle:
                'Company operating expenses are divided equally among eligible active paying members.',
          ),
          const SizedBox(height: 16),
          periodAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (period) {
              if (period == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                        'Monthly expense statement has not been published for this month yet.'),
                  ),
                );
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Period: ${period.monthLabel}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Per Member: ${AppFormatters.pkr(period.effectiveFee, showDecimals: true)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Formula: ${AppFormatters.pkr(period.totalMonthlyExpenses)} total expenses ÷ ${period.eligibleActiveMembers} eligible members = ${AppFormatters.pkr(period.calculatedSharePerMember, showDecimals: true)} per member',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (period.promoEnabled) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Promotional Period Active: ${AppFormatters.pkr(period.promoAmount)} (${AppFormatters.date(period.promoStartDate)} – ${AppFormatters.date(period.promoEndDate)})',
                          style: const TextStyle(
                            color: AppColors.infoBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      Text('Expense Breakdown',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: period.expenseBreakdown.entries
                            .map((e) => Chip(
                                  label: Text(
                                    '${e.key.replaceAll('_', ' ').toUpperCase()}: ${AppFormatters.pkr(e.value)}',
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('My Subscription Invoices & Payment History',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          invoicesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (invoices) {
              if (invoices.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Subscription Invoices Yet',
                  message:
                      'Invoices appear here when monthly company expenses are finalized.',
                );
              }

              return Column(
                children: invoices
                    .map((inv) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              title: Text('Month: ${inv.monthKey}'),
                              subtitle: Text(
                                'Amount: ${AppFormatters.pkr(inv.amountDue, showDecimals: true)}'
                                '${inv.isPromoApplied ? ' (Promo Applied)' : ''}',
                              ),
                              trailing: inv.status == 'due'
                                  ? FilledButton(
                                      onPressed: () async {
                                        try {
                                          await ref
                                              .read(firebaseServiceProvider)
                                              .paySubscriptionInvoice(inv.id);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Subscription paid from wallet balance.')));
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(e.toString())));
                                        }
                                      },
                                      child: const Text('Pay from Wallet'),
                                    )
                                  : StatusBadge(status: inv.status),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
