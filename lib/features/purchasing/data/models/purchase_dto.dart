import '../../../../core/utils/json_reader.dart';
import 'purchase_detail_dto.dart';

enum PurchaseStatus {
  draft,
  pending,
  approved,
  partiallyReceived,
  received,
  cancelled,
}

class PurchaseDto {
  const PurchaseDto({
    required this.id,
    required this.purchaseNumber,
    required this.supplierId,
    this.supplierName,
    required this.warehouseId,
    this.warehouseName,
    required this.purchaseDate,
    this.expectedDeliveryDate,
    this.status = PurchaseStatus.draft,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.transportCost = 0.0,
    this.otherCost = 0.0,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.referenceNo,
    this.notes,
    this.items = const [],
  });

  final int id;
  final String purchaseNumber;
  final int supplierId;
  final String? supplierName;
  final int warehouseId;
  final String? warehouseName;
  final DateTime purchaseDate;
  final DateTime? expectedDeliveryDate;
  final PurchaseStatus status;
  final double subtotal;
  final double taxAmount;
  final double transportCost;
  final double otherCost;
  final double totalAmount;
  final double paidAmount;
  final String? referenceNo;
  final String? notes;
  final List<PurchaseDetailDto> items;

  double get outstandingBalance => (totalAmount - paidAmount).clamp(0.0, double.infinity);
  bool get isFullyPaid => outstandingBalance <= 0.01;

  factory PurchaseDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    PurchaseStatus parseStatus(String? s) {
      switch (s?.toUpperCase()) {
        case 'PENDING':
          return PurchaseStatus.pending;
        case 'APPROVED':
          return PurchaseStatus.approved;
        case 'PARTIALLY_RECEIVED':
        case 'PARTIALLYRECEIVED':
          return PurchaseStatus.partiallyReceived;
        case 'RECEIVED':
          return PurchaseStatus.received;
        case 'CANCELLED':
          return PurchaseStatus.cancelled;
        case 'DRAFT':
        default:
          return PurchaseStatus.draft;
      }
    }

    final rawItems = reader.getList('items', aliases: ['purchaseDetails', 'PurchaseDetails', 'details', 'Details']);
    final itemList = rawItems
        .map((e) => PurchaseDetailDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return PurchaseDto(
      id: reader.getInt('id', aliases: ['purchaseId', 'PurchaseId', 'Id']),
      purchaseNumber: reader.getString('purchaseNumber', aliases: ['PurchaseNumber', 'poNumber', 'PoNumber', 'number', 'Number']),
      supplierId: reader.getInt('supplierId', aliases: ['SupplierId']),
      supplierName: reader.getOptionalString('supplierName', aliases: ['SupplierName']),
      warehouseId: reader.getInt('warehouseId', aliases: ['WarehouseId']),
      warehouseName: reader.getOptionalString('warehouseName', aliases: ['WarehouseName']),
      purchaseDate: reader.getDateTime('purchaseDate', aliases: ['PurchaseDate', 'date', 'Date']) ?? DateTime.now(),
      expectedDeliveryDate: reader.getDateTime('expectedDeliveryDate', aliases: ['ExpectedDeliveryDate', 'deliveryDate', 'DeliveryDate']),
      status: parseStatus(reader.getOptionalString('status', aliases: ['Status'])),
      subtotal: reader.getDouble('subtotal', aliases: ['Subtotal', 'subTotal']),
      taxAmount: reader.getDouble('taxAmount', aliases: ['TaxAmount', 'tax', 'Tax']),
      transportCost: reader.getDouble('transportCost', aliases: ['TransportCost', 'transportCharges']),
      otherCost: reader.getDouble('otherCost', aliases: ['OtherCost']),
      totalAmount: reader.getDouble('totalAmount', aliases: ['TotalAmount', 'total', 'Total', 'grandTotal', 'GrandTotal']),
      paidAmount: reader.getDouble('paidAmount', aliases: ['PaidAmount', 'paid', 'Paid']),
      referenceNo: reader.getOptionalString('referenceNo', aliases: ['ReferenceNo', 'referenceNumber']),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    String statusToString() {
      switch (status) {
        case PurchaseStatus.draft:
          return 'DRAFT';
        case PurchaseStatus.pending:
          return 'PENDING';
        case PurchaseStatus.approved:
          return 'APPROVED';
        case PurchaseStatus.partiallyReceived:
          return 'PARTIALLY_RECEIVED';
        case PurchaseStatus.received:
          return 'RECEIVED';
        case PurchaseStatus.cancelled:
          return 'CANCELLED';
      }
    }

    return {
      'id': id,
      'purchaseNumber': purchaseNumber,
      'supplierId': supplierId,
      if (supplierName != null) 'supplierName': supplierName,
      'warehouseId': warehouseId,
      if (warehouseName != null) 'warehouseName': warehouseName,
      'purchaseDate': purchaseDate.toIso8601String(),
      if (expectedDeliveryDate != null) 'expectedDeliveryDate': expectedDeliveryDate!.toIso8601String(),
      'status': statusToString(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'transportCost': transportCost,
      'otherCost': otherCost,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      if (referenceNo != null) 'referenceNo': referenceNo,
      if (notes != null) 'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  PurchaseDto copyWith({
    int? id,
    String? purchaseNumber,
    int? supplierId,
    String? supplierName,
    int? warehouseId,
    String? warehouseName,
    DateTime? purchaseDate,
    DateTime? expectedDeliveryDate,
    PurchaseStatus? status,
    double? subtotal,
    double? taxAmount,
    double? transportCost,
    double? otherCost,
    double? totalAmount,
    double? paidAmount,
    String? referenceNo,
    String? notes,
    List<PurchaseDetailDto>? items,
  }) {
    return PurchaseDto(
      id: id ?? this.id,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      transportCost: transportCost ?? this.transportCost,
      otherCost: otherCost ?? this.otherCost,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      referenceNo: referenceNo ?? this.referenceNo,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }
}
