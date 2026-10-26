import '../../../../core/utils/json_reader.dart';

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
    final reader = JsonReader(json);

    String? prodName = reader.getOptionalString('productName', aliases: ['ProductName']);
    String? prodCode = reader.getOptionalString('productCode', aliases: ['ProductCode']);
    String? uName = reader.getOptionalString('unitName', aliases: ['UnitName']);
    String? pType = reader.getOptionalString('productType', aliases: ['ProductType']);

    if (prodName == null) {
      final pMap = reader.getMap('product', aliases: ['Product']);
      if (pMap != null) {
        prodName = pMap['name']?.toString() ?? pMap['productName']?.toString();
        prodCode ??= pMap['code']?.toString() ?? pMap['productCode']?.toString();
        uName ??= pMap['unitName']?.toString() ?? pMap['unit']?['name']?.toString();
        pType ??= pMap['type']?.toString() ?? pMap['productType']?.toString();
      }
    }

    String? whName = reader.getOptionalString('warehouseName', aliases: ['WarehouseName']);
    if (whName == null) {
      final wMap = reader.getMap('warehouse', aliases: ['Warehouse']);
      if (wMap != null) {
        whName = wMap['name']?.toString() ?? wMap['warehouseName']?.toString();
      }
    }

    return StockBalanceDto(
      id: reader.getInt('id', aliases: ['stockBalanceId', 'StockBalanceId', 'Id']),
      productId: reader.getInt('productId', aliases: ['ProductId']),
      productName: prodName,
      productCode: prodCode,
      unitName: uName,
      productType: pType,
      warehouseId: reader.getInt('warehouseId', aliases: ['WarehouseId']),
      warehouseName: whName,
      quantity: reader.getDouble('quantity', aliases: ['Quantity', 'qty', 'Qty']),
      averageCost: reader.getDouble('averageCost', aliases: ['AverageCost', 'cost', 'Cost', 'unitCost', 'UnitCost']),
      minimumStock: reader.getDouble('minimumStock', aliases: ['MinimumStock', 'minStock', 'MinStock']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
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
