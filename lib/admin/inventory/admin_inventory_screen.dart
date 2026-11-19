import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class AdminInventoryScreen extends ConsumerWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownershipAsync = ref.watch(allOwnershipProvider);
    final buybacksAsync = ref.watch(allBuybacksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Inventory Ownership & Buyback Queue',
            subtitle:
                'Track multi-investor ownership allocations and review buyback requests.',
          ),
          const SizedBox(height: 16),
          Text('Buyback Requests',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          buybacksAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (buybacks) {
              if (buybacks.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No buyback requests submitted.'),
                  ),
                );
              }
              return Column(
                children: buybacks.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${b.userName} • ${b.projectTitle} (${b.packName})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                StatusBadge(status: b.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Original: ${AppFormatters.pkr(b.originalAmount)} • Proposed Net (after 10% deduction): ${AppFormatters.pkr(b.netPayoutAmount)}',
                            ),
                            if (b.status == 'pending_admin') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: () async {
                                      await ref
                                          .read(firebaseServiceProvider)
                                          .adminReviewBuyback(
                                            buybackId: b.id,
                                            approveOffer: true,
                                            confirmedBuybackPrice:
                                                b.originalAmount,
                                          );
                                    },
                                    child: const Text(
                                        'Confirm Buyback Offer (10% Deduction)'),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.dangerRed),
                                    onPressed: () async {
                                      await ref
                                          .read(firebaseServiceProvider)
                                          .adminReviewBuyback(
                                            buybackId: b.id,
                                            approveOffer: false,
                                            confirmedBuybackPrice: 0,
                                            adminNote:
                                                'Insufficient buyback liquidity.',
                                          );
                                    },
                                    child: const Text('Decline'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('All Ownership Records',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ownershipAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (records) {
              if (records.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No ownership records issued yet.'),
                  ),
                );
              }
              return Column(
                children: records
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                  '${r.projectTitle} • ${r.packName} × ${r.quantity}'),
                              subtitle: Text(
                                  'User: ${r.userId} • Capital: ${AppFormatters.pkr(r.remainingCapital)} • Share: ${r.ownershipPercentage.toStringAsFixed(2)}%'),
                              trailing: StatusBadge(status: r.currentStatus),
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
