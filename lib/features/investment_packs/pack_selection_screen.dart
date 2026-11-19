import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/project_model.dart';

class PackSelectionScreen extends ConsumerStatefulWidget {
  final String projectId;

  const PackSelectionScreen({super.key, required this.projectId});

  @override
  ConsumerState<PackSelectionScreen> createState() =>
      _PackSelectionScreenState();
}

class _PackSelectionScreenState extends ConsumerState<PackSelectionScreen> {
  PackModel? _selectedPack;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));
    final packsAsync = ref.watch(projectPacksProvider(widget.projectId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () =>
                        context.go('/projects/${widget.projectId}'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Ownership Pack',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              projectAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => ErrorStateView(message: e.toString()),
                data: (project) {
                  if (project == null) {
                    return const Text('Project not found.');
                  }
                  return packsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => ErrorStateView(message: e.toString()),
                    data: (packs) {
                      final activePacks =
                          packs.where((p) => p.isActive && p.stockQuantity > 0).toList();
                      if (activePacks.isEmpty) {
                        return const EmptyStateView(
                          icon: Icons.inventory_outlined,
                          title: 'Out of Stock',
                          message:
                              'All packs for this project are currently out of stock.',
                        );
                      }

                      final selected = _selectedPack ?? activePacks.first;
                      final total = selected.price * _quantity;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...activePacks.map((pack) {
                            final isSelected = pack.id == selected.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.emeraldAccent
                                        : AppColors.borderLight,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: RadioListTile<String>(
                                  value: pack.id,
                                  groupValue: selected.id,
                                  onChanged: (_) {
                                    setState(() {
                                      _selectedPack = pack;
                                      _quantity = 1;
                                    });
                                  },
                                  title: Text(
                                    '${pack.name} — ${AppFormatters.pkr(pack.price)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    'Available: ${pack.stockQuantity} packs • ${pack.unitsPerPack} product unit(s) per pack',
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Pack Quantity (Min: 1, No Cap)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Row(
                                        children: [
                                          IconButton.outlined(
                                            onPressed: _quantity > 1
                                                ? () => setState(
                                                    () => _quantity--)
                                                : null,
                                            icon: const Icon(Icons.remove),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: Text(
                                              '$_quantity',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          IconButton.outlined(
                                            onPressed: _quantity <
                                                    selected.stockQuantity
                                                ? () => setState(
                                                    () => _quantity++)
                                                : null,
                                            icon: const Icon(Icons.add),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 28),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Payable Amount',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        AppFormatters.pkr(total),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.emeraldDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  FilledButton.icon(
                                    onPressed: () {
                                      context.go(
                                        '/payment-instructions',
                                        extra: {
                                          'project': project,
                                          'pack': selected,
                                          'quantity': _quantity,
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.payment),
                                    label: const Text(
                                        'Proceed to Payment Instructions'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
