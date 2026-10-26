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
      id: json['id'] as int? ?? json['grnDetailId'] as int? ?? json['GRNDetailId'] as int? ?? 0,
      grnId: json['grnId'] as int? ?? json['GRNId'] as int? ?? 0,
      productId: json['productId'] as int? ?? json['ProductId'] as int? ?? 0,
      productName: json['productName'] as String? ?? json['ProductName'] as String?,
      productCode: json['productCode'] as String? ?? json['ProductCode'] as String?,
      unitName: json['unitName'] as String? ?? json['UnitName'] as String?,
      orderedQuantity: parseDouble(json['orderedQuantity'] ?? json['orderedQty'] ?? json['OrderedQty']),
      receivedQuantity: parseDouble(json['receivedQuantity'] ?? json['receivedQty'] ?? json['ReceivedQty']),
      rejectedQuantity: parseDouble(json['rejectedQuantity'] ?? json['rejectedQty'] ?? json['RejectedQty']),
      unitCost: parseDouble(json['unitCost'] ?? json['rate'] ?? json['UnitCost']),
      batchNumber: json['batchNumber'] as String? ?? json['batchNo'] as String? ?? json['BatchNo'] as String?,
      expiryDate: parseDate(json['expiryDate'] ?? json['ExpiryDate']),
      remarks: json['remarks'] as String? ?? json['notes'] as String? ?? json['Notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'grnDetailId': id,
      'grnId': grnId,
      'productId': productId,
      'orderedQty': orderedQuantity,
      'receivedQty': receivedQuantity,
      'rejectedQty': rejectedQuantity,
      'unitCost': unitCost,
      if (batchNumber != null && batchNumber!.isNotEmpty) 'batchNo': batchNumber,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      if (remarks != null && remarks!.isNotEmpty) 'notes': remarks,
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
