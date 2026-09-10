class ProductionOutputDto {
  const ProductionOutputDto({
    required this.id,
    required this.productionOrderId,
    required this.productId,
    this.productName,
    this.productCode,
    required this.producedQty,
    required this.goodQty,
    this.rejectQty = 0.0,
    required this.batchNo,
    this.unitCost = 0.0,
    required this.outputDate,
    this.isActive = true,
  });

  final int id;
  final int productionOrderId;
  final int productId;
  final String? productName;
  final String? productCode;
  final double producedQty;
  final double goodQty;
  final double rejectQty;
  final String batchNo;
  final double unitCost;
  final DateTime outputDate;
  final bool isActive;

  /// Business Rule Check: ProducedQty == GoodQty + RejectQty
  bool get isBalanced => (goodQty + rejectQty) == producedQty;

  /// Scrap rate percentage on this production run output
  double get rejectRatePercent => producedQty > 0 ? (rejectQty / producedQty) * 100.0 : 0.0;

  factory ProductionOutputDto.fromJson(Map<String, dynamic> json) {
    return ProductionOutputDto(
      id: json['id'] as int? ?? json['ProductionOutputId'] as int? ?? 0,
      productionOrderId: json['productionOrderId'] as int? ?? json['ProductionOrderId'] as int? ?? 0,
      productId: json['productId'] as int? ?? json['ProductId'] as int? ?? 0,
      productName: json['productName'] as String? ?? json['ProductName'] as String?,
      productCode: json['productCode'] as String? ?? json['ProductCode'] as String?,
      producedQty: (json['producedQty'] as num? ?? json['ProducedQty'] as num? ?? 0.0).toDouble(),
      goodQty: (json['goodQty'] as num? ?? json['GoodQty'] as num? ?? 0.0).toDouble(),
      rejectQty: (json['rejectQty'] as num? ?? json['RejectQty'] as num? ?? 0.0).toDouble(),
      batchNo: json['batchNo'] as String? ?? json['BatchNo'] as String? ?? '',
      unitCost: (json['unitCost'] as num? ?? json['UnitCost'] as num? ?? 0.0).toDouble(),
      outputDate: json['outputDate'] != null
          ? DateTime.parse(json['outputDate'].toString())
          : (json['OutputDate'] != null
              ? DateTime.parse(json['OutputDate'].toString())
              : DateTime.now()),
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
      'producedQty': producedQty,
      'goodQty': goodQty,
      'rejectQty': rejectQty,
      'batchNo': batchNo,
      'unitCost': unitCost,
      'outputDate': outputDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
