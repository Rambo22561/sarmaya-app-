import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class AdminWithdrawalsScreen extends ConsumerWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(allWithdrawalsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Withdrawal Approvals',
            subtitle:
                'Approve or reject member withdrawal requests via double-entry ledger settlement.',
          ),
          const SizedBox(height: 16),
          withdrawalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.payments_outlined,
                  title: 'No Withdrawal Requests',
                  message: 'Member payout requests will appear here.',
                );
              }
              return Column(
                children: items.map((w) {
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
                                  '${w.userName} • ${AppFormatters.pkr(w.amount)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                                StatusBadge(status: w.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${w.method.toUpperCase()} • ${w.accountTitle} (${w.accountNumber})${w.bankName != null && w.bankName!.isNotEmpty ? ' • ${w.bankName}' : ''}',
                            ),
                            if (w.status == 'pending') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: () => ref
                                        .read(firebaseServiceProvider)
                                        .processWithdrawal(
                                            withdrawalId: w.id, approve: true),
                                    child: const Text('Mark Paid & Approve'),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.dangerRed),
                                    onPressed: () => ref
                                        .read(firebaseServiceProvider)
                                        .processWithdrawal(
                                          withdrawalId: w.id,
                                          approve: false,
                                          adminNote:
                                              'Account details mismatch.',
                                        ),
                                    child: const Text('Reject & Refund'),
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
