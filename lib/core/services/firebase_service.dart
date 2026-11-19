import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../../models/community_models.dart';
import '../../models/financial_models.dart';
import '../../models/ownership_model.dart';
import '../../models/payment_request_model.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Uuid _uuid = const Uuid();

  // ---------------- AUTHENTICATION ----------------

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection(AppConstants.usersCol).doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _db
        .collection(AppConstants.usersCol)
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists && snap.data() != null
            ? UserModel.fromMap(snap.data()!, snap.id)
            : null);
  }

  Future<void> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String city,
    String? referralCodeInput,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw Exception('Failed to create Firebase Auth account.');
    }

    await user.updateDisplayName(fullName.trim());
    await user.sendEmailVerification();

    final ownReferralCode =
        'SRM${user.uid.substring(0, 6).toUpperCase()}';

    final userDoc = UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      city: city.trim(),
      role: 'user',
      emailVerified: user.emailVerified,
      referralCode: ownReferralCode,
      referredByCode: referralCodeInput?.trim().toUpperCase(),
      isEligibleMember: false,
      subscriptionStatus: 'due',
      accountStatus: 'active',
      createdAt: DateTime.now(),
    );

    await _db
        .collection(AppConstants.usersCol)
        .doc(user.uid)
        .set(userDoc.toMap());

    // Initialize empty wallet via trusted Cloud Function or safe initial doc
    await _functions.httpsCallable('initializeNewUserAccount').call({
      'referralCodeInput': referralCodeInput?.trim().toUpperCase(),
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user != null) {
      await syncEmailVerificationStatus();
      await registerFcmToken();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> syncEmailVerificationStatus() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    final verified = refreshed?.emailVerified ?? false;
    await _db.collection(AppConstants.usersCol).doc(user.uid).set(
      {'emailVerified': verified},
      SetOptions(merge: true),
    );
    return verified;
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String city,
  }) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
    });
  }

  Future<void> registerFcmToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token != null) {
        await _db
            .collection(AppConstants.usersCol)
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    } catch (_) {
      // Safe fallback on web/emulators without push configuration
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------- STORAGE UPLOADS ----------------

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileExtension,
  }) async {
    final fileName = '${_uuid.v4()}.$fileExtension';
    final ref = _storage.ref().child('$folder/$fileName');
    final metadata = SettableMetadata(
      contentType: fileExtension == 'png' ? 'image/png' : 'image/jpeg',
    );
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  // ---------------- PROJECTS, PRODUCTS & PACKS ----------------

  Stream<List<ProjectModel>> watchProjects({bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.projectsCol)
        .orderBy('createdAt', descending: true);
    if (activeOnly) {
      query = query.where('status', isEqualTo: 'active');
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => ProjectModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<ProjectModel?> watchProjectById(String projectId) {
    return _db
        .collection(AppConstants.projectsCol)
        .doc(projectId)
        .snapshots()
        .map((d) =>
            d.exists && d.data() != null ? ProjectModel.fromMap(d.data()!, d.id) : null);
  }

  Stream<List<PackModel>> watchPacksForProject(String projectId) {
    return _db
        .collection(AppConstants.packsCol)
        .where('projectId', isEqualTo: projectId)
        .orderBy('price')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PackModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<PackModel>> watchAllPacks() {
    return _db.collection(AppConstants.packsCol).snapshots().map((snap) =>
        snap.docs.map((d) => PackModel.fromMap(d.data(), d.id)).toList());
  }

  Future<String> saveProject(ProjectModel project, {bool isNew = false}) async {
    if (isNew) {
      final ref = await _db
          .collection(AppConstants.projectsCol)
          .add(project.toMap());
      await _db.collection(AppConstants.productsCol).doc(ref.id).set({
        'projectId': ref.id,
        'name': project.title,
        'sku': 'SKU-${ref.id.substring(0, 6).toUpperCase()}',
        'unitLabel': 'Unit',
        'unitCost': project.productCost,
        'expectedUnitSellingPrice': project.expectedSellingPrice,
        'imageUrls': project.imageUrls,
      });
      await _db.collection(AppConstants.inventoryCol).doc(ref.id).set({
        'projectId': ref.id,
        'totalUnits': project.totalStockUnits,
        'availableUnits': project.availableStockUnits,
        'allocatedUnits': 0,
        'soldUnits': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } else {
      await _db
          .collection(AppConstants.projectsCol)
          .doc(project.id)
          .update(project.toMap());
      return project.id;
    }
  }

  Future<void> archiveProject(String projectId) async {
    await _db
        .collection(AppConstants.projectsCol)
        .doc(projectId)
        .update({'status': 'archived'});
  }

  Future<void> savePack(PackModel pack, {bool isNew = false}) async {
    if (isNew) {
      await _db.collection(AppConstants.packsCol).add(pack.toMap());
    } else {
      await _db
          .collection(AppConstants.packsCol)
          .doc(pack.id)
          .update(pack.toMap());
    }
  }

  Future<void> deletePack(String packId) async {
    await _db.collection(AppConstants.packsCol).doc(packId).delete();
  }

  // ---------------- PAYMENT SETTINGS & MANUAL PAYMENTS ----------------

  Stream<PaymentSettingsModel> watchPaymentSettings() {
    return _db
        .collection(AppConstants.appSettingsCol)
        .doc('payment_methods')
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? PaymentSettingsModel.fromMap(doc.data()!)
            : const PaymentSettingsModel());
  }

  Future<void> updatePaymentSettings(PaymentSettingsModel settings) async {
    await _db
        .collection(AppConstants.appSettingsCol)
        .doc('payment_methods')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  Future<void> submitManualPaymentRequest({
    required UserModel user,
    required ProjectModel project,
    required PackModel pack,
    required int quantity,
    required String paymentMethod,
    required String transactionReference,
    required String senderAccountNumber,
    required String proofImageUrl,
    required bool forwardedToWhatsapp,
  }) async {
    if (quantity < 1) {
      throw Exception('Minimum purchase is 1 pack.');
    }
    if (quantity > pack.stockQuantity) {
      throw Exception('Selected quantity exceeds available pack stock.');
    }
    final totalAmount = pack.price * quantity;
    final request = PaymentRequestModel(
      id: '',
      userId: user.uid,
      userEmail: user.email,
      userName: user.fullName,
      projectId: project.id,
      projectTitle: project.title,
      productId: pack.productId,
      packId: pack.id,
      packName: pack.name,
      quantity: quantity,
      unitPrice: pack.price,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference.trim(),
      senderAccountNumber: senderAccountNumber.trim(),
      proofImageUrl: proofImageUrl,
      forwardedToWhatsapp: forwardedToWhatsapp,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _db.collection(AppConstants.paymentRequestsCol).add(request.toMap());
  }

  Stream<List<PaymentRequestModel>> watchUserPaymentRequests(String uid) {
    return _db
        .collection(AppConstants.paymentRequestsCol)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PaymentRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<PaymentRequestModel>> watchAllPaymentRequests() {
    return _db
        .collection(AppConstants.paymentRequestsCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PaymentRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  // Trusted backend Cloud Functions for Payment Approval/Rejection
  Future<void> approvePaymentRequest({
    required String paymentRequestId,
    String? adminNote,
  }) async {
    await _functions.httpsCallable('approvePaymentRequest').call({
      'paymentRequestId': paymentRequestId,
      'adminNote': adminNote ?? '',
    });
  }

  Future<void> rejectPaymentRequest({
    required String paymentRequestId,
    required String reason,
  }) async {
    await _functions.httpsCallable('rejectPaymentRequest').call({
      'paymentRequestId': paymentRequestId,
      'reason': reason,
    });
  }

  // ---------------- OWNERSHIP, SALES, WALLET & LEDGER ----------------

  Stream<List<OwnershipRecordModel>> watchUserOwnership(String uid) {
    return _db
        .collection(AppConstants.ownershipRecordsCol)
        .where('userId', isEqualTo: uid)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OwnershipRecordModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<OwnershipRecordModel>> watchAllOwnership() {
    return _db
        .collection(AppConstants.ownershipRecordsCol)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OwnershipRecordModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<WalletModel> watchUserWallet(String uid) {
    return _db
        .collection(AppConstants.walletsCol)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? WalletModel.fromMap(doc.data()!, doc.id)
            : WalletModel(userId: uid));
  }

  Stream<List<LedgerEntryModel>> watchUserLedger(String uid) {
    return _db
        .collection(AppConstants.ledgerEntriesCol)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LedgerEntryModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<SaleRecordModel>> watchSales({String? projectId}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.salesCol)
        .orderBy('saleDate', descending: true);
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => SaleRecordModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> recordProductSale({
    required String projectId,
    required int unitsSold,
    required double grossRevenue,
    required double allocatedProductCost,
    required double eligibleExpenses,
    required String notes,
  }) async {
    await _functions.httpsCallable('recordProductSale').call({
      'projectId': projectId,
      'unitsSold': unitsSold,
      'grossRevenue': grossRevenue,
      'allocatedProductCost': allocatedProductCost,
      'eligibleExpenses': eligibleExpenses,
      'notes': notes,
    });
  }

  // ---------------- BUYBACK ----------------

  Stream<List<BuybackRequestModel>> watchUserBuybacks(String uid) {
    return _db
        .collection(AppConstants.buybackRequestsCol)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BuybackRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<BuybackRequestModel>> watchAllBuybacks() {
    return _db
        .collection(AppConstants.buybackRequestsCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BuybackRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> requestBuyback({required String ownershipId}) async {
    await _functions.httpsCallable('requestBuyback').call({
      'ownershipId': ownershipId,
    });
  }

  Future<void> adminReviewBuyback({
    required String buybackId,
    required bool approveOffer,
    required double confirmedBuybackPrice,
    String? adminNote,
  }) async {
    await _functions.httpsCallable('adminReviewBuyback').call({
      'buybackId': buybackId,
      'approveOffer': approveOffer,
      'confirmedBuybackPrice': confirmedBuybackPrice,
      'adminNote': adminNote ?? '',
    });
  }

  Future<void> userRespondBuyback({
    required String buybackId,
    required bool accept,
  }) async {
    await _functions.httpsCallable('userRespondBuyback').call({
      'buybackId': buybackId,
      'accept': accept,
    });
  }

  // ---------------- WITHDRAWALS ----------------

  Stream<List<WithdrawalRequestModel>> watchUserWithdrawals(String uid) {
    return _db
        .collection(AppConstants.withdrawalRequestsCol)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WithdrawalRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<WithdrawalRequestModel>> watchAllWithdrawals() {
    return _db
        .collection(AppConstants.withdrawalRequestsCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WithdrawalRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String method,
    required String accountTitle,
    required String accountNumber,
    String? bankName,
  }) async {
    await _functions.httpsCallable('requestWithdrawal').call({
      'amount': amount,
      'method': method,
      'accountTitle': accountTitle,
      'accountNumber': accountNumber,
      'bankName': bankName ?? '',
    });
  }

  Future<void> processWithdrawal({
    required String withdrawalId,
    required bool approve,
    String? adminNote,
  }) async {
    await _functions.httpsCallable('processWithdrawal').call({
      'withdrawalId': withdrawalId,
      'approve': approve,
      'adminNote': adminNote ?? '',
    });
  }

  // ---------------- SUBSCRIPTIONS & MONTHLY EXPENSE SHARING ----------------

  Stream<SubscriptionPeriodModel?> watchCurrentSubscriptionPeriod(
      String monthKey) {
    return _db
        .collection(AppConstants.subscriptionsCol)
        .doc(monthKey)
        .snapshots()
        .map((d) => d.exists && d.data() != null
            ? SubscriptionPeriodModel.fromMap(d.data()!, d.id)
            : null);
  }

  Stream<List<SubscriptionInvoiceModel>> watchUserSubscriptionInvoices(
      String uid) {
    return _db
        .collection(AppConstants.subscriptionInvoicesCol)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SubscriptionInvoiceModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> saveMonthlyExpensesAndRecalculate({
    required String monthKey,
    required Map<String, double> expenseBreakdown,
    required bool promoEnabled,
    required double promoAmount,
    DateTime? promoStartDate,
    DateTime? promoEndDate,
  }) async {
    await _functions.httpsCallable('recalculateMonthlySubscription').call({
      'monthKey': monthKey,
      'expenseBreakdown': expenseBreakdown,
      'promoEnabled': promoEnabled,
      'promoAmount': promoAmount,
      'promoStartIso': promoStartDate?.toIso8601String(),
      'promoEndIso': promoEndDate?.toIso8601String(),
    });
  }

  Future<void> paySubscriptionInvoice(String invoiceId) async {
    await _functions.httpsCallable('paySubscriptionInvoice').call({
      'invoiceId': invoiceId,
    });
  }

  // ---------------- REFERRALS, USERS, NOTIFICATIONS & AUDIT ----------------

  Stream<List<ReferralRelationshipModel>> watchUserReferrals(String uid) {
    return _db
        .collection(AppConstants.referralRelationshipsCol)
        .where('referrerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReferralRelationshipModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<ReferralRelationshipModel>> watchAllReferrals() {
    return _db
        .collection(AppConstants.referralRelationshipsCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReferralRelationshipModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<UserModel>> watchAllUsers() {
    return _db
        .collection(AppConstants.usersCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> toggleUserEligibility({
    required String userId,
    required bool isEligibleMember,
  }) async {
    await _functions.httpsCallable('updateMemberEligibility').call({
      'targetUserId': userId,
      'isEligibleMember': isEligibleMember,
    });
  }

  Stream<List<AppNotificationModel>> watchUserNotifications(String uid) {
    return _db
        .collection(AppConstants.notificationsCol)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotificationModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCol)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Stream<List<AuditLogModel>> watchAuditLogs() {
    return _db
        .collection(AppConstants.auditLogsCol)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AuditLogModel.fromMap(d.data(), d.id)).toList());
  }
}
