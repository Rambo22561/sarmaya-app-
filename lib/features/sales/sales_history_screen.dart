import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(allSalesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Realized Product Sales History',
            subtitle:
                'Transparent breakdown of actual sales revenue, allocated cost, eligible expenses, 10% platform commission, and investor profit pool.',
          ),
          const SizedBox(height: 16),
          salesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (sales) {
              if (sales.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.point_of_sale_outlined,
                  title: 'No Sales Recorded Yet',
                  message:
                      'Unsold inventory is never counted as profit. Sales appear here once admin sells product stock.',
                );
              }

              return Column(
                children: sales
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.projectTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text(
                                        AppFormatters.date(s.saleDate),
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Wrap(
                                    spacing: 24,
                                    runSpacing: 10,
                                    children: [
                                      _SaleStat('Units Sold', '${s.unitsSold}'),
                                      _SaleStat(
                                          'Gross Sales',
                                          AppFormatters.pkr(s.grossRevenue)),
                                      _SaleStat(
                                          'Product Cost',
                                          AppFormatters.pkr(
                                              s.allocatedProductCost)),
                                      _SaleStat(
                                          'Eligible Expenses',
                                          AppFormatters.pkr(
                                              s.eligibleExpenses)),
                                      _SaleStat(
                                          'Distributable Profit',
                                          AppFormatters.pkr(
                                              s.distributableProfit)),
                                      _SaleStat(
                                          'Platform Fee (10%)',
                                          AppFormatters.pkr(
                                              s.platformCommission)),
                                      _SaleStat(
                                          'Investor Profit Pool',
                                          AppFormatters.pkr(
                                              s.investorProfitPool),
                                          highlight: true),
                                      _SaleStat(
                                          'Capital Returned',
                                          AppFormatters.pkr(s.capitalReturned)),
                                    ],
                                  ),
                                ],
                              ),
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

class _SaleStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SaleStat(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.emeraldDark : AppColors.navyPrimary,
          ),
        ),
      ],
    );
  }
}
