import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _ts(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();

class SubscriptionPeriodModel {
  final String id; // monthKey e.g. '2026-11'
  final String monthLabel;
  final double totalMonthlyExpenses;
  final Map<String, double> expenseBreakdown;
  final int eligibleActiveMembers;
  final double calculatedSharePerMember;
  final bool promoEnabled;
  final double promoAmount; // e.g. Rs. 1
  final DateTime? promoStartDate;
  final DateTime? promoEndDate;
  final double collectedTotal;
  final double surplusOrShortfall;
  final DateTime updatedAt;

  const SubscriptionPeriodModel({
    required this.id,
    required this.monthLabel,
    required this.totalMonthlyExpenses,
    this.expenseBreakdown = const {},
    required this.eligibleActiveMembers,
    required this.calculatedSharePerMember,
    this.promoEnabled = false,
    this.promoAmount = 1.0,
    this.promoStartDate,
    this.promoEndDate,
    this.collectedTotal = 0,
    this.surplusOrShortfall = 0,
    required this.updatedAt,
  });

  double get effectiveFee {
    final now = DateTime.now();
    if (promoEnabled &&
        promoStartDate != null &&
        promoEndDate != null &&
        now.isAfter(promoStartDate!) &&
        now.isBefore(promoEndDate!)) {
      return promoAmount;
    }
    return calculatedSharePerMember;
  }

  factory SubscriptionPeriodModel.fromMap(Map<String, dynamic> map, String id) {
    final rawBreakdown =
        Map<String, dynamic>.from(map['expenseBreakdown'] ?? const {});
    return SubscriptionPeriodModel(
      id: id,
      monthLabel: (map['monthLabel'] ?? id) as String,
      totalMonthlyExpenses:
          ((map['totalMonthlyExpenses'] ?? 0) as num).toDouble(),
      expenseBreakdown: rawBreakdown
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      eligibleActiveMembers:
          ((map['eligibleActiveMembers'] ?? 1) as num).toInt(),
      calculatedSharePerMember:
          ((map['calculatedSharePerMember'] ?? 0) as num).toDouble(),
      promoEnabled: (map['promoEnabled'] ?? false) as bool,
      promoAmount: ((map['promoAmount'] ?? 1.0) as num).toDouble(),
      promoStartDate:
          map['promoStartDate'] is Timestamp ? _ts(map['promoStartDate']) : null,
      promoEndDate:
          map['promoEndDate'] is Timestamp ? _ts(map['promoEndDate']) : null,
      collectedTotal: ((map['collectedTotal'] ?? 0) as num).toDouble(),
      surplusOrShortfall:
          ((map['surplusOrShortfall'] ?? 0) as num).toDouble(),
      updatedAt: _ts(map['updatedAt']),
    );
  }
}

class SubscriptionInvoiceModel {
  final String id;
  final String userId;
  final String monthKey;
  final double amountDue;
  final bool isPromoApplied;
  final String status; // 'due' | 'paid' | 'waived'
  final DateTime createdAt;
  final DateTime? paidAt;

  const SubscriptionInvoiceModel({
    required this.id,
    required this.userId,
    required this.monthKey,
    required this.amountDue,
    this.isPromoApplied = false,
    this.status = 'due',
    required this.createdAt,
    this.paidAt,
  });

  factory SubscriptionInvoiceModel.fromMap(
      Map<String, dynamic> map, String id) {
    return SubscriptionInvoiceModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      monthKey: (map['monthKey'] ?? '') as String,
      amountDue: ((map['amountDue'] ?? 0) as num).toDouble(),
      isPromoApplied: (map['isPromoApplied'] ?? false) as bool,
      status: (map['status'] ?? 'due') as String,
      createdAt: _ts(map['createdAt']),
      paidAt: map['paidAt'] is Timestamp ? _ts(map['paidAt']) : null,
    );
  }
}

class ReferralRelationshipModel {
  final String id;
  final String referrerId;
  final String referrerName;
  final String referredUserId;
  final String referredUserName;
  final String referredUserEmail;
  final bool isEligibleActive;
  final DateTime createdAt;

  const ReferralRelationshipModel({
    required this.id,
    required this.referrerId,
    required this.referrerName,
    required this.referredUserId,
    required this.referredUserName,
    required this.referredUserEmail,
    this.isEligibleActive = false,
    required this.createdAt,
  });

