import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _ts(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();

class SaleRecordModel {
  final String id;
  final String projectId;
  final String projectTitle;
  final int unitsSold;
  final double grossRevenue;
  final double allocatedProductCost;
  final double eligibleExpenses;
  final double distributableProfit;
  final double platformCommission; // 10% of positive distributable profit
  final double investorProfitPool;
  final double capitalReturned;
  final String notes;
  final String recordedBy;
  final DateTime saleDate;

  const SaleRecordModel({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.unitsSold,
    required this.grossRevenue,
    required this.allocatedProductCost,
    required this.eligibleExpenses,
    required this.distributableProfit,
    required this.platformCommission,
    required this.investorProfitPool,
    required this.capitalReturned,
    this.notes = '',
    required this.recordedBy,
    required this.saleDate,
  });

  factory SaleRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return SaleRecordModel(
      id: id,
      projectId: (map['projectId'] ?? '') as String,
      projectTitle: (map['projectTitle'] ?? '') as String,
      unitsSold: ((map['unitsSold'] ?? 0) as num).toInt(),
      grossRevenue: ((map['grossRevenue'] ?? 0) as num).toDouble(),
      allocatedProductCost:
          ((map['allocatedProductCost'] ?? 0) as num).toDouble(),
      eligibleExpenses: ((map['eligibleExpenses'] ?? 0) as num).toDouble(),
      distributableProfit:
          ((map['distributableProfit'] ?? 0) as num).toDouble(),
      platformCommission:
          ((map['platformCommission'] ?? 0) as num).toDouble(),
      investorProfitPool:
          ((map['investorProfitPool'] ?? 0) as num).toDouble(),
      capitalReturned: ((map['capitalReturned'] ?? 0) as num).toDouble(),
      notes: (map['notes'] ?? '') as String,
      recordedBy: (map['recordedBy'] ?? '') as String,
      saleDate: _ts(map['saleDate']),
    );
  }
}

class ExpenseRecordModel {
  final String id;
  final String? projectId;
  final String category; // 'office_rent', 'electricity', 'petrol', 'transport', 'salaries', 'packaging', 'marketing', 'other'
  final String description;
  final double amount;
  final String scope; // 'project' | 'monthly_shared'
  final String? monthKey; // e.g. '2026-11'
  final DateTime createdAt;

  const ExpenseRecordModel({
    required this.id,
    this.projectId,
    required this.category,
    required this.description,
    required this.amount,
    required this.scope,
    this.monthKey,
    required this.createdAt,
  });

  factory ExpenseRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseRecordModel(
      id: id,
      projectId: map['projectId'] as String?,
      category: (map['category'] ?? 'other') as String,
      description: (map['description'] ?? '') as String,
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      scope: (map['scope'] ?? 'monthly_shared') as String,
      monthKey: map['monthKey'] as String?,
      createdAt: _ts(map['createdAt']),
    );
  }
}

class WalletModel {
  final String userId;
  final double availableBalance;
  final double pendingBalance;
  final double investedCapital;
  final double realizedProfit;
  final double buybackProceeds;
  final double totalWithdrawn;

  const WalletModel({
    required this.userId,
    this.availableBalance = 0,
    this.pendingBalance = 0,
    this.investedCapital = 0,
    this.realizedProfit = 0,
    this.buybackProceeds = 0,
    this.totalWithdrawn = 0,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletModel(
      userId: id,
      availableBalance: ((map['availableBalance'] ?? 0) as num).toDouble(),
      pendingBalance: ((map['pendingBalance'] ?? 0) as num).toDouble(),
      investedCapital: ((map['investedCapital'] ?? 0) as num).toDouble(),
      realizedProfit: ((map['realizedProfit'] ?? 0) as num).toDouble(),
      buybackProceeds: ((map['buybackProceeds'] ?? 0) as num).toDouble(),
      totalWithdrawn: ((map['totalWithdrawn'] ?? 0) as num).toDouble(),
    );
  }
}

class LedgerEntryModel {
  final String id;
  final String transactionGroupId;
  final String accountType; // 'user_available' | 'user_pending' | 'user_capital' | 'platform_commission' | 'platform_cash'
  final String userId;
  final String entryType; // 'credit' | 'debit'
  final String category; // 'pack_purchase', 'capital_return', 'profit_distribution', 'platform_commission', 'buyback', 'withdrawal', 'subscription'
  final double amount;
  final double balanceAfter;
  final String description;
  final DateTime createdAt;

  const LedgerEntryModel({
    required this.id,
    required this.transactionGroupId,
    required this.accountType,
    required this.userId,
    required this.entryType,
    required this.category,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  factory LedgerEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return LedgerEntryModel(
      id: id,
      transactionGroupId: (map['transactionGroupId'] ?? '') as String,
      accountType: (map['accountType'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      entryType: (map['entryType'] ?? 'credit') as String,
      category: (map['category'] ?? '') as String,
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      balanceAfter: ((map['balanceAfter'] ?? 0) as num).toDouble(),
      description: (map['description'] ?? '') as String,
      createdAt: _ts(map['createdAt']),
    );
  }
}

class WithdrawalRequestModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String method; // 'easypaisa' | 'jazzcash' | 'bank_transfer'
  final String accountTitle;
  final String accountNumber;
  final String? bankName;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  const WithdrawalRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.method,
    required this.accountTitle,
    required this.accountNumber,
    this.bankName,
    this.status = 'pending',
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  factory WithdrawalRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return WithdrawalRequestModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      method: (map['method'] ?? 'easypaisa') as String,
      accountTitle: (map['accountTitle'] ?? '') as String,
      accountNumber: (map['accountNumber'] ?? '') as String,
      bankName: map['bankName'] as String?,
      status: (map['status'] ?? 'pending') as String,
      adminNote: map['adminNote'] as String?,
      createdAt: _ts(map['createdAt']),
      processedAt:
          map['processedAt'] is Timestamp ? _ts(map['processedAt']) : null,
    );
  }
}

class BuybackRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String ownershipId;
  final String projectId;
  final String projectTitle;
  final String packName;
  final double originalAmount;
  final double proposedBuybackPrice;
  final double deductionAmount; // e.g. 10%
  final double netPayoutAmount;
  final String status; // 'pending_admin' | 'awaiting_user_acceptance' | 'completed' | 'rejected' | 'cancelled_by_user'
  final String? adminNote;
  final DateTime createdAt;

  const BuybackRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.ownershipId,
    required this.projectId,
    required this.projectTitle,
    required this.packName,
    required this.originalAmount,
    required this.proposedBuybackPrice,
    required this.deductionAmount,
    required this.netPayoutAmount,
    this.status = 'pending_admin',
    this.adminNote,
    required this.createdAt,
  });

  factory BuybackRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return BuybackRequestModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      ownershipId: (map['ownershipId'] ?? '') as String,
      projectId: (map['projectId'] ?? '') as String,
      projectTitle: (map['projectTitle'] ?? '') as String,
      packName: (map['packName'] ?? '') as String,
      originalAmount: ((map['originalAmount'] ?? 0) as num).toDouble(),
      proposedBuybackPrice:
          ((map['proposedBuybackPrice'] ?? 0) as num).toDouble(),
      deductionAmount: ((map['deductionAmount'] ?? 0) as num).toDouble(),
      netPayoutAmount: ((map['netPayoutAmount'] ?? 0) as num).toDouble(),
      status: (map['status'] ?? 'pending_admin') as String,
      adminNote: map['adminNote'] as String?,
      createdAt: _ts(map['createdAt']),
    );
  }
}
