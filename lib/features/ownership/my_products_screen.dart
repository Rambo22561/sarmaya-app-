import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class MyProductsScreen extends ConsumerWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownershipAsync = ref.watch(userOwnershipProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'My Products',
            subtitle: 'Real inventory packs owned by your account.',
            trailing: OutlinedButton(
              onPressed: () => context.go('/my-ownership'),
              child: const Text('Detailed Ownership'),
            ),
          ),
          const SizedBox(height: 16),
          ownershipAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (records) {
              if (records.isEmpty) {
                return EmptyStateView(
                  icon: Icons.inventory_2_outlined,
                  title: 'No Products Owned Yet',
                  message:
                      'Browse active projects and submit a pack purchase to build product ownership.',
                  action: FilledButton(
                    onPressed: () => context.go('/projects'),
                    child: const Text('Browse Projects'),
                  ),
                );
              }

              return Column(
                children: records
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.navyPrimary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.inventory_2_outlined,
                                    color: AppColors.navyPrimary),
                              ),
                              title: Text(
                                '${r.projectTitle} • ${r.packName}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Qty: ${r.remainingQuantity}/${r.quantity} packs • Capital: ${AppFormatters.pkr(r.remainingCapital)} • Realized Profit: ${AppFormatters.pkr(r.realizedProfit)}',
                                ),
                              ),
                              trailing: StatusBadge(status: r.currentStatus),
                              onTap: () =>
                                  context.go('/projects/${r.projectId}'),
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
