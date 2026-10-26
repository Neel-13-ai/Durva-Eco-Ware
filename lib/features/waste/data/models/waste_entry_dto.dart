enum DisposalMethod {
  recycled,
  repulped,
  discarded,
  soldAsScrap;

  static DisposalMethod fromString(dynamic val) {
    if (val == null) return DisposalMethod.recycled;
    if (val is int) {
      if (val >= 0 && val < DisposalMethod.values.length) {
        return DisposalMethod.values[val];
      }
      return DisposalMethod.recycled;
    }
    final s = val.toString().toUpperCase();
    switch (s) {
      case '0':
      case 'RECYCLED':
        return DisposalMethod.recycled;
      case '1':
      case 'REPULPED':
        return DisposalMethod.repulped;
      case '2':
      case 'DISCARDED':
        return DisposalMethod.discarded;
      case '3':
      case 'SOLD_AS_SCRAP':
      case 'SOLDASSCRAP':
      case 'SCRAP_SALE':
        return DisposalMethod.soldAsScrap;
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
      id: json['id'] as int? ?? json['WasteEntryId'] as int? ?? json['wasteEntryId'] as int? ?? 0,
      wasteNumber: json['wasteNumber']?.toString() ?? json['WasteNumber']?.toString() ?? '',
      wasteDate: json['wasteDate'] != null
          ? DateTime.parse(json['wasteDate'].toString())
          : (json['WasteDate'] != null
              ? DateTime.parse(json['WasteDate'].toString())
              : DateTime.now()),
      warehouseId: json['warehouseId'] as int? ?? json['WarehouseId'] as int? ?? 0,
      warehouseName: json['warehouseName']?.toString() ?? json['WarehouseName']?.toString(),
      productId: json['productId'] as int? ?? json['ProductId'] as int? ?? 0,
      productName: json['productName']?.toString() ?? json['ProductName']?.toString(),
      productCode: json['productCode']?.toString() ?? json['ProductCode']?.toString(),
      unitName: json['unitName']?.toString() ?? json['UnitName']?.toString(),
      wasteReasonId: json['wasteReasonId'] as int? ?? json['WasteReasonId'] as int? ?? 0,
      wasteReasonName: json['wasteReasonName']?.toString() ?? json['WasteReasonName']?.toString(),
      quantity: (json['quantity'] as num? ?? json['Quantity'] as num? ?? 0.0).toDouble(),
      unitCost: (json['unitCost'] as num? ?? json['UnitCost'] as num? ?? 0.0).toDouble(),
      productionOrderId: json['productionOrderId'] as int? ?? json['ProductionOrderId'] as int?,
      batchNo: json['batchNo']?.toString() ?? json['BatchNo']?.toString(),
      disposalMethod: DisposalMethod.fromString(
        json['disposalMethod'] ?? json['DisposalMethod'],
      ),
      notes: json['notes']?.toString() ?? json['Notes']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['CreatedBy']?.toString(),
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  WasteEntryDto copyWith({
    int? id,
    String? wasteNumber,
    DateTime? wasteDate,
    int? warehouseId,
    String? warehouseName,
    int? productId,
    String? productName,
    String? productCode,
    String? unitName,
    int? wasteReasonId,
    String? wasteReasonName,
    double? quantity,
    double? unitCost,
    int? productionOrderId,
    String? batchNo,
    DisposalMethod? disposalMethod,
    String? notes,
    String? createdBy,
    bool? isActive,
    double? totalLossAmount,
  }) {
    return WasteEntryDto(
      id: id ?? this.id,
      wasteNumber: wasteNumber ?? this.wasteNumber,
      wasteDate: wasteDate ?? this.wasteDate,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitName: unitName ?? this.unitName,
      wasteReasonId: wasteReasonId ?? this.wasteReasonId,
      wasteReasonName: wasteReasonName ?? this.wasteReasonName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      productionOrderId: productionOrderId ?? this.productionOrderId,
      batchNo: batchNo ?? this.batchNo,
      disposalMethod: disposalMethod ?? this.disposalMethod,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      if (wasteNumber.isNotEmpty && !wasteNumber.startsWith('AUTO')) 'wasteNumber': wasteNumber,
      'wasteDate': wasteDate.toIso8601String(),
      'warehouseId': warehouseId,
      'productId': productId,
      'wasteReasonId': wasteReasonId,
      'quantity': quantity,
      'unitCost': unitCost,
      if (productionOrderId != null && productionOrderId! > 0) 'productionOrderId': productionOrderId,
      if (batchNo != null && batchNo!.isNotEmpty) 'batchNo': batchNo,
      'disposalMethod': disposalMethod.toApiValue(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdBy': int.tryParse(createdBy ?? '') ?? 1,
    };
  }
}
