import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialReferralCode;

  const RegisterScreen({super.key, this.initialReferralCode});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final TextEditingController _referralCtrl;
  bool _acceptedTerms = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _referralCtrl =
        TextEditingController(text: widget.initialReferralCode ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _passwordCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _error =
          'Please acknowledge the real-product commercial risk disclaimer.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(firebaseServiceProvider).registerUser(
            fullName: _nameCtrl.text,
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            phone: _phoneCtrl.text,
            city: _cityCtrl.text,
            referralCodeInput: _referralCtrl.text.trim().isEmpty
                ? null
                : _referralCtrl.text.trim(),
          );
      if (!mounted) return;
      context.go('/verify-email');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DemoModeBanner(),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Join ${AppConstants.appName}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Register to browse product packs and participate in shared monthly operating costs.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.dangerRed,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.trim().length < 3
                                ? 'Enter your full name'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) =>
                                v == null || !v.contains('@')
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Mobile Number',
                                    hintText: '0300-1234567',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().length < 10
                                          ? 'Enter valid phone'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cityCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                    hintText: 'Lahore',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Enter city'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Minimum 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _referralCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Referral Code (Optional)',
                              prefixIcon: Icon(Icons.group_add_outlined),
                              helperText:
                                  'No cash bonus—referrals help lower everyone\'s monthly expense share.',
                            ),
                          ),
                          const SizedBox(height: 14),
                          CheckboxListTile(
                            value: _acceptedTerms,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (v) =>
                                setState(() => _acceptedTerms = v ?? false),
                            title: const Text(
                              'I understand returns depend solely on actual product sales after expenses and 10% platform commission on positive profit, with no guaranteed returns.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Create Account'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Sign In'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
