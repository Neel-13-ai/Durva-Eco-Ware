class ProductionMaterialIssueDto {
  const ProductionMaterialIssueDto({
    required this.id,
    required this.productionOrderId,
    required this.productId,
    this.productName,
    this.productCode,
    this.unitName,
    required this.requiredQty,
    this.issuedQty = 0.0,
    this.unitCost = 0.0,
    this.batchNo,
    this.isActive = true,
  });

  final int id;
  final int productionOrderId;
  final int productId;
  final String? productName;
  final String? productCode;
  final String? unitName;
  final double requiredQty;
  final double issuedQty;
  final double unitCost;
  final String? batchNo;
  final bool isActive;

  bool get isFullyIssued => issuedQty >= requiredQty && requiredQty > 0;
  double get totalCost => issuedQty * unitCost;

  factory ProductionMaterialIssueDto.fromJson(Map<String, dynamic> json) {
    return ProductionMaterialIssueDto(
      id: json['id'] as int? ?? json['ProductionMaterialIssueId'] as int? ?? 0,
      productionOrderId: json['productionOrderId'] as int? ?? json['ProductionOrderId'] as int? ?? 0,
      productId: json['productId'] as int? ?? json['ProductId'] as int? ?? 0,
      productName: json['productName'] as String? ?? json['ProductName'] as String?,
      productCode: json['productCode'] as String? ?? json['ProductCode'] as String?,
      unitName: json['unitName'] as String? ?? json['UnitName'] as String?,
      requiredQty: (json['requiredQty'] as num? ?? json['RequiredQty'] as num? ?? 0.0).toDouble(),
      issuedQty: (json['issuedQty'] as num? ?? json['IssuedQty'] as num? ?? 0.0).toDouble(),
      unitCost: (json['unitCost'] as num? ?? json['UnitCost'] as num? ?? 0.0).toDouble(),
      batchNo: json['batchNo'] as String? ?? json['BatchNo'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productionOrderId': productionOrderId,
      'productId': productId,
      if (productName != null) 'productName': productName,
      if (productCode != null) 'productCode': productCode,
      if (unitName != null) 'unitName': unitName,
      'requiredQty': requiredQty,
      'issuedQty': issuedQty,
      'unitCost': unitCost,
      if (batchNo != null) 'batchNo': batchNo,
      'isActive': isActive,
    };
  }

  ProductionMaterialIssueDto copyWith({
    int? id,
    int? productionOrderId,
    int? productId,
    String? productName,
    String? productCode,
    String? unitName,
    double? requiredQty,
    double? issuedQty,
    double? unitCost,
    String? batchNo,
    bool? isActive,
  }) {
    return ProductionMaterialIssueDto(
      id: id ?? this.id,
      productionOrderId: productionOrderId ?? this.productionOrderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitName: unitName ?? this.unitName,
      requiredQty: requiredQty ?? this.requiredQty,
      issuedQty: issuedQty ?? this.issuedQty,
      unitCost: unitCost ?? this.unitCost,
      batchNo: batchNo ?? this.batchNo,
      isActive: isActive ?? this.isActive,
    );
  }
}
