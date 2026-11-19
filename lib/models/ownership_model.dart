import 'package:cloud_firestore/cloud_firestore.dart';

class OwnershipStatus {
  static const String pending = 'pending';
  static const String active = 'active';
  static const String partiallySold = 'partially_sold';
  static const String sold = 'sold';
  static const String buybackRequested = 'buyback_requested';
  static const String boughtBack = 'bought_back';
}

class OwnershipRecordModel {
  final String id;
  final String userId;
  final String projectId;
  final String projectTitle;
  final String productId;
  final String packId;
  final String packName;
  final String paymentRequestId;
  final int quantity;
  final int remainingQuantity;
  final double purchaseAmount;
  final double remainingCapital;
  final double realizedProfit;
  final double ownershipPercentage; // 0..100
  final DateTime purchaseDate;
  final String currentStatus;

  const OwnershipRecordModel({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.projectTitle,
    required this.productId,
    required this.packId,
    required this.packName,
    required this.paymentRequestId,
    required this.quantity,
    required this.remainingQuantity,
    required this.purchaseAmount,
    required this.remainingCapital,
    this.realizedProfit = 0,
    required this.ownershipPercentage,
    required this.purchaseDate,
    required this.currentStatus,
  });

  factory OwnershipRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return OwnershipRecordModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      projectId: (map['projectId'] ?? '') as String,
      projectTitle: (map['projectTitle'] ?? '') as String,
      productId: (map['productId'] ?? '') as String,
      packId: (map['packId'] ?? '') as String,
      packName: (map['packName'] ?? '') as String,
      paymentRequestId: (map['paymentRequestId'] ?? '') as String,
      quantity: ((map['quantity'] ?? 0) as num).toInt(),
      remainingQuantity: ((map['remainingQuantity'] ?? 0) as num).toInt(),
      purchaseAmount: ((map['purchaseAmount'] ?? 0) as num).toDouble(),
      remainingCapital: ((map['remainingCapital'] ?? 0) as num).toDouble(),
      realizedProfit: ((map['realizedProfit'] ?? 0) as num).toDouble(),
      ownershipPercentage:
          ((map['ownershipPercentage'] ?? 0) as num).toDouble(),
      purchaseDate: map['purchaseDate'] is Timestamp
          ? (map['purchaseDate'] as Timestamp).toDate()
          : DateTime.now(),
      currentStatus:
          (map['currentStatus'] ?? OwnershipStatus.active) as String,
    );
  }
}