  factory ReferralRelationshipModel.fromMap(
      Map<String, dynamic> map, String id) {
    return ReferralRelationshipModel(
      id: id,
      referrerId: (map['referrerId'] ?? '') as String,
      referrerName: (map['referrerName'] ?? '') as String,
      referredUserId: (map['referredUserId'] ?? '') as String,
      referredUserName: (map['referredUserName'] ?? '') as String,
      referredUserEmail: (map['referredUserEmail'] ?? '') as String,
      isEligibleActive: (map['isEligibleActive'] ?? false) as bool,
      createdAt: _ts(map['createdAt']),
    );
  }
}

class AppNotificationModel {
  final String id;
  final String userId; // user UID or 'admin_broadcast'
  final String title;
  final String body;
  final String type; // 'project' | 'payment' | 'sale' | 'profit' | 'buyback' | 'subscription' | 'withdrawal'
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return AppNotificationModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      type: (map['type'] ?? 'general') as String,
      isRead: (map['isRead'] ?? false) as bool,
      createdAt: _ts(map['createdAt']),
    );
  }
}

class PaymentSettingsModel {
  final String easypaisaTitle;
  final String easypaisaNumber;
  final String jazzcashTitle;
  final String jazzcashNumber;
  final String bankName;
  final String bankAccountTitle;
  final String bankAccountNumber;
  final String bankIban;
  final String adminWhatsappNumber;

  const PaymentSettingsModel({
    this.easypaisaTitle = 'Sarmaya Commerce Pvt Ltd (Demo)',
    this.easypaisaNumber = '0300-0000000',
    this.jazzcashTitle = 'Sarmaya Commerce Pvt Ltd (Demo)',
    this.jazzcashNumber = '0301-0000000',
    this.bankName = 'Meezan Bank (Demo)',
    this.bankAccountTitle = 'Sarmaya Commerce Pvt Ltd',
    this.bankAccountNumber = '0101-0101010101',
    this.bankIban = 'PK00MEZN0001010101010101',
    this.adminWhatsappNumber = '+923000000000',
  });

  factory PaymentSettingsModel.fromMap(Map<String, dynamic> map) {
    return PaymentSettingsModel(
      easypaisaTitle:
          (map['easypaisaTitle'] ?? 'Sarmaya Commerce (Demo)') as String,
      easypaisaNumber: (map['easypaisaNumber'] ?? '0300-0000000') as String,
      jazzcashTitle:
          (map['jazzcashTitle'] ?? 'Sarmaya Commerce (Demo)') as String,
      jazzcashNumber: (map['jazzcashNumber'] ?? '0301-0000000') as String,
      bankName: (map['bankName'] ?? 'Meezan Bank (Demo)') as String,
      bankAccountTitle:
          (map['bankAccountTitle'] ?? 'Sarmaya Commerce Pvt Ltd') as String,
      bankAccountNumber:
          (map['bankAccountNumber'] ?? '0101-0101010101') as String,
      bankIban: (map['bankIban'] ?? 'PK00MEZN0001010101010101') as String,
      adminWhatsappNumber:
          (map['adminWhatsappNumber'] ?? '+923000000000') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'easypaisaTitle': easypaisaTitle,
      'easypaisaNumber': easypaisaNumber,
      'jazzcashTitle': jazzcashTitle,
      'jazzcashNumber': jazzcashNumber,
      'bankName': bankName,
      'bankAccountTitle': bankAccountTitle,
      'bankAccountNumber': bankAccountNumber,
      'bankIban': bankIban,
      'adminWhatsappNumber': adminWhatsappNumber,
    };
  }
}

class AuditLogModel {
  final String id;
  final String actorId;
  final String action;
  final String targetCollection;
  final String targetId;
  final String summary;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.actorId,
    required this.action,
    required this.targetCollection,
    required this.targetId,
    required this.summary,
    required this.createdAt,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      id: id,
      actorId: (map['actorId'] ?? '') as String,
      action: (map['action'] ?? '') as String,
      targetCollection: (map['targetCollection'] ?? '') as String,
      targetId: (map['targetId'] ?? '') as String,
      summary: (map['summary'] ?? '') as String,
      createdAt: _ts(map['createdAt']),
    );
  }
}
