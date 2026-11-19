import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class ProjectModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> imageUrls;
  final String status; // 'active' | 'paused' | 'archived'
  final double productCost;
  final double expectedSellingPrice;
  final int totalStockUnits;
  final int availableStockUnits;
  final int soldUnits;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.imageUrls = const [],
    this.status = 'active',
    required this.productCost,
    required this.expectedSellingPrice,
    required this.totalStockUnits,
    required this.availableStockUnits,
    this.soldUnits = 0,
    required this.createdAt,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectModel(
      id: id,
      title: (map['title'] ?? '') as String,
      category: (map['category'] ?? 'Consumer Goods') as String,
      description: (map['description'] ?? '') as String,
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      status: (map['status'] ?? 'active') as String,
      productCost: ((map['productCost'] ?? 0) as num).toDouble(),
      expectedSellingPrice:
          ((map['expectedSellingPrice'] ?? 0) as num).toDouble(),
      totalStockUnits: ((map['totalStockUnits'] ?? 0) as num).toInt(),
      availableStockUnits: ((map['availableStockUnits'] ?? 0) as num).toInt(),
      soldUnits: ((map['soldUnits'] ?? 0) as num).toInt(),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'productCost': productCost,
      'expectedSellingPrice': expectedSellingPrice,
      'totalStockUnits': totalStockUnits,
      'availableStockUnits': availableStockUnits,
      'soldUnits': soldUnits,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ProductModel {
  final String id;
  final String projectId;
  final String name;
  final String sku;
  final String unitLabel; // e.g. "1kg Bag", "Carton"
  final double unitCost;
  final double expectedUnitSellingPrice;
  final List<String> imageUrls;

  const ProductModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.sku,
    this.unitLabel = 'Unit',
    required this.unitCost,
    required this.expectedUnitSellingPrice,
    this.imageUrls = const [],
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      projectId: (map['projectId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      sku: (map['sku'] ?? '') as String,
      unitLabel: (map['unitLabel'] ?? 'Unit') as String,
      unitCost: ((map['unitCost'] ?? 0) as num).toDouble(),
      expectedUnitSellingPrice:
          ((map['expectedUnitSellingPrice'] ?? 0) as num).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'name': name,
      'sku': sku,
      'unitLabel': unitLabel,
      'unitCost': unitCost,
      'expectedUnitSellingPrice': expectedUnitSellingPrice,
      'imageUrls': imageUrls,
    };
  }
}

class PackModel {
  final String id;
  final String projectId;
  final String productId;
  final String name; // e.g. Pack A, Pack B
  final double price; // e.g. 140, 500, 1000, 5000
  final int stockQuantity;
  final int unitsPerPack;
  final bool isActive;

  const PackModel({
    required this.id,
    required this.projectId,
    required this.productId,
    required this.name,
    required this.price,
    required this.stockQuantity,
    this.unitsPerPack = 1,
    this.isActive = true,
  });

  factory PackModel.fromMap(Map<String, dynamic> map, String id) {
    return PackModel(
      id: id,
      projectId: (map['projectId'] ?? '') as String,
      productId: (map['productId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      price: ((map['price'] ?? 0) as num).toDouble(),
      stockQuantity: ((map['stockQuantity'] ?? 0) as num).toInt(),
      unitsPerPack: ((map['unitsPerPack'] ?? 1) as num).toInt(),
      isActive: (map['isActive'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'productId': productId,
      'name': name,
      'price': price,
      'stockQuantity': stockQuantity,
      'unitsPerPack': unitsPerPack,
      'isActive': isActive,
    };
  }
}
