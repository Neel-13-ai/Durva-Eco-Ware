import '../../../../core/utils/json_reader.dart';

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
    final reader = JsonReader(json);
    return ProductionMaterialIssueDto(
      id: reader.getInt('id', aliases: ['Id', 'ProductionMaterialIssueId', 'productionMaterialIssueId']),
      productionOrderId: reader.getInt('productionOrderId', aliases: ['ProductionOrderId']),
      productId: reader.getInt('productId', aliases: ['ProductId']),
      productName: reader.getOptionalString('productName', aliases: ['ProductName']),
      productCode: reader.getOptionalString('productCode', aliases: ['ProductCode']),
      unitName: reader.getOptionalString('unitName', aliases: ['UnitName', 'unit', 'Unit']),
      requiredQty: reader.getDouble('requiredQty', aliases: ['RequiredQty', 'quantity', 'Quantity']),
      issuedQty: reader.getDouble('issuedQty', aliases: ['IssuedQty']),
      unitCost: reader.getDouble('unitCost', aliases: ['UnitCost', 'cost', 'Cost', 'price', 'Price']),
      batchNo: reader.getOptionalString('batchNo', aliases: ['BatchNo']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
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
