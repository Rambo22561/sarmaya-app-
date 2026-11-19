import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/project_model.dart';

class UploadPaymentProofScreen extends ConsumerStatefulWidget {
  final ProjectModel project;
  final PackModel pack;
  final int quantity;
  final String paymentMethod;
  final bool forwardedToWhatsapp;

  const UploadPaymentProofScreen({
    super.key,
    required this.project,
    required this.pack,
    required this.quantity,
    required this.paymentMethod,
    this.forwardedToWhatsapp = false,
  });

  @override
  ConsumerState<UploadPaymentProofScreen> createState() =>
      _UploadPaymentProofScreenState();
}

class _UploadPaymentProofScreenState
    extends ConsumerState<UploadPaymentProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _txnCtrl = TextEditingController();
  final _senderAccountCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String _fileExt = 'jpg';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _txnCtrl.dispose();
    _senderAccountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    setState(() {
      _imageBytes = bytes;
      _fileExt = ext;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      setState(() => _error = 'Please upload your payment receipt screenshot.');
      return;
    }

    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) {
      setState(() => _error = 'User profile not loaded. Please sign in again.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final svc = ref.read(firebaseServiceProvider);
      final imageUrl = await svc.uploadBytes(
        bytes: _imageBytes!,
        folder: 'payment_proofs/${user.uid}',
        fileExtension: _fileExt,
      );

      await svc.submitManualPaymentRequest(
        user: user,
        project: widget.project,
        pack: widget.pack,
        quantity: widget.quantity,
        paymentMethod: widget.paymentMethod,
        transactionReference: _txnCtrl.text,
        senderAccountNumber: _senderAccountCtrl.text,
        proofImageUrl: imageUrl,
        forwardedToWhatsapp: widget.forwardedToWhatsapp,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Payment proof submitted. Status is PENDING manual admin verification.'),
        ),
      );
      context.go('/my-ownership');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.pack.price * widget.quantity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Upload Payment Proof',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.project.title} • ${widget.pack.name} × ${widget.quantity} = ${AppFormatters.pkr(total)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.emeraldDark),
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.dangerRed)),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _txnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Transaction ID / Reference Number',
                        hintText: 'e.g. TID-839201948',
                      ),
                      validator: (v) => v == null || v.trim().length < 4
                          ? 'Enter transaction ID'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _senderAccountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sender Account / Mobile Number',
                        hintText: '03XX-XXXXXXX',
                      ),
                      validator: (v) => v == null || v.trim().length < 5
                          ? 'Enter sender account number'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: _pickScreenshot,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.borderLight, width: 1.5),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(_imageBytes!,
                                    fit: BoxFit.contain),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined,
                                      size: 40, color: AppColors.navyPrimary),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to Select Payment Screenshot',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'PNG or JPG receipt image',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting
                          ? 'Uploading & Submitting...'
                          : 'Submit for Admin Verification'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
