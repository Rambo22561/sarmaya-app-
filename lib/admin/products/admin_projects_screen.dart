import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/community_models.dart';
import '../../models/project_model.dart';

class AdminProjectsScreen extends ConsumerWidget {
  const AdminProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final settingsAsync = ref.watch(paymentSettingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Projects, Products & Custom Packs',
            subtitle:
                'Create product projects, upload multiple product images, configure unlimited custom packs, and manage payment channels.',
            trailing: Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openPaymentSettingsDialog(
                    context,
                    ref,
                    settingsAsync.valueOrNull ?? const PaymentSettingsModel(),
                  ),
                  icon: const Icon(Icons.account_balance_outlined, size: 18),
                  label: const Text('Payment Accounts'),
                ),
                FilledButton.icon(
                  onPressed: () => _openProjectDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('New Project'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          projectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (projects) {
              if (projects.isEmpty) {
                return EmptyStateView(
                  icon: Icons.add_business_outlined,
                  title: 'No Projects Yet',
                  message:
                      'Create your first real-product project and add fixed-price packs.',
                  action: FilledButton(
                    onPressed: () => _openProjectDialog(context, ref),
                    child: const Text('Create Project'),
                  ),
                );
              }

              return Column(
                children: projects
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AdminProjectCard(project: p),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openProjectDialog(
    BuildContext context,
    WidgetRef ref, {
    ProjectModel? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final catCtrl =
        TextEditingController(text: existing?.category ?? 'Consumer Goods');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final costCtrl =
        TextEditingController(text: existing?.productCost.toString() ?? '');
    final sellCtrl = TextEditingController(
        text: existing?.expectedSellingPrice.toString() ?? '');
    final stockCtrl = TextEditingController(
        text: existing?.totalStockUnits.toString() ?? '100');
    final imageUrls = List<String>.from(existing?.imageUrls ?? const []);
    bool uploadingImage = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Create Project' : 'Edit Project'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Project / Product Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: catCtrl,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Product Unit Cost (PKR)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: sellCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Expected Selling Price'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Total Stock Units'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: uploadingImage
                            ? null
                            : () async {
                                final picker = ImagePicker();
                                final files = await picker.pickMultiImage();
                                if (files.isEmpty) return;
                                setModalState(() => uploadingImage = true);
                                final svc = ref.read(firebaseServiceProvider);
                                for (final f in files) {
                                  final bytes = await f.readAsBytes();
                                  final url = await svc.uploadBytes(
                                    bytes: bytes,
                                    folder: 'product_images',
                                    fileExtension: f.name
                                            .toLowerCase()
                                            .endsWith('.png')
                                        ? 'png'
                                        : 'jpg',
                                  );
                                  imageUrls.add(url);
                                }
                                setModalState(() => uploadingImage = false);
                              },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(uploadingImage
                            ? 'Uploading...'
                            : 'Upload Product Images (${imageUrls.length})'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final totalStock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                final project = ProjectModel(
                  id: existing?.id ?? '',
                  title: titleCtrl.text.trim(),
                  category: catCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  imageUrls: imageUrls,
                  status: existing?.status ?? 'active',
                  productCost: double.tryParse(costCtrl.text.trim()) ?? 0,
                  expectedSellingPrice:
                      double.tryParse(sellCtrl.text.trim()) ?? 0,
                  totalStockUnits: totalStock,
                  availableStockUnits: existing?.availableStockUnits ?? totalStock,
                  soldUnits: existing?.soldUnits ?? 0,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                await ref
                    .read(firebaseServiceProvider)
                    .saveProject(project, isNew: existing == null);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
              child: const Text('Save Project'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPaymentSettingsDialog(
    BuildContext context,
    WidgetRef ref,
    PaymentSettingsModel current,
  ) async {
    final epTitle = TextEditingController(text: current.easypaisaTitle);
    final epNum = TextEditingController(text: current.easypaisaNumber);
    final jcTitle = TextEditingController(text: current.jazzcashTitle);
    final jcNum = TextEditingController(text: current.jazzcashNumber);
    final bankName = TextEditingController(text: current.bankName);
    final bankTitle = TextEditingController(text: current.bankAccountTitle);
    final bankNum = TextEditingController(text: current.bankAccountNumber);
    final bankIban = TextEditingController(text: current.bankIban);
    final whatsapp = TextEditingController(text: current.adminWhatsappNumber);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Payment & WhatsApp Config'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: epTitle,
                    decoration:
                        const InputDecoration(labelText: 'Easypaisa Title')),
                const SizedBox(height: 8),
                TextField(
                    controller: epNum,
                    decoration:
                        const InputDecoration(labelText: 'Easypaisa Number')),
                const SizedBox(height: 8),
                TextField(
                    controller: jcTitle,
                    decoration:
                        const InputDecoration(labelText: 'JazzCash Title')),
                const SizedBox(height: 8),
                TextField(
                    controller: jcNum,
                    decoration:
                        const InputDecoration(labelText: 'JazzCash Number')),
                const SizedBox(height: 8),
                TextField(
                    controller: bankName,
                    decoration: const InputDecoration(labelText: 'Bank Name')),
                const SizedBox(height: 8),
                TextField(
                    controller: bankTitle,
                    decoration:
                        const InputDecoration(labelText: 'Bank Account Title')),
                const SizedBox(height: 8),
                TextField(
                    controller: bankNum,
                    decoration: const InputDecoration(
                        labelText: 'Bank Account Number')),
                const SizedBox(height: 8),
                TextField(
                    controller: bankIban,
                    decoration: const InputDecoration(labelText: 'Bank IBAN')),
                const SizedBox(height: 8),
                TextField(
                    controller: whatsapp,
                    decoration: const InputDecoration(
                        labelText: 'Admin WhatsApp Number')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(firebaseServiceProvider).updatePaymentSettings(
                    PaymentSettingsModel(
                      easypaisaTitle: epTitle.text.trim(),
                      easypaisaNumber: epNum.text.trim(),
                      jazzcashTitle: jcTitle.text.trim(),
                      jazzcashNumber: jcNum.text.trim(),
                      bankName: bankName.text.trim(),
                      bankAccountTitle: bankTitle.text.trim(),
                      bankAccountNumber: bankNum.text.trim(),
                      bankIban: bankIban.text.trim(),
                      adminWhatsappNumber: whatsapp.text.trim(),
                    ),
                  );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

class _AdminProjectCard extends ConsumerWidget {
  final ProjectModel project;

  const _AdminProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(projectPacksProvider(project.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        'Cost: ${AppFormatters.pkr(project.productCost)} • Expected Sell: ${AppFormatters.pkr(project.expectedSellingPrice)} • Stock: ${project.availableStockUnits}/${project.totalStockUnits}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: project.status),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Add Custom Pack',
                  icon: const Icon(Icons.add_box_outlined,
                      color: AppColors.emeraldDark),
                  onPressed: () => _openAddPackDialog(context, ref, project),
                ),
                IconButton(
                  tooltip: 'Archive Project',
                  icon: const Icon(Icons.archive_outlined,
                      color: AppColors.dangerRed),
                  onPressed: () => ref
                      .read(firebaseServiceProvider)
                      .archiveProject(project.id),
                ),
              ],
            ),
            const Divider(height: 20),
            packsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (packs) {
                if (packs.isEmpty) {
                  return const Text(
                    'No packs added yet. Click the + box icon to create unlimited custom packs (e.g. Rs. 140, Rs. 500, Rs. 1,000, Rs. 5,000).',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  );
                }
                return Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: packs
                      .map((pack) => Chip(
                            label: Text(
                              '${pack.name}: ${AppFormatters.pkr(pack.price)} (${pack.stockQuantity} left)',
                            ),
                            onDeleted: () => ref
                                .read(firebaseServiceProvider)
                                .deletePack(pack.id),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddPackDialog(
      BuildContext context, WidgetRef ref, ProjectModel project) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '100');
    final unitsCtrl = TextEditingController(text: '1');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Pack for ${project.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Pack Name (e.g. Pack A)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Pack Price (PKR)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Available Stock'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: unitsCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Product Units per Pack'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final pack = PackModel(
                id: '',
                projectId: project.id,
                productId: project.id,
                name: nameCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                stockQuantity: int.tryParse(stockCtrl.text.trim()) ?? 0,
                unitsPerPack: int.tryParse(unitsCtrl.text.trim()) ?? 1,
              );
              await ref
                  .read(firebaseServiceProvider)
                  .savePack(pack, isNew: true);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Create Pack'),
          ),
        ],
      ),
    );
  }
}
