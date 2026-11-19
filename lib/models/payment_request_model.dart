import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRequestModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String projectId;
  final String projectTitle;
  final String productId;
  final String packId;
  final String packName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String paymentMethod; // 'easypaisa' | 'jazzcash' | 'bank_transfer'
  final String transactionReference;
  final String senderAccountNumber;
  final String proofImageUrl;
  final bool forwardedToWhatsapp;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? adminNote;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const PaymentRequestModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.projectId,
    required this.projectTitle,
    required this.productId,
    required this.packId,
    required this.packName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.paymentMethod,
    required this.transactionReference,
    this.senderAccountNumber = '',
    required this.proofImageUrl,
    this.forwardedToWhatsapp = false,
    this.status = 'pending',
    this.adminNote,
    this.reviewedBy,
    required this.createdAt,
    this.reviewedAt,
  });

  factory PaymentRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentRequestModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      userEmail: (map['userEmail'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      projectId: (map['projectId'] ?? '') as String,
      projectTitle: (map['projectTitle'] ?? '') as String,
      productId: (map['productId'] ?? '') as String,
      packId: (map['packId'] ?? '') as String,
      packName: (map['packName'] ?? '') as String,
      quantity: ((map['quantity'] ?? 1) as num).toInt(),
      unitPrice: ((map['unitPrice'] ?? 0) as num).toDouble(),
      totalAmount: ((map['totalAmount'] ?? 0) as num).toDouble(),
      paymentMethod: (map['paymentMethod'] ?? 'easypaisa') as String,
      transactionReference: (map['transactionReference'] ?? '') as String,
      senderAccountNumber: (map['senderAccountNumber'] ?? '') as String,
      proofImageUrl: (map['proofImageUrl'] ?? '') as String,
      forwardedToWhatsapp: (map['forwardedToWhatsapp'] ?? false) as bool,
      status: (map['status'] ?? 'pending') as String,
      adminNote: map['adminNote'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      reviewedAt: map['reviewedAt'] is Timestamp
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'projectId': projectId,
      'projectTitle': projectTitle,
      'productId': productId,
      'packId': packId,
      'packName': packName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'transactionReference': transactionReference,
      'senderAccountNumber': senderAccountNumber,
      'proofImageUrl': proofImageUrl,
      'forwardedToWhatsapp': forwardedToWhatsapp,
      'status': status,
      'adminNote': adminNote,
      'reviewedBy': reviewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}
