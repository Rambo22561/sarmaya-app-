import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allPaymentRequestsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Manual Payment Verification',
            subtitle:
                'Inspect screenshots and TXN references. Approving triggers Cloud Function ownership creation and stock deduction.',
          ),
          const SizedBox(height: 16),
          paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (payments) {
              if (payments.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.fact_check_outlined,
                  title: 'No Payment Requests',
                  message: 'Submitted payment proofs will appear here.',
                );
              }
              return Column(
                children: payments.map((p) {
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
                                    '${p.userName} (${p.userEmail})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                ),
                                StatusBadge(status: p.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${p.projectTitle} • ${p.packName} × ${p.quantity} = ${AppFormatters.pkr(p.totalAmount)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emeraldDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Method: ${p.paymentMethod.toUpperCase()} • TXN: ${p.transactionReference} • Sender: ${p.senderAccountNumber}',
                            ),
                            const SizedBox(height: 10),
                            if (p.proofImageUrl.isNotEmpty)
                              InkWell(
                                onTap: () => showDialog<void>(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                          maxWidth: 540, maxHeight: 620),
                                      child: InteractiveViewer(
                                        child: Image.network(p.proofImageUrl),
                                      ),
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'View Payment Screenshot',
                                  style: TextStyle(
                                    color: AppColors.infoBlue,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            if (p.status == 'pending') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(firebaseServiceProvider)
                                          .approvePaymentRequest(
                                              paymentRequestId: p.id);
                                    },
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Approve & Issue Ownership'),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.dangerRed),
                                    onPressed: () async {
                                      await ref
                                          .read(firebaseServiceProvider)
                                          .rejectPaymentRequest(
                                            paymentRequestId: p.id,
                                            reason:
                                                'Payment proof could not be verified.',
                                          );
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Reject'),
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
        ],
      ),
    );
  }
}
