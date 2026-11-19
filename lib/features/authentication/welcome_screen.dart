import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DemoModeBanner(),
                  const SizedBox(height: 24),
                  Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: isWide ? 6 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: AppColors.navyPrimary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldAccent
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'REAL-PRODUCT OWNERSHIP MARKETPLACE',
                                  style: TextStyle(
                                    color: AppColors.emeraldAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Own Real Inventory Packs.\nTrack Real Sales.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  height: 1.18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Purchase fixed-price product packs, monitor verified inventory ownership, and receive your original capital plus proportional realized profit after actual product sales and documented expenses.',
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 15,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => context.go('/register'),
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('Create Member Account'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Color(0xFF475569)),
                                    ),
                                    onPressed: () => context.go('/login'),
                                    icon: const Icon(Icons.login),
                                    label: const Text('Sign In'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 24 : 0,
                        height: isWide ? 0 : 24,
                      ),
                      Expanded(
                        flex: isWide ? 4 : 0,
                        child: Column(
                          children: [
                            _FeatureTile(
                              icon: Icons.inventory_2_outlined,
                              title: 'Transparent Pack Ownership',
                              desc:
                                  'Select custom product packs starting from 1 pack, backed by admin-verified receipts and unique ownership records.',
                            ),
                            const SizedBox(height: 14),
                            _FeatureTile(
                              icon: Icons.receipt_long_outlined,
                              title: 'Actual Sales Accounting',
                              desc:
                                  'Profits are calculated strictly from completed sales minus product cost, eligible expenses, and 10% platform commission.',
                            ),
                            const SizedBox(height: 14),
                            _FeatureTile(
                              icon: Icons.groups_outlined,
                              title: 'Shared Monthly Operating Costs',
                              desc:
                                  'Company expenses are split transparently among eligible active members—no MLM or cash referral bonuses.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const RiskDisclaimerCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emeraldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.emeraldDark, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(desc, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
