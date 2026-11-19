import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class BrowseProjectsScreen extends ConsumerStatefulWidget {
  const BrowseProjectsScreen({super.key});

  @override
  ConsumerState<BrowseProjectsScreen> createState() =>
      _BrowseProjectsScreenState();
}

class _BrowseProjectsScreenState extends ConsumerState<BrowseProjectsScreen> {
  String _search = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(activeProjectsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Browse Product Projects',
            subtitle:
                'Purchase verified fixed-price product packs backed by physical inventory.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search products (e.g., Washing Powder, Rice...)',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Categories')),
                  DropdownMenuItem(
                      value: 'Consumer Goods', child: Text('Consumer Goods')),
                  DropdownMenuItem(value: 'FMCG', child: Text('FMCG')),
                  DropdownMenuItem(
                      value: 'Agriculture', child: Text('Agriculture')),
                  DropdownMenuItem(value: 'Apparel', child: Text('Apparel')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          projectsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ErrorStateView(message: err.toString()),
            data: (projects) {
              final filtered = projects.where((p) {
                final matchesSearch = _search.isEmpty ||
                    p.title.toLowerCase().contains(_search) ||
                    p.description.toLowerCase().contains(_search);
                final matchesCat =
                    _category == 'All' || p.category == _category;
                return matchesSearch && matchesCat;
              }).toList();

              if (filtered.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.storefront_outlined,
                  title: 'No Active Projects Found',
                  message:
                      'Admin has not published matching product projects yet.',
                );
              }

              final width = MediaQuery.of(context).size.width;
              final cols = width >= 1100
                  ? 3
                  : width >= 700
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: cols == 1 ? 1.35 : 0.92,
                ),
                itemBuilder: (context, index) {
                  final project = filtered[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.go('/projects/${project.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            width: double.infinity,
                            color: AppColors.navyPrimary.withValues(alpha: 0.08),
                            child: project.imageUrls.isNotEmpty
                                ? Image.network(
                                    project.imageUrls.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 48,
                                      color: AppColors.navyPrimary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: AppColors.navyPrimary,
                                  ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        project.category,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.emeraldDark,
                                        ),
                                      ),
                                      StatusBadge(status: project.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    project.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      project.description,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Unit Cost',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted)),
                                          Text(
                                            AppFormatters.pkr(
                                                project.productCost),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text('Stock Left',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted)),
                                          Text(
                                            '${project.availableStockUnits} / ${project.totalStockUnits}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.emeraldDark),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
