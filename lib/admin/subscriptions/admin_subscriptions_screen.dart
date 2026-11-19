import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState
    extends ConsumerState<AdminSubscriptionsScreen> {
  final _rentCtrl = TextEditingController(text: '35000');
  final _elecCtrl = TextEditingController(text: '12000');
  final _petrolCtrl = TextEditingController(text: '8000');
  final _transportCtrl = TextEditingController(text: '10000');
  final _salariesCtrl = TextEditingController(text: '25000');
  final _packagingCtrl = TextEditingController(text: '6000');
  final _otherCtrl = TextEditingController(text: '4000');
  final _promoAmtCtrl = TextEditingController(text: '1');
  bool _promoEnabled = false;
  DateTime _promoStart = DateTime.now();
  DateTime _promoEnd = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _rentCtrl.dispose();
    _elecCtrl.dispose();
    _petrolCtrl.dispose();
    _transportCtrl.dispose();
    _salariesCtrl.dispose();
    _packagingCtrl.dispose();
    _otherCtrl.dispose();
    _promoAmtCtrl.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final monthKey = ref.watch(currentMonthKeyProvider);
    final periodAsync = ref.watch(currentSubscriptionPeriodProvider);
    final users = ref.watch(allUsersProvider).valueOrNull ?? const [];
    final eligibleCount =
        users.where((u) => u.isEligibleMember).length.clamp(1, 9999999);

    final totalExp = _val(_rentCtrl) +
        _val(_elecCtrl) +
        _val(_petrolCtrl) +
        _val(_transportCtrl) +
        _val(_salariesCtrl) +
        _val(_packagingCtrl) +
        _val(_otherCtrl);
    final perMember = totalExp / eligibleCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Monthly Expense Sharing & Subscriptions',
            subtitle:
                'Formula: Total Monthly Expenses ÷ Eligible Active Paying Members ($eligibleCount eligible currently)',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Month: $monthKey',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _numField(_rentCtrl, 'Office Rent (PKR)'),
                      _numField(_elecCtrl, 'Electricity (PKR)'),
                      _numField(_petrolCtrl, 'Petrol (PKR)'),
                      _numField(_transportCtrl, 'Transportation (PKR)'),
                      _numField(_salariesCtrl, 'Salaries (PKR)'),
                      _numField(_packagingCtrl, 'Packaging (PKR)'),
                      _numField(_otherCtrl, 'Other Expenses (PKR)'),
                    ],
                  ),
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _promoEnabled,
                    onChanged: (v) => setState(() => _promoEnabled = v),
                    title: const Text('Enable Promotional Subscription Period'),
                    subtitle: const Text(
                        'e.g. Promotional Rs. 1 subscription between start and end date.'),
                  ),
                  if (_promoEnabled) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _promoAmtCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Promo Amount (PKR)'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                              initialDateRange: DateTimeRange(
                                  start: _promoStart, end: _promoEnd),
                            );
                            if (picked != null) {
                              setState(() {
                                _promoStart = picked.start;
                                _promoEnd = picked.end;
                              });
                            }
                          },
                          child: Text(
                              '${AppFormatters.date(_promoStart)} – ${AppFormatters.date(_promoEnd)}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSoft.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total Expenses: ${AppFormatters.pkr(totalExp)} ÷ $eligibleCount Eligible Members = ${AppFormatters.pkr(perMember, showDecimals: true)} / member',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await ref
                                  .read(firebaseServiceProvider)
                                  .saveMonthlyExpensesAndRecalculate(
                                    monthKey: monthKey,
                                    expenseBreakdown: {
                                      'office_rent': _val(_rentCtrl),
                                      'electricity': _val(_elecCtrl),
                                      'petrol': _val(_petrolCtrl),
                                      'transportation': _val(_transportCtrl),
                                      'salaries': _val(_salariesCtrl),
                                      'packaging': _val(_packagingCtrl),
                                      'other': _val(_otherCtrl),
                                    },
                                    promoEnabled: _promoEnabled,
                                    promoAmount: _val(_promoAmtCtrl),
                                    promoStartDate: _promoStart,
                                    promoEndDate: _promoEnd,
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Monthly expenses saved & member invoices recalculated.'),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: Text(_saving
                        ? 'Recalculating & Generating Invoices...'
                        : 'Save Expenses & Generate Monthly Invoices'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          periodAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (period) {
              if (period == null) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  title: Text('Published Statement: ${period.monthLabel}'),
                  subtitle: Text(
                    'Collected: ${AppFormatters.pkr(period.collectedTotal)} | Surplus/Shortfall: ${AppFormatters.pkr(period.surplusOrShortfall)}',
                  ),
                  trailing: Text(
                    AppFormatters.pkr(period.effectiveFee, showDecimals: true),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldDark),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return SizedBox(
      width: 210,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
