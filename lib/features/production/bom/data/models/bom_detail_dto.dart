import '../../../../../../core/utils/json_reader.dart';

class BomDetailDto {
  const BomDetailDto({
    required this.id,
    required this.bomId,
    required this.rawMaterialId,
    this.rawMaterialName,
    this.rawMaterialCode,
    this.unitName,
    required this.quantityRequired,
    this.scrapPercent = 0.0,
    this.unitCost = 0.0,
    this.notes,
    this.isActive = true,
  });

  final int id;
  final int bomId;
  final int rawMaterialId;
  final String? rawMaterialName;
  final String? rawMaterialCode;
  final String? unitName;
  final double quantityRequired;
  final double scrapPercent;
  final double unitCost;
  final String? notes;
  final bool isActive;

  /// Effective quantity including scrap/wastage allowance percentage
  double get effectiveQuantity => quantityRequired * (1 + (scrapPercent / 100.0));

  /// Total cost contribution of this raw material line item
  double get itemCost => effectiveQuantity * unitCost;

  factory BomDetailDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return BomDetailDto(
      id: reader.getInt('id', aliases: ['Id', 'BOMDetailId', 'bomDetailId']),
      bomId: reader.getInt('bomId', aliases: ['BOMHeaderId', 'bomHeaderId', 'BomId']),
      rawMaterialId: reader.getInt('rawMaterialId', aliases: ['RawMaterialId', 'ProductId', 'productId']),
      rawMaterialName: reader.getOptionalString('rawMaterialName', aliases: ['RawMaterialName', 'ProductName', 'productName']),
      rawMaterialCode: reader.getOptionalString('rawMaterialCode', aliases: ['RawMaterialCode', 'ProductCode', 'productCode']),
      unitName: reader.getOptionalString('unitName', aliases: ['UnitName']),
      quantityRequired: reader.getDouble('quantityRequired', aliases: ['QuantityRequired', 'quantity', 'Quantity', 'qty', 'Qty']),
      scrapPercent: reader.getDouble('scrapPercent', aliases: ['ScrapPercent']),
      unitCost: reader.getDouble('unitCost', aliases: ['UnitCost', 'cost', 'Cost', 'price', 'Price']),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bomId': bomId,
      'rawMaterialId': rawMaterialId,
      if (rawMaterialName != null) 'rawMaterialName': rawMaterialName,
      if (rawMaterialCode != null) 'rawMaterialCode': rawMaterialCode,
      if (unitName != null) 'unitName': unitName,
      'quantityRequired': quantityRequired,
      'scrapPercent': scrapPercent,
      'unitCost': unitCost,
      if (notes != null) 'notes': notes,
      'isActive': isActive,
    };
  }

  BomDetailDto copyWith({
    int? id,
    int? bomId,
    int? rawMaterialId,
    String? rawMaterialName,
    String? rawMaterialCode,
    String? unitName,
    double? quantityRequired,
    double? scrapPercent,
    double? unitCost,
    String? notes,
    bool? isActive,
  }) {
    return BomDetailDto(
      id: id ?? this.id,
      bomId: bomId ?? this.bomId,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      rawMaterialName: rawMaterialName ?? this.rawMaterialName,
      rawMaterialCode: rawMaterialCode ?? this.rawMaterialCode,
      unitName: unitName ?? this.unitName,
      quantityRequired: quantityRequired ?? this.quantityRequired,
      scrapPercent: scrapPercent ?? this.scrapPercent,
      unitCost: unitCost ?? this.unitCost,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}
