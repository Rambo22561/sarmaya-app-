import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class AdminSalesScreen extends ConsumerStatefulWidget {
  const AdminSalesScreen({super.key});

  @override
  ConsumerState<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends ConsumerState<AdminSalesScreen> {
  String? _selectedProjectId;
  final _unitsCtrl = TextEditingController();
  final _revenueCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _unitsCtrl.dispose();
    _revenueCtrl.dispose();
    _costCtrl.dispose();
    _expensesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _recordSale() async {
    if (_selectedProjectId == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(firebaseServiceProvider).recordProductSale(
            projectId: _selectedProjectId!,
            unitsSold: int.tryParse(_unitsCtrl.text.trim()) ?? 0,
            grossRevenue: double.tryParse(_revenueCtrl.text.trim()) ?? 0,
            allocatedProductCost: double.tryParse(_costCtrl.text.trim()) ?? 0,
            eligibleExpenses: double.tryParse(_expensesCtrl.text.trim()) ?? 0,
            notes: _notesCtrl.text.trim(),
          );
      _unitsCtrl.clear();
      _revenueCtrl.clear();
      _costCtrl.clear();
      _notesCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Sale recorded! Capital & proportional profit distributed via Cloud Function.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(allProjectsProvider).valueOrNull ?? const [];
    final salesAsync = ref.watch(allSalesProvider);

    final rev = double.tryParse(_revenueCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    final exp = double.tryParse(_expensesCtrl.text) ?? 0;
    final distProfit = rev - cost - exp;
    final comm = distProfit > 0 ? distProfit * 0.10 : 0.0;
    final investorPool = distProfit - comm;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Record Product Sales & Distribute Profit',
            subtitle:
                'Profit = Actual Sales − Allocated Cost − Eligible Expenses. 10% platform commission applies only to positive distributable profit.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedProjectId,
                    decoration:
                        const InputDecoration(labelText: 'Select Project'),
                    items: projects
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.title),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProjectId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _unitsCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration:
                              const InputDecoration(labelText: 'Units Sold'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _revenueCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Actual Gross Sales (PKR)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _costCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Allocated Product Cost (PKR)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _expensesCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Eligible Expenses (PKR)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Sale Notes'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Preview -> Distributable Profit: ${AppFormatters.pkr(distProfit)} | Platform Commission (10%): ${AppFormatters.pkr(comm)} | Investor Profit Pool: ${AppFormatters.pkr(investorPool)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitting ? null : _recordSale,
                    child: Text(_submitting
                        ? 'Processing Distribution...'
                        : 'Record Sale & Distribute Capital + Profit'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recorded Sales Batches',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          salesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (sales) => Column(
              children: sales
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            title: Text(
                                '${s.projectTitle} • ${s.unitsSold} units'),
                            subtitle: Text(
                              'Gross: ${AppFormatters.pkr(s.grossRevenue)} • Fee: ${AppFormatters.pkr(s.platformCommission)} • Investor Pool: ${AppFormatters.pkr(s.investorProfitPool)}',
                            ),
                            trailing: Text(AppFormatters.date(s.saleDate)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
