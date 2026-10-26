import '../../../../core/utils/json_reader.dart';

enum StockTransactionType {
  inward,
  outward,
  transfer,
  adjustment;

  static StockTransactionType fromString(dynamic val) {
    if (val == null) return StockTransactionType.inward;
    if (val is int) {
      if (val >= 0 && val < StockTransactionType.values.length) {
        return StockTransactionType.values[val];
      }
      return StockTransactionType.inward;
    }
    final s = val.toString().toLowerCase();
    switch (s) {
      case '0':
      case 'in':
      case 'inward':
        return StockTransactionType.inward;
      case '1':
      case 'out':
      case 'outward':
        return StockTransactionType.outward;
      case '2':
      case 'transfer':
        return StockTransactionType.transfer;
      case '3':
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
    final reader = JsonReader(json);

    String? prodName = reader.getOptionalString('productName', aliases: ['ProductName']);
    String? prodCode = reader.getOptionalString('productCode', aliases: ['ProductCode']);
    if (prodName == null) {
      final pMap = reader.getMap('product', aliases: ['Product']);
      if (pMap != null) {
        prodName = pMap['name']?.toString() ?? pMap['productName']?.toString();
        prodCode ??= pMap['code']?.toString() ?? pMap['productCode']?.toString();
      }
    }

    String? whName = reader.getOptionalString('warehouseName', aliases: ['WarehouseName']);
    if (whName == null) {
      final wMap = reader.getMap('warehouse', aliases: ['Warehouse']);
      if (wMap != null) {
        whName = wMap['name']?.toString() ?? wMap['warehouseName']?.toString();
      }
    }

    return StockTransactionDto(
      id: reader.getInt('id', aliases: ['stockTransactionId', 'StockTransactionId', 'Id']),
      productId: reader.getInt('productId', aliases: ['ProductId']),
      productName: prodName,
      productCode: prodCode,
      warehouseId: reader.getInt('warehouseId', aliases: ['WarehouseId']),
      warehouseName: whName,
      transactionType: StockTransactionType.fromString(
        reader.getString('transactionType', aliases: ['TransactionType']),
      ),
      quantityIn: reader.getDouble('quantityIn', aliases: ['QuantityIn']),
      quantityOut: reader.getDouble('quantityOut', aliases: ['QuantityOut']),
      unitCost: reader.getDouble('unitCost', aliases: ['UnitCost', 'cost', 'Cost']),
      batchNo: reader.getOptionalString('batchNo', aliases: ['BatchNo']),
      referenceType: reader.getOptionalString('referenceType', aliases: ['ReferenceType']),
      referenceId: reader.getOptionalInt('referenceId', aliases: ['ReferenceId']),
      transactionDate: reader.getDateTime('transactionDate', aliases: ['TransactionDate', 'date', 'Date']) ?? DateTime.now(),
      userId: reader.getOptionalInt('userId', aliases: ['UserId']),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
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
