import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    final packsAsync = ref.watch(projectPacksProvider(projectId));

    return projectAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorStateView(message: err.toString()),
      data: (project) {
        if (project == null) {
          return const EmptyStateView(
            icon: Icons.inventory_2_outlined,
            title: 'Project Not Found',
            message: 'This product project may have been archived or removed.',
          );
        }

        final stockRatio = project.totalStockUnits > 0
            ? project.availableStockUnits / project.totalStockUnits
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1020),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/projects'),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          project.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      StatusBadge(status: project.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (project.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: project.imageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            project.imageUrls[i],
                            width: 320,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Economics & Inventory',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(project.description),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 24,
                            runSpacing: 12,
                            children: [
                              _MetricChip(
                                label: 'Product Unit Cost',
                                value: AppFormatters.pkr(project.productCost),
                              ),
                              _MetricChip(
                                label: 'Expected Selling Price',
                                value: AppFormatters.pkr(
                                    project.expectedSellingPrice),
                              ),
                              _MetricChip(
                                label: 'Available Units',
                                value:
                                    '${project.availableStockUnits} / ${project.totalStockUnits}',
                              ),
                              _MetricChip(
                                label: 'Sold Units',
                                value: '${project.soldUnits}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: stockRatio.clamp(0.0, 1.0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.emeraldAccent,
                            backgroundColor: AppColors.borderLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Available Ownership Packs',
                    subtitle:
                        'Minimum purchase is 1 pack. Multiple investors may co-own product stock.',
                    trailing: FilledButton.icon(
                      onPressed: () =>
                          context.go('/projects/${project.id}/packs'),
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Select Packs'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  packsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading packs: $e'),
                    data: (packs) {
                      if (packs.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No packs configured yet by admin.'),
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: packs
                            .map((pack) => SizedBox(
                                  width: 230,
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(pack.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          const SizedBox(height: 4),
                                          Text(
                                            AppFormatters.pkr(pack.price),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.emeraldDark,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Stock: ${pack.stockQuantity} packs (${pack.unitsPerPack} unit/pack)',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted),
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
                  const SizedBox(height: 20),
                  const RiskDisclaimerCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary)),
      ],
    );
  }
}
