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
    return BomDetailDto(
      id: json['id'] as int? ?? json['BOMDetailId'] as int? ?? 0,
      bomId: json['bomId'] as int? ?? json['BOMHeaderId'] as int? ?? json['BomId'] as int? ?? 0,
      rawMaterialId: json['rawMaterialId'] as int? ?? json['RawMaterialId'] as int? ?? json['ProductId'] as int? ?? 0,
      rawMaterialName: json['rawMaterialName'] as String? ?? json['RawMaterialName'] as String? ?? json['ProductName'] as String?,
      rawMaterialCode: json['rawMaterialCode'] as String? ?? json['RawMaterialCode'] as String? ?? json['ProductCode'] as String?,
      unitName: json['unitName'] as String? ?? json['UnitName'] as String?,
      quantityRequired: (json['quantityRequired'] as num? ?? json['QuantityRequired'] as num? ?? 0.0).toDouble(),
      scrapPercent: (json['scrapPercent'] as num? ?? json['ScrapPercent'] as num? ?? 0.0).toDouble(),
      unitCost: (json['unitCost'] as num? ?? json['UnitCost'] as num? ?? 0.0).toDouble(),
      notes: json['notes'] as String? ?? json['Notes'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
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
