import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _accountTitleCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  String _method = 'easypaisa';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountTitleCtrl.dispose();
    _accountNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(double available) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0 || amount > available) {
      setState(() => _error = 'Enter an amount up to your available balance.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(firebaseServiceProvider).requestWithdrawal(
            amount: amount,
            method: _method,
            accountTitle: _accountTitleCtrl.text.trim(),
            accountNumber: _accountNumberCtrl.text.trim(),
            bankName:
                _method == 'bank_transfer' ? _bankNameCtrl.text.trim() : null,
          );
      _amountCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted for admin approval.'),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(userWalletProvider).valueOrNull;
    final withdrawalsAsync = ref.watch(userWithdrawalsProvider);
    final available = wallet?.availableBalance ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Withdraw Money',
                subtitle:
                    'Available Balance: ${AppFormatters.pkr(available, showDecimals: true)}',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_error!,
                                style:
                                    const TextStyle(color: AppColors.dangerRed)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'easypaisa', label: Text('Easypaisa')),
                            ButtonSegment(
                                value: 'jazzcash', label: Text('JazzCash')),
                            ButtonSegment(
                                value: 'bank_transfer',
                                label: Text('Bank Transfer')),
                          ],
                          selected: {_method},
                          onSelectionChanged: (v) =>
                              setState(() => _method = v.first),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Withdrawal Amount (PKR)',
                          ),
                          validator: (v) {
                            final n = double.tryParse(v ?? '') ?? 0;
                            return n <= 0 ? 'Enter valid amount' : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_method == 'bank_transfer') ...[
                          TextFormField(
                            controller: _bankNameCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Bank Name'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter bank name'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _accountTitleCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Account Title'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter account title'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _accountNumberCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Account / Mobile Number / IBAN',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter account number'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed:
                              _submitting ? null : () => _submit(available),
                          child: Text(_submitting
                              ? 'Submitting...'
                              : 'Request Withdrawal'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Withdrawal History',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              withdrawalsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => ErrorStateView(message: e.toString()),
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No withdrawal requests submitted yet.'),
                      ),
                    );
                  }
                  return Column(
                    children: items
                        .map((w) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  title: Text(
                                      '${AppFormatters.pkr(w.amount)} via ${w.method.toUpperCase()}'),
                                  subtitle: Text(
                                      '${w.accountTitle} (${w.accountNumber}) • ${AppFormatters.date(w.createdAt)}'),
                                  trailing: StatusBadge(status: w.status),
                                ),
                              ),
                            ))
                        .toList(),
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
