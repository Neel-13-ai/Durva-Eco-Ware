import '../../../../core/utils/json_reader.dart';

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
    final reader = JsonReader(json);
    return ProductionOutputDto(
      id: reader.getInt('id', aliases: ['Id', 'ProductionOutputId', 'productionOutputId']),
      productionOrderId: reader.getInt('productionOrderId', aliases: ['ProductionOrderId']),
      productId: reader.getInt('productId', aliases: ['ProductId']),
      productName: reader.getOptionalString('productName', aliases: ['ProductName']),
      productCode: reader.getOptionalString('productCode', aliases: ['ProductCode']),
      producedQty: reader.getDouble('producedQty', aliases: ['ProducedQty', 'quantity', 'Quantity']),
      goodQty: reader.getDouble('goodQty', aliases: ['GoodQty']),
      rejectQty: reader.getDouble('rejectQty', aliases: ['RejectQty', 'wasteQty', 'WasteQty']),
      batchNo: reader.getString('batchNo', aliases: ['BatchNo'], defaultValue: ''),
      unitCost: reader.getDouble('unitCost', aliases: ['UnitCost', 'cost', 'Cost']),
      outputDate: reader.getDateTime('outputDate', aliases: ['OutputDate', 'date', 'Date']) ?? DateTime.now(),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'productionOrderId': productionOrderId,
      'productId': productId,
      'producedQty': producedQty,
      'goodQty': goodQty,
      'rejectQty': rejectQty,
      'batchNo': batchNo,
      'unitCost': unitCost,
      'outputDate': outputDate.toIso8601String(),
    };
  }
}
