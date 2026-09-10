import 'goods_receipt_detail_dto.dart';

enum GRNStatus {
  draft,
  confirmed,
  cancelled,
}

class GoodsReceiptDto {
  const GoodsReceiptDto({
    required this.id,
    required this.grnNumber,
    required this.purchaseId,
    this.purchaseNumber,
    required this.warehouseId,
    this.warehouseName,
    this.supplierName,
    required this.receiptDate,
    this.status = GRNStatus.confirmed,
    this.receivedBy,
    this.vehicleNumber,
    this.challanNumber,
    this.totalItems = 0,
    this.totalQuantity = 0.0,
    this.totalAmount = 0.0,
    this.items = const [],
  });

  final int id;
  final String grnNumber;
  final int purchaseId;
  final String? purchaseNumber;
  final int warehouseId;
  final String? warehouseName;
  final String? supplierName;
  final DateTime receiptDate;
  final GRNStatus status;
  final String? receivedBy;
  final String? vehicleNumber;
  final String? challanNumber;
  final int totalItems;
  final double totalQuantity;
  final double totalAmount;
  final List<GoodsReceiptDetailDto> items;

  factory GoodsReceiptDto.fromJson(Map<String, dynamic> json) {
    GRNStatus parseStatus(String? s) {
      switch (s?.toUpperCase()) {
        case 'CONFIRMED':
          return GRNStatus.confirmed;
        case 'CANCELLED':
          return GRNStatus.cancelled;
        case 'DRAFT':
        default:
          return GRNStatus.draft;
      }
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    final rawItems = json['items'] as List<dynamic>? ??
        json['goodsReceiptDetails'] as List<dynamic>? ??
        json['details'] as List<dynamic>? ??
        [];

    final itemList = rawItems
        .map((e) => GoodsReceiptDetailDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return GoodsReceiptDto(
      id: json['id'] as int? ?? json['grnId'] as int? ?? 0,
      grnNumber: json['grnNumber'] as String? ?? json['code'] as String? ?? '',
      purchaseId: json['purchaseId'] as int? ?? 0,
      purchaseNumber: json['purchaseNumber'] as String? ?? json['poNumber'] as String?,
      warehouseId: json['warehouseId'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String?,
      supplierName: json['supplierName'] as String?,
      receiptDate: parseDate(json['receiptDate'] ?? json['date']),
      status: parseStatus(json['status'] as String?),
      receivedBy: json['receivedBy'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      challanNumber: json['challanNumber'] as String?,
      totalItems: json['totalItems'] as int? ?? itemList.length,
      totalQuantity: parseDouble(json['totalQuantity'] ?? json['totalQty']),
      totalAmount: parseDouble(json['totalAmount']),
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    String statusToString() {
      switch (status) {
        case GRNStatus.draft:
          return 'DRAFT';
        case GRNStatus.confirmed:
          return 'CONFIRMED';
        case GRNStatus.cancelled:
          return 'CANCELLED';
      }
    }

    return {
      'id': id,
      'grnNumber': grnNumber,
      'purchaseId': purchaseId,
      if (purchaseNumber != null) 'purchaseNumber': purchaseNumber,
      'warehouseId': warehouseId,
      if (warehouseName != null) 'warehouseName': warehouseName,
      if (supplierName != null) 'supplierName': supplierName,
      'receiptDate': receiptDate.toIso8601String(),
      'status': statusToString(),
      if (receivedBy != null) 'receivedBy': receivedBy,
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (challanNumber != null) 'challanNumber': challanNumber,
      'totalItems': totalItems,
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  GoodsReceiptDto copyWith({
    int? id,
    String? grnNumber,
    int? purchaseId,
    String? purchaseNumber,
    int? warehouseId,
    String? warehouseName,
    String? supplierName,
    DateTime? receiptDate,
    GRNStatus? status,
    String? receivedBy,
    String? vehicleNumber,
    String? challanNumber,
    int? totalItems,
    double? totalQuantity,
    double? totalAmount,
    List<GoodsReceiptDetailDto>? items,
  }) {
    return GoodsReceiptDto(
      id: id ?? this.id,
      grnNumber: grnNumber ?? this.grnNumber,
      purchaseId: purchaseId ?? this.purchaseId,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      supplierName: supplierName ?? this.supplierName,
      receiptDate: receiptDate ?? this.receiptDate,
      status: status ?? this.status,
      receivedBy: receivedBy ?? this.receivedBy,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      challanNumber: challanNumber ?? this.challanNumber,
      totalItems: totalItems ?? this.totalItems,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
    );
  }
}
