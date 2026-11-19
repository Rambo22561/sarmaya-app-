import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String role; // 'user' | 'admin'
  final bool emailVerified;
  final String referralCode;
  final String? referredByUserId;
  final String? referredByCode;
  final bool isEligibleMember;
  final String subscriptionStatus; // 'active' | 'due' | 'promo_active' | 'inactive'
  final String accountStatus; // 'active' | 'suspended'
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.city = '',
    this.role = 'user',
    this.emailVerified = false,
    required this.referralCode,
    this.referredByUserId,
    this.referredByCode,
    this.isEligibleMember = false,
    this.subscriptionStatus = 'due',
    this.accountStatus = 'active',
    this.fcmToken,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      fullName: (map['fullName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      role: (map['role'] ?? 'user') as String,
      emailVerified: (map['emailVerified'] ?? false) as bool,
      referralCode: (map['referralCode'] ?? '') as String,
      referredByUserId: map['referredByUserId'] as String?,
      referredByCode: map['referredByCode'] as String?,
      isEligibleMember: (map['isEligibleMember'] ?? false) as bool,
      subscriptionStatus: (map['subscriptionStatus'] ?? 'due') as String,
      accountStatus: (map['accountStatus'] ?? 'active') as String,
      fcmToken: map['fcmToken'] as String?,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'city': city,
      'role': role,
      'emailVerified': emailVerified,
      'referralCode': referralCode,
      'referredByUserId': referredByUserId,
      'referredByCode': referredByCode,
      'isEligibleMember': isEligibleMember,
      'subscriptionStatus': subscriptionStatus,
      'accountStatus': accountStatus,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
