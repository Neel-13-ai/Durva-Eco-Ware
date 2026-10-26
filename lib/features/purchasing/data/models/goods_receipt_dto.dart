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

    final rawNotes = (json['notes'] ?? json['Notes']) as String?;
    String? parsedChallan = (json['challanNumber'] ?? json['ChallanNumber']) as String?;
    String? parsedVehicle = (json['vehicleNumber'] ?? json['VehicleNumber']) as String?;
    if (rawNotes != null && rawNotes.isNotEmpty) {
      final parts = rawNotes.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.toLowerCase().startsWith('challan:')) {
          parsedChallan ??= trimmed.substring(8).trim();
        } else if (trimmed.toLowerCase().startsWith('vehicle:')) {
          parsedVehicle ??= trimmed.substring(8).trim();
        }
      }
    }

    return GoodsReceiptDto(
      id: json['id'] as int? ?? json['grnId'] as int? ?? json['GRNId'] as int? ?? 0,
      grnNumber: json['grnNumber'] as String? ?? json['GRNNumber'] as String? ?? json['code'] as String? ?? '',
      purchaseId: json['purchaseId'] as int? ?? json['PurchaseId'] as int? ?? 0,
      purchaseNumber: json['purchaseNumber'] as String? ?? json['PurchaseNumber'] as String? ?? json['poNumber'] as String?,
      warehouseId: json['warehouseId'] as int? ?? json['WarehouseId'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String? ?? json['WarehouseName'] as String?,
      supplierName: json['supplierName'] as String? ?? json['SupplierName'] as String?,
      receiptDate: parseDate(json['receiptDate'] ?? json['ReceiptDate'] ?? json['date']),
      status: parseStatus((json['status'] ?? json['Status']) as String?),
      receivedBy: (json['receivedBy'] ?? json['ReceivedBy'])?.toString(),
      vehicleNumber: parsedVehicle,
      challanNumber: parsedChallan,
      totalItems: json['totalItems'] as int? ?? json['TotalItems'] as int? ?? itemList.length,
      totalQuantity: parseDouble(json['totalQuantity'] ?? json['TotalQuantity'] ?? json['totalQty']),
      totalAmount: parseDouble(json['totalAmount'] ?? json['TotalAmount']),
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

    final notesParts = <String>[];
    if (challanNumber != null && challanNumber!.isNotEmpty) {
      notesParts.add('Challan: $challanNumber');
    }
    if (vehicleNumber != null && vehicleNumber!.isNotEmpty) {
      notesParts.add('Vehicle: $vehicleNumber');
    }
    final notesStr = notesParts.isNotEmpty ? notesParts.join(', ') : null;

    return {
      if (id > 0) 'id': id,
      'grnNumber': (grnNumber.isNotEmpty && !grnNumber.startsWith('AUTO')) ? grnNumber : 'GRN-${DateTime.now().millisecondsSinceEpoch}',
      'purchaseId': purchaseId,
      'warehouseId': warehouseId,
      'receiptDate': receiptDate.toIso8601String(),
      'status': statusToString(),
      'receivedBy': (receivedBy != null && receivedBy!.isNotEmpty)
          ? (int.tryParse(receivedBy!) ?? 1)
          : 1,
      if (notesStr != null) 'notes': notesStr,
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
