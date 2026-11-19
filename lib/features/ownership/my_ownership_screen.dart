import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/ownership_model.dart';

class MyOwnershipScreen extends ConsumerWidget {
  const MyOwnershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownershipAsync = ref.watch(userOwnershipProvider);
    final paymentsAsync = ref.watch(userPaymentRequestsProvider);
    final buybacksAsync = ref.watch(userBuybacksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'My Ownership & Buyback Offers',
            subtitle:
                'Track verified ownership lots, pending payment proofs, and buyback requests.',
          ),
          const SizedBox(height: 16),
          buybacksAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (buybacks) {
              final awaiting = buybacks
                  .where((b) => b.status == 'awaiting_user_acceptance')
                  .toList();
              if (awaiting.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Buyback Offers Awaiting Your Decision',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...awaiting.map((b) => Card(
                        color: AppColors.emeraldSoft.withValues(alpha: 0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${b.projectTitle} (${b.packName})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                'Confirmed Price: ${AppFormatters.pkr(b.proposedBuybackPrice)} | Deduction: ${AppFormatters.pkr(b.deductionAmount)} | Net Credit: ${AppFormatters.pkr(b.netPayoutAmount)}',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: () async {
                                      await ref
                                          .read(firebaseServiceProvider)
                                          .userRespondBuyback(
                                              buybackId: b.id, accept: true);
                                    },
                                    child: const Text('Accept & Transfer'),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () async {
                                      await ref
                                          .read(firebaseServiceProvider)
                                          .userRespondBuyback(
                                              buybackId: b.id, accept: false);
                                    },
                                    child: const Text('Reject Offer'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
          Text('Verified Ownership Records',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ownershipAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (records) {
              if (records.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.verified_outlined,
                  title: 'No Verified Ownership Yet',
                  message:
                      'Ownership records are created once admin verifies your manual payment.',
                );
              }
              return Column(
                children: records.map((r) {
                  final canBuyback =
                      r.currentStatus == OwnershipStatus.active &&
                          r.remainingCapital > 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${r.projectTitle} — ${r.packName}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                StatusBadge(status: r.currentStatus),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 20,
                              runSpacing: 8,
                              children: [
                                Text(
                                    'Purchased: ${AppFormatters.pkr(r.purchaseAmount)}'),
                                Text(
                                    'Remaining Capital: ${AppFormatters.pkr(r.remainingCapital)}'),
                                Text(
                                    'Share: ${r.ownershipPercentage.toStringAsFixed(2)}%'),
                                Text(
                                    'Realized Profit: ${AppFormatters.pkr(r.realizedProfit)}'),
                                Text(
                                    'Date: ${AppFormatters.date(r.purchaseDate)}'),
                              ],
                            ),
                            if (canBuyback) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await ref
                                      .read(firebaseServiceProvider)
                                      .requestBuyback(ownershipId: r.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Buyback request submitted. Subject to admin review and available funds.'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.swap_horiz),
                                label: const Text(
                                    'Request Buyback (10% Deduction Policy)'),
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
          Text('Manual Payment Requests',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          paymentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (payments) {
              if (payments.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No payment submissions yet.'),
                  ),
                );
              }
              return Column(
                children: payments
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                  '${p.projectTitle} • ${p.packName} × ${p.quantity}'),
                              subtitle: Text(
                                  '${p.paymentMethod.toUpperCase()} • TXN: ${p.transactionReference} • ${AppFormatters.pkr(p.totalAmount)}'),
                              trailing: StatusBadge(status: p.status),
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
