class GoodsReceiptDetailDto {
  const GoodsReceiptDetailDto({
    required this.id,
    required this.grnId,
    required this.productId,
    this.productName,
    this.productCode,
    this.unitName,
    required this.orderedQuantity,
    required this.receivedQuantity,
    this.rejectedQuantity = 0.0,
    required this.unitCost,
    this.batchNumber,
    this.expiryDate,
    this.remarks,
  });

  final int id;
  final int grnId;
  final int productId;
  final String? productName;
  final String? productCode;
  final String? unitName;
  final double orderedQuantity;
  final double receivedQuantity;
  final double rejectedQuantity;
  final double unitCost;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? remarks;

  double get acceptedQuantity => (receivedQuantity - rejectedQuantity).clamp(0.0, double.infinity);
  double get totalCost => acceptedQuantity * unitCost;

  factory GoodsReceiptDetailDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is String) return DateTime.tryParse(d);
      return null;
    }

    return GoodsReceiptDetailDto(
      id: json['id'] as int? ?? json['grnDetailId'] as int? ?? 0,
      grnId: json['grnId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String?,
      productCode: json['productCode'] as String?,
      unitName: json['unitName'] as String?,
      orderedQuantity: parseDouble(json['orderedQuantity'] ?? json['orderedQty']),
      receivedQuantity: parseDouble(json['receivedQuantity'] ?? json['receivedQty']),
      rejectedQuantity: parseDouble(json['rejectedQuantity'] ?? json['rejectedQty']),
      unitCost: parseDouble(json['unitCost'] ?? json['rate']),
      batchNumber: json['batchNumber'] as String? ?? json['batchNo'] as String?,
      expiryDate: parseDate(json['expiryDate']),
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grnId': grnId,
      'productId': productId,
      if (productName != null) 'productName': productName,
      if (productCode != null) 'productCode': productCode,
      if (unitName != null) 'unitName': unitName,
      'orderedQuantity': orderedQuantity,
      'receivedQuantity': receivedQuantity,
      'rejectedQuantity': rejectedQuantity,
      'unitCost': unitCost,
      if (batchNumber != null) 'batchNumber': batchNumber,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      if (remarks != null) 'remarks': remarks,
    };
  }

  GoodsReceiptDetailDto copyWith({
    int? id,
    int? grnId,
    int? productId,
    String? productName,
    String? productCode,
    String? unitName,
    double? orderedQuantity,
    double? receivedQuantity,
    double? rejectedQuantity,
    double? unitCost,
    String? batchNumber,
    DateTime? expiryDate,
    String? remarks,
  }) {
    return GoodsReceiptDetailDto(
      id: id ?? this.id,
      grnId: grnId ?? this.grnId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitName: unitName ?? this.unitName,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      rejectedQuantity: rejectedQuantity ?? this.rejectedQuantity,
      unitCost: unitCost ?? this.unitCost,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      remarks: remarks ?? this.remarks,
    );
  }
}
