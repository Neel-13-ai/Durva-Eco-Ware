class SaleDetailDto {
  final int id;
  final int saleId;
  final int productId;
  final String? productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double tax;
  final String? notes;

  const SaleDetailDto({
    required this.id,
    required this.saleId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.tax = 0.0,
    this.notes,
  });

  double get lineTotal => (quantity * unitPrice) - discount + tax;

  factory SaleDetailDto.fromJson(Map<String, dynamic> json) {
    return SaleDetailDto(
      id: json['id'] as int? ?? 0,
      saleId: json['saleId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'saleId': saleId,
      'productId': productId,
      if (productName != null) 'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'tax': tax,
      if (notes != null) 'notes': notes,
    };
  }
}

class SaleDto {
  final int id;
  final String invoiceNumber;
  final int customerId;
  final String? customerName;
  final int warehouseId;
  final String? warehouseName;
  final DateTime saleDate;
  final DateTime? dueDate;
  final double subtotal;
  final double discount;
  final double tax;
  final double transportCharge;
  final double totalAmount;
  final double paidAmount;
  final String status; // DRAFT, CONFIRMED, CANCELLED
  final String paymentStatus; // PENDING, PARTIALLY_PAID, PAID
  final String? notes;
  final List<SaleDetailDto> items;

  const SaleDto({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    this.customerName,
    required this.warehouseId,
    this.warehouseName,
    required this.saleDate,
    this.dueDate,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.transportCharge = 0.0,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.status = 'CONFIRMED',
    this.paymentStatus = 'PENDING',
    this.notes,
    this.items = const [],
  });

  double get outstandingBalance => (totalAmount - paidAmount) > 0 ? (totalAmount - paidAmount) : 0.0;

  bool get isOverdue {
    if (paymentStatus == 'PAID' || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  factory SaleDto.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return SaleDto(
      id: json['id'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      customerId: json['customerId'] as int? ?? 0,
      customerName: json['customerName'] as String?,
      warehouseId: json['warehouseId'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String?,
      saleDate: parseDate(json['saleDate']),
      dueDate: parseNullableDate(json['dueDate']),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      transportCharge: (json['transportCharge'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'CONFIRMED',
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SaleDetailDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      'warehouseId': warehouseId,
      if (warehouseName != null) 'warehouseName': warehouseName,
      'saleDate': saleDate.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'transportCharge': transportCharge,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      if (notes != null) 'notes': notes,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
