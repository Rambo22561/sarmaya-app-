import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    final verified =
        await ref.read(firebaseServiceProvider).syncEmailVerificationStatus();
    if (!mounted) return;
    setState(() => _checking = false);
    if (verified) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Email not verified yet. Please click the verification link in your inbox.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).valueOrNull?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.emeraldSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: AppColors.emeraldDark,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Check Your Inbox',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a verification link to $email. Verify your email before submitting payments or withdrawals.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _checking ? null : _checkNow,
                        child: Text(
                            _checking ? 'Checking...' : 'I Verified My Email'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(firebaseServiceProvider)
                            .sendEmailVerification();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Verification email resent.')),
                        );
                      },
                      child: const Text('Resend Verification Email'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Continue in Demo Preview'),
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
