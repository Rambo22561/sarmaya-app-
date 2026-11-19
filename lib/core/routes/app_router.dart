import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../admin/dashboard/admin_dashboard_screen.dart';
import '../../admin/inventory/admin_inventory_screen.dart';
import '../../admin/payments/admin_payments_screen.dart';
import '../../admin/products/admin_projects_screen.dart';
import '../../admin/reports/admin_reports_screen.dart';
import '../../admin/sales/admin_sales_screen.dart';
import '../../admin/subscriptions/admin_subscriptions_screen.dart';
import '../../admin/users/admin_users_screen.dart';
import '../../admin/withdrawals/admin_withdrawals_screen.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/authentication/register_screen.dart';
import '../../features/authentication/splash_screen.dart';
import '../../features/authentication/verify_email_screen.dart';
import '../../features/authentication/welcome_screen.dart';
import '../../features/dashboard/user_dashboard_screen.dart';
import '../../features/investment_packs/pack_selection_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/ownership/my_ownership_screen.dart';
import '../../features/ownership/my_products_screen.dart';
import '../../features/payments/payment_instructions_screen.dart';
import '../../features/payments/upload_payment_proof_screen.dart';
import '../../features/products/browse_projects_screen.dart';
import '../../features/products/project_details_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/referrals/referral_screen.dart';
import '../../features/sales/sales_history_screen.dart';
import '../../features/subscriptions/subscription_screen.dart';
import '../../features/wallet/transaction_history_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/withdrawals/withdraw_screen.dart';
import '../../models/project_model.dart';
import '../services/providers.dart';
import '../widgets/responsive_shell.dart';

const _userPrimaryNav = [
  NavDestinationItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    route: '/dashboard',
  ),
  NavDestinationItem(
    label: 'Projects',
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront,
    route: '/projects',
  ),
  NavDestinationItem(
    label: 'Ownership',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    route: '/my-ownership',
  ),
  NavDestinationItem(
    label: 'Wallet',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    route: '/wallet',
  ),
  NavDestinationItem(
    label: 'Subscription',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    route: '/subscription',
  ),
];

const _userSecondaryNav = [
  NavDestinationItem(
    label: 'My Products',
    icon: Icons.shopping_bag_outlined,
    activeIcon: Icons.shopping_bag,
    route: '/my-products',
  ),
  NavDestinationItem(
    label: 'Sales History',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale,
    route: '/sales-history',
  ),
  NavDestinationItem(
    label: 'Withdraw Money',
    icon: Icons.payments_outlined,
    activeIcon: Icons.payments,
    route: '/withdraw',
  ),
  NavDestinationItem(
    label: 'Transactions',
    icon: Icons.list_alt_outlined,
    activeIcon: Icons.list_alt,
    route: '/transactions',
  ),
  NavDestinationItem(
    label: 'Referrals',
    icon: Icons.group_outlined,
    activeIcon: Icons.group,
    route: '/referrals',
  ),
  NavDestinationItem(
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications,
    route: '/notifications',
  ),
  NavDestinationItem(
    label: 'Profile & Settings',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    route: '/profile',
  ),
];

const _adminPrimaryNav = [
  NavDestinationItem(
    label: 'Admin Overview',
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics,
    route: '/admin',
  ),
  NavDestinationItem(
    label: 'Projects & Packs',
    icon: Icons.add_business_outlined,
    activeIcon: Icons.add_business,
    route: '/admin/projects',
  ),
  NavDestinationItem(
    label: 'Payments',
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    route: '/admin/payments',
  ),
  NavDestinationItem(
    label: 'Sales & Profit',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale,
    route: '/admin/sales',
  ),
  NavDestinationItem(
    label: 'Expenses & Sub',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    route: '/admin/subscriptions',
  ),
];

const _adminSecondaryNav = [
  NavDestinationItem(
    label: 'Inventory & Buybacks',
    icon: Icons.swap_horiz_outlined,
    activeIcon: Icons.swap_horiz,
    route: '/admin/inventory',
  ),
  NavDestinationItem(
    label: 'Withdrawals',
    icon: Icons.payments_outlined,
    activeIcon: Icons.payments,
    route: '/admin/withdrawals',
  ),
  NavDestinationItem(
    label: 'Users & Referrals',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    route: '/admin/users',
  ),
  NavDestinationItem(
    label: 'Reports & Audit',
    icon: Icons.security_outlined,
    activeIcon: Icons.security,
    route: '/admin/reports',
  ),
  NavDestinationItem(
    label: 'Member View',
    icon: Icons.exit_to_app_outlined,
    activeIcon: Icons.exit_to_app,
    route: '/dashboard',
  ),
];

