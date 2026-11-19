import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/community_models.dart';
import '../../models/financial_models.dart';
import '../../models/ownership_model.dart';
import '../../models/payment_request_model.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import 'firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges();
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value(null);
  return ref.watch(firebaseServiceProvider).watchUserProfile(authUser.uid);
});

final activeProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchProjects(activeOnly: true);
});

final allProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchProjects(activeOnly: false);
});

final projectByIdProvider =
    StreamProvider.family<ProjectModel?, String>((ref, projectId) {
  return ref.watch(firebaseServiceProvider).watchProjectById(projectId);
});

final projectPacksProvider =
    StreamProvider.family<List<PackModel>, String>((ref, projectId) {
  return ref.watch(firebaseServiceProvider).watchPacksForProject(projectId);
});

final paymentSettingsProvider = StreamProvider<PaymentSettingsModel>((ref) {
  return ref.watch(firebaseServiceProvider).watchPaymentSettings();
});

final userPaymentRequestsProvider =
    StreamProvider<List<PaymentRequestModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firebaseServiceProvider).watchUserPaymentRequests(uid);
});

final allPaymentRequestsProvider =
    StreamProvider<List<PaymentRequestModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAllPaymentRequests();
});

final userOwnershipProvider =
    StreamProvider<List<OwnershipRecordModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firebaseServiceProvider).watchUserOwnership(uid);
});

final allOwnershipProvider =
    StreamProvider<List<OwnershipRecordModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAllOwnership();
});

final userWalletProvider = StreamProvider<WalletModel>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const WalletModel(userId: ''));
  return ref.watch(firebaseServiceProvider).watchUserWallet(uid);
});

final userLedgerProvider = StreamProvider<List<LedgerEntryModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firebaseServiceProvider).watchUserLedger(uid);
});

final allSalesProvider = StreamProvider<List<SaleRecordModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchSales();
});

final userBuybacksProvider = StreamProvider<List<BuybackRequestModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firebaseServiceProvider).watchUserBuybacks(uid);
});

final allBuybacksProvider = StreamProvider<List<BuybackRequestModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAllBuybacks();
});

final userWithdrawalsProvider =
    StreamProvider<List<WithdrawalRequestModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firebaseServiceProvider).watchUserWithdrawals(uid);
});

final allWithdrawalsProvider =
    StreamProvider<List<WithdrawalRequestModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAllWithdrawals();
});

final currentMonthKeyProvider = Provider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

final currentSubscriptionPeriodProvider =
    StreamProvider<SubscriptionPeriodModel?>((ref) {
  final monthKey = ref.watch(currentMonthKeyProvider);
  return ref
      .watch(firebaseServiceProvider)
      .watchCurrentSubscriptionPeriod(monthKey);
});

final userSubscriptionInvoicesProvider =
    StreamProvider<List<SubscriptionInvoiceModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firebaseServiceProvider).watchUserSubscriptionInvoices(uid);
});

final userReferralsProvider =
    StreamProvider<List<ReferralRelationshipModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firebaseServiceProvider).watchUserReferrals(uid);
});

final allReferralsProvider =
    StreamProvider<List<ReferralRelationshipModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAllReferrals();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAllUsers();
});

final userNotificationsProvider =
    StreamProvider<List<AppNotificationModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firebaseServiceProvider).watchUserNotifications(uid);
});

final auditLogsProvider = StreamProvider<List<AuditLogModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAuditLogs();
});
