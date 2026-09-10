enum DisposalMethod {
  recycled,
  repulped,
  discarded,
  soldAsScrap;

  static DisposalMethod fromString(String? val) {
    if (val == null) return DisposalMethod.recycled;
    switch (val.toUpperCase()) {
      case 'REPULPED':
        return DisposalMethod.repulped;
      case 'DISCARDED':
        return DisposalMethod.discarded;
      case 'SOLD_AS_SCRAP':
      case 'SOLDASSCRAP':
      case 'SCRAP_SALE':
        return DisposalMethod.soldAsScrap;
      case 'RECYCLED':
      default:
        return DisposalMethod.recycled;
    }
  }

  String toApiValue() {
    switch (this) {
      case DisposalMethod.recycled:
        return 'RECYCLED';
      case DisposalMethod.repulped:
        return 'REPULPED';
      case DisposalMethod.discarded:
        return 'DISCARDED';
      case DisposalMethod.soldAsScrap:
        return 'SOLD_AS_SCRAP';
    }
  }
}

class WasteEntryDto {
  const WasteEntryDto({
    required this.id,
    required this.wasteNumber,
    required this.wasteDate,
    required this.warehouseId,
    this.warehouseName,
    required this.productId,
    this.productName,
    this.productCode,
    this.unitName,
    required this.wasteReasonId,
    this.wasteReasonName,
    required this.quantity,
    this.unitCost = 0.0,
    this.productionOrderId,
    this.batchNo,
    this.disposalMethod = DisposalMethod.recycled,
    this.notes,
    this.createdBy,
    this.isActive = true,
  });

  final int id;
  final String wasteNumber;
  final DateTime wasteDate;
  final int warehouseId;
  final String? warehouseName;
  final int productId;
  final String? productName;
  final String? productCode;
  final String? unitName;
  final int wasteReasonId;
  final String? wasteReasonName;
  final double quantity;
  final double unitCost;
  final int? productionOrderId;
  final String? batchNo;
  final DisposalMethod disposalMethod;
  final String? notes;
  final String? createdBy;
  final bool isActive;

  /// Total financial loss amount from this waste/scrap record
  double get totalLossAmount => quantity * unitCost;

  /// Whether this scrap was recovered or repulped back into production
  bool get isRecovered => disposalMethod == DisposalMethod.recycled || disposalMethod == DisposalMethod.repulped;

  factory WasteEntryDto.fromJson(Map<String, dynamic> json) {
    return WasteEntryDto(
      id: json['id'] as int? ?? json['WasteEntryId'] as int? ?? 0,
      wasteNumber: json['wasteNumber'] as String? ?? json['WasteNumber'] as String? ?? '',
      wasteDate: json['wasteDate'] != null
          ? DateTime.parse(json['wasteDate'].toString())
          : (json['WasteDate'] != null
              ? DateTime.parse(json['WasteDate'].toString())
              : DateTime.now()),
      warehouseId: json['warehouseId'] as int? ?? json['WarehouseId'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String? ?? json['WarehouseName'] as String?,
      productId: json['productId'] as int? ?? json['ProductId'] as int? ?? 0,
      productName: json['productName'] as String? ?? json['ProductName'] as String?,
      productCode: json['productCode'] as String? ?? json['ProductCode'] as String?,
      unitName: json['unitName'] as String? ?? json['UnitName'] as String?,
      wasteReasonId: json['wasteReasonId'] as int? ?? json['WasteReasonId'] as int? ?? 0,
      wasteReasonName: json['wasteReasonName'] as String? ?? json['WasteReasonName'] as String?,
      quantity: (json['quantity'] as num? ?? json['Quantity'] as num? ?? 0.0).toDouble(),
      unitCost: (json['unitCost'] as num? ?? json['UnitCost'] as num? ?? 0.0).toDouble(),
      productionOrderId: json['productionOrderId'] as int? ?? json['ProductionOrderId'] as int?,
      batchNo: json['batchNo'] as String? ?? json['BatchNo'] as String?,
      disposalMethod: DisposalMethod.fromString(
        json['disposalMethod'] as String? ?? json['DisposalMethod'] as String?,
      ),
      notes: json['notes'] as String? ?? json['Notes'] as String?,
      createdBy: json['createdBy'] as String? ?? json['CreatedBy'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wasteNumber': wasteNumber,
      'wasteDate': wasteDate.toIso8601String(),
      'warehouseId': warehouseId,
      if (warehouseName != null) 'warehouseName': warehouseName,
      'productId': productId,
      if (productName != null) 'productName': productName,
      if (productCode != null) 'productCode': productCode,
      if (unitName != null) 'unitName': unitName,
      'wasteReasonId': wasteReasonId,
      if (wasteReasonName != null) 'wasteReasonName': wasteReasonName,
      'quantity': quantity,
      'unitCost': unitCost,
      if (productionOrderId != null) 'productionOrderId': productionOrderId,
      if (batchNo != null) 'batchNo': batchNo,
      'disposalMethod': disposalMethod.toApiValue(),
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'createdBy': createdBy,
      'isActive': isActive,
    };
  }
}
