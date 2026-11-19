class AppConstants {
  static const String appName = 'Sarmaya Market';
  static const String appTagline = 'Real-Product Ownership & Shared Commerce';

  // Keep true during development/testing until legal & regulatory compliance
  // in Pakistan (e.g., SECP / SBP requirements) has been formally cleared.
  static const bool isDemoMode = true;

  static const String demoBannerText =
      'DEMO MODE: Educational & staging environment. Do not collect real public funds until legal and regulatory requirements in Pakistan are reviewed.';

  static const String riskDisclaimer =
      'Product ownership carries real commercial risk. Returns depend exclusively on actual product sales after documented expenses and a 10% platform commission on positive distributable profit. No fixed or guaranteed returns are promised.';

  static const String referralPolicyNotice =
      'Referrals do not pay cash bonuses, recruitment commissions, or multi-level rewards. New active eligible members simply share monthly operating expenses and reduce the per-member subscription fee for everyone.';

  // Financial Rules
  static const double platformProfitCommissionRate = 0.10; // 10%
  static const double defaultBuybackDeductionRate = 0.10; // 10%
  static const String currencySymbol = 'Rs.';

  // Firestore Collection Names
  static const String usersCol = 'users';
  static const String adminsCol = 'admins';
  static const String projectsCol = 'projects';
  static const String productsCol = 'products';
  static const String packsCol = 'packs';
  static const String paymentRequestsCol = 'payment_requests';
  static const String ownershipRecordsCol = 'ownership_records';
  static const String inventoryCol = 'inventory';
  static const String salesCol = 'sales';
  static const String expensesCol = 'expenses';
  static const String walletsCol = 'wallets';
  static const String ledgerEntriesCol = 'ledger_entries';
  static const String withdrawalRequestsCol = 'withdrawal_requests';
  static const String buybackRequestsCol = 'buyback_requests';
  static const String subscriptionsCol = 'subscriptions';
  static const String subscriptionInvoicesCol = 'subscription_invoices';
  static const String referralRelationshipsCol = 'referral_relationships';
  static const String notificationsCol = 'notifications';
  static const String auditLogsCol = 'audit_logs';
  static const String appSettingsCol = 'app_settings';
}