final appRouterProvider = Provider<GoRouter>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isPublic = loc == '/splash' ||
          loc == '/welcome' ||
          loc == '/login' ||
          loc == '/register';

      if (authUser == null && !isPublic) {
        return '/welcome';
      }

      if (loc.startsWith('/admin') && userProfile != null && !userProfile.isAdmin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterScreen(
          initialReferralCode: state.uri.queryParameters['ref'],
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) => const VerifyEmailScreen(),
      ),

      // User Authenticated Shell
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(
          currentLocation: state.matchedLocation,
          navItems: _userPrimaryNav,
          secondaryItems: _userSecondaryNav,
          headerTitle: _titleForRoute(state.matchedLocation),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
              icon: const Icon(Icons.notifications_outlined),
            ),
            IconButton(
              tooltip: 'Profile',
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.person_outline),
            ),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const UserDashboardScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (_, __) => const BrowseProjectsScreen(),
          ),
          GoRoute(
            path: '/projects/:projectId',
            builder: (_, state) => ProjectDetailsScreen(
              projectId: state.pathParameters['projectId']!,
            ),
          ),
          GoRoute(
            path: '/projects/:projectId/packs',
            builder: (_, state) => PackSelectionScreen(
              projectId: state.pathParameters['projectId']!,
            ),
          ),
          GoRoute(
            path: '/payment-instructions',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              if (extra == null) return const BrowseProjectsScreen();
              return PaymentInstructionsScreen(
                project: extra['project'] as ProjectModel,
                pack: extra['pack'] as PackModel,
                quantity: extra['quantity'] as int,
              );
            },
          ),
          GoRoute(
            path: '/upload-payment-proof',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              if (extra == null) return const BrowseProjectsScreen();
              return UploadPaymentProofScreen(
                project: extra['project'] as ProjectModel,
                pack: extra['pack'] as PackModel,
                quantity: extra['quantity'] as int,
                paymentMethod: extra['method'] as String,
                forwardedToWhatsapp:
                    (extra['forwardedWhatsapp'] as bool?) ?? false,
              );
            },
          ),
          GoRoute(
            path: '/my-products',
            builder: (_, __) => const MyProductsScreen(),
          ),
          GoRoute(
            path: '/my-ownership',
            builder: (_, __) => const MyOwnershipScreen(),
          ),
          GoRoute(
            path: '/sales-history',
            builder: (_, __) => const SalesHistoryScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (_, __) => const WalletScreen(),
          ),
          GoRoute(
            path: '/withdraw',
            builder: (_, __) => const WithdrawScreen(),
          ),
          GoRoute(
            path: '/subscription',
            builder: (_, __) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: '/referrals',
            builder: (_, __) => const ReferralScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (_, __) => const TransactionHistoryScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Admin Authenticated Shell
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(
          currentLocation: state.matchedLocation,
          navItems: _adminPrimaryNav,
          secondaryItems: _adminSecondaryNav,
          headerTitle: 'Admin Operations',
          isAdminShell: true,
          actions: [
            IconButton(
              tooltip: 'Switch to Member View',
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.storefront_outlined),
            ),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/projects',
            builder: (_, __) => const AdminProjectsScreen(),
          ),
          GoRoute(
            path: '/admin/payments',
            builder: (_, __) => const AdminPaymentsScreen(),
          ),
          GoRoute(
            path: '/admin/inventory',
            builder: (_, __) => const AdminInventoryScreen(),
          ),
          GoRoute(
            path: '/admin/sales',
            builder: (_, __) => const AdminSalesScreen(),
          ),
          GoRoute(
            path: '/admin/subscriptions',
            builder: (_, __) => const AdminSubscriptionsScreen(),
          ),
          GoRoute(
            path: '/admin/withdrawals',
            builder: (_, __) => const AdminWithdrawalsScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (_, __) => const AdminReportsScreen(),
          ),
        ],
      ),
    ],
  );
});

String _titleForRoute(String loc) {
  if (loc.startsWith('/projects')) return 'Product Marketplace';
  if (loc == '/my-products') return 'My Products';
  if (loc == '/my-ownership') return 'My Ownership';
  if (loc == '/sales-history') return 'Sales History';
  if (loc == '/wallet') return 'Wallet';
  if (loc == '/withdraw') return 'Withdraw Money';
  if (loc == '/subscription') return 'Monthly Subscription';
  if (loc == '/referrals') return 'Referrals';
  if (loc == '/transactions') return 'Transaction Ledger';
  if (loc == '/notifications') return 'Notifications';
  if (loc == '/profile') return 'Profile & Settings';
  return 'Dashboard';
}
