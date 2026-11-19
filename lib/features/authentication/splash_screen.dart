import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), _routeNext);
  }

  void _routeNext() {
    if (!mounted) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth == null) {
      context.go('/welcome');
      return;
    }
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile?.isAdmin == true) {
      context.go('/admin');
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.emeraldAccent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.account_balance,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              AppConstants.appTagline,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: AppColors.emeraldAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
