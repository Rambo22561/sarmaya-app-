import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/project_model.dart';

class PaymentInstructionsScreen extends ConsumerStatefulWidget {
  final ProjectModel project;
  final PackModel pack;
  final int quantity;

  const PaymentInstructionsScreen({
    super.key,
    required this.project,
    required this.pack,
    required this.quantity,
  });

  @override
  ConsumerState<PaymentInstructionsScreen> createState() =>
      _PaymentInstructionsScreenState();
}

class _PaymentInstructionsScreenState
    extends ConsumerState<PaymentInstructionsScreen> {
  String _selectedMethod = 'easypaisa';
  bool _forwardedWhatsapp = false;

  Future<void> _forwardToWhatsapp(String whatsappNumber, double total) async {
    final cleanPhone = whatsappNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = Uri.encodeComponent(
      'Payment Notification:\nProject: ${widget.project.title}\nPack: ${widget.pack.name} x${widget.quantity}\nAmount: ${AppFormatters.pkr(total)}\nMethod: $_selectedMethod\nI am uploading my payment proof in the app.',
    );
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    setState(() => _forwardedWhatsapp = true);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(paymentSettingsProvider);
    final total = widget.pack.price * widget.quantity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () =>
                        context.go('/projects/${widget.project.id}/packs'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Manual Payment Instructions',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                color: AppColors.navyPrimary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.pack.name} × ${widget.quantity} pack(s)',
                            style: const TextStyle(color: Color(0xFFCBD5E1)),
                          ),
                        ],
                      ),
                      Text(
                        AppFormatters.pkr(total),
                        style: const TextStyle(
                          color: AppColors.emeraldAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              settingsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load payment settings: $e'),
                data: (settings) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('1. Choose Transfer Channel',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
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
                            selected: {_selectedMethod},
                            onSelectionChanged: (v) =>
                                setState(() => _selectedMethod = v.first),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedMethod == 'easypaisa')
                            _AccountBox(
                              title: 'Easypaisa Account',
                              accountTitle: settings.easypaisaTitle,
                              accountNumber: settings.easypaisaNumber,
                            ),
                          if (_selectedMethod == 'jazzcash')
                            _AccountBox(
                              title: 'JazzCash Account',
                              accountTitle: settings.jazzcashTitle,
                              accountNumber: settings.jazzcashNumber,
                            ),
                          if (_selectedMethod == 'bank_transfer')
                            _AccountBox(
                              title: settings.bankName,
                              accountTitle: settings.bankAccountTitle,
                              accountNumber: settings.bankAccountNumber,
                              extraLine: 'IBAN: ${settings.bankIban}',
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            'Important: Payments are NEVER auto-approved. After transferring, upload your screenshot and wait for manual admin verification.',
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _forwardToWhatsapp(
                                settings.adminWhatsappNumber, total),
                            icon: const Icon(Icons.chat_outlined),
                            label: Text(
                              'Forward Details to Admin WhatsApp (${settings.adminWhatsappNumber})',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              context.go(
                                '/upload-payment-proof',
                                extra: {
                                  'project': widget.project,
                                  'pack': widget.pack,
                                  'quantity': widget.quantity,
                                  'method': _selectedMethod,
                                  'forwardedWhatsapp': _forwardedWhatsapp,
                                },
                              );
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Payment Screenshot'),
                          ),
                        ],
                      ),
                    ),
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

class _AccountBox extends StatelessWidget {
  final String title;
  final String accountTitle;
  final String accountNumber;
  final String? extraLine;

  const _AccountBox({
    required this.title,
    required this.accountTitle,
    required this.accountNumber,
    this.extraLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.navyPrimary)),
          const SizedBox(height: 8),
          Text('Account Title: $accountTitle'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Account / Number: $accountNumber',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account number copied')),
                  );
                },
              ),
            ],
          ),
          if (extraLine != null) Text(extraLine!),
        ],
      ),
    );
  }
}
