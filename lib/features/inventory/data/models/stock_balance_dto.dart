class StockBalanceDto {
  const StockBalanceDto({
    required this.id,
    required this.productId,
    this.productName,
    this.productCode,
    this.unitName,
    this.productType,
    required this.warehouseId,
    this.warehouseName,
    required this.quantity,
    this.averageCost = 0.0,
    this.minimumStock = 0.0,
    this.isActive = true,
  });

  final int id;
  final int productId;
  final String? productName;
  final String? productCode;
  final String? unitName;
  final String? productType;
  final int warehouseId;
  final String? warehouseName;
  final double quantity;
  final double averageCost;
  final double minimumStock;
  final bool isActive;

  double get totalValue => quantity * averageCost;
  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity > 0 && quantity <= minimumStock;

  factory StockBalanceDto.fromJson(Map<String, dynamic> json) {
    return StockBalanceDto(
      id: json['id'] as int? ?? json['StockBalanceId'] as int? ?? 0,
      productId: json['productId'] as int? ?? json['ProductId'] as int? ?? 0,
      productName: json['productName'] as String? ?? json['ProductName'] as String?,
      productCode: json['productCode'] as String? ?? json['ProductCode'] as String?,
      unitName: json['unitName'] as String? ?? json['UnitName'] as String?,
      productType: json['productType'] as String? ?? json['ProductType'] as String?,
      warehouseId: json['warehouseId'] as int? ?? json['WarehouseId'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String? ?? json['WarehouseName'] as String?,
      quantity: (json['quantity'] as num? ?? json['Quantity'] as num? ?? 0.0).toDouble(),
      averageCost: (json['averageCost'] as num? ?? json['AverageCost'] as num? ?? 0.0).toDouble(),
      minimumStock: (json['minimumStock'] as num? ?? json['MinimumStock'] as num? ?? 0.0).toDouble(),
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      if (productName != null) 'productName': productName,
      if (productCode != null) 'productCode': productCode,
      if (unitName != null) 'unitName': unitName,
      if (productType != null) 'productType': productType,
      'warehouseId': warehouseId,
      if (warehouseName != null) 'warehouseName': warehouseName,
      'quantity': quantity,
      'averageCost': averageCost,
      'minimumStock': minimumStock,
      'isActive': isActive,
    };
  }

  StockBalanceDto copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productCode,
    String? unitName,
    String? productType,
    int? warehouseId,
    String? warehouseName,
    double? quantity,
    double? averageCost,
    double? minimumStock,
    bool? isActive,
  }) {
    return StockBalanceDto(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitName: unitName ?? this.unitName,
      productType: productType ?? this.productType,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      quantity: quantity ?? this.quantity,
      averageCost: averageCost ?? this.averageCost,
      minimumStock: minimumStock ?? this.minimumStock,
      isActive: isActive ?? this.isActive,
    );
  }
}
