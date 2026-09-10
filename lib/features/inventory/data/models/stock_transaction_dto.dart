enum StockTransactionType {
  inward,
  outward,
  transfer,
  adjustment;

  static StockTransactionType fromString(String? val) {
    if (val == null) return StockTransactionType.inward;
    switch (val.toLowerCase()) {
      case 'in':
      case 'inward':
        return StockTransactionType.inward;
      case 'out':
      case 'outward':
        return StockTransactionType.outward;
      case 'transfer':
        return StockTransactionType.transfer;
      case 'adjustment':
        return StockTransactionType.adjustment;
      default:
        return StockTransactionType.inward;
    }
  }

  String toApiValue() {
    switch (this) {
      case StockTransactionType.inward:
        return 'IN';
      case StockTransactionType.outward:
        return 'OUT';
      case StockTransactionType.transfer:
        return 'TRANSFER';
      case StockTransactionType.adjustment:
        return 'ADJUSTMENT';
    }
  }
}

class StockTransactionDto {
  const StockTransactionDto({
    required this.id,
    required this.productId,
    this.productName,
    this.productCode,
    required this.warehouseId,
    this.warehouseName,
    required this.transactionType,
    this.quantityIn = 0.0,
    this.quantityOut = 0.0,
    this.unitCost = 0.0,
    this.batchNo,
    this.referenceType,
    this.referenceId,
    required this.transactionDate,
    this.userId,
    this.notes,
    this.isActive = true,
  });

  final int id;
  final int productId;
  final String? productName;
  final String? productCode;
  final int warehouseId;
  final String? warehouseName;
  final StockTransactionType transactionType;
  final double quantityIn;
  final double quantityOut;
  final double unitCost;
  final String? batchNo;
  final String? referenceType;
  final int? referenceId;
  final DateTime transactionDate;
  final int? userId;
  final String? notes;
  final bool isActive;

  double get netQuantity => quantityIn - quantityOut;
  double get totalCost => (quantityIn > 0 ? quantityIn : quantityOut) * unitCost;

  factory StockTransactionDto.fromJson(Map<String, dynamic> json) {
    return StockTransactionDto(
      id: json['id'] as int? ?? json['StockTransactionId'] as int? ?? 0,
      productId: json['productId'] as int? ?? json['ProductId'] as int? ?? 0,
      productName: json['productName'] as String? ?? json['ProductName'] as String?,
      productCode: json['productCode'] as String? ?? json['ProductCode'] as String?,
      warehouseId: json['warehouseId'] as int? ?? json['WarehouseId'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String? ?? json['WarehouseName'] as String?,
      transactionType: StockTransactionType.fromString(
        json['transactionType'] as String? ?? json['TransactionType'] as String?,
      ),
      quantityIn: (json['quantityIn'] as num? ?? json['QuantityIn'] as num? ?? 0.0).toDouble(),
      quantityOut: (json['quantityOut'] as num? ?? json['QuantityOut'] as num? ?? 0.0).toDouble(),
      unitCost: (json['unitCost'] as num? ?? json['UnitCost'] as num? ?? 0.0).toDouble(),
      batchNo: json['batchNo'] as String? ?? json['BatchNo'] as String?,
      referenceType: json['referenceType'] as String? ?? json['ReferenceType'] as String?,
      referenceId: json['referenceId'] as int? ?? json['ReferenceId'] as int?,
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'].toString())
          : (json['TransactionDate'] != null
              ? DateTime.parse(json['TransactionDate'].toString())
              : DateTime.now()),
      userId: json['userId'] as int? ?? json['UserId'] as int?,
      notes: json['notes'] as String? ?? json['Notes'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      if (productName != null) 'productName': productName,
      if (productCode != null) 'productCode': productCode,
      'warehouseId': warehouseId,
      if (warehouseName != null) 'warehouseName': warehouseName,
      'transactionType': transactionType.toApiValue(),
      'quantityIn': quantityIn,
      'quantityOut': quantityOut,
      'unitCost': unitCost,
      if (batchNo != null) 'batchNo': batchNo,
      if (referenceType != null) 'referenceType': referenceType,
      if (referenceId != null) 'referenceId': referenceId,
      'transactionDate': transactionDate.toIso8601String(),
      if (userId != null) 'userId': userId,
      if (notes != null) 'notes': notes,
      'isActive': isActive,
    };
  }
}
