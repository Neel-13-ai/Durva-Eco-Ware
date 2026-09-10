class DeliveryDetailDto {
  final int id;
  final int deliveryId;
  final int? saleDetailId;
  final int productId;
  final String? productName;
  final double quantity;
  final String? notes;

  const DeliveryDetailDto({
    required this.id,
    required this.deliveryId,
    this.saleDetailId,
    required this.productId,
    this.productName,
    required this.quantity,
    this.notes,
  });

  factory DeliveryDetailDto.fromJson(Map<String, dynamic> json) {
    return DeliveryDetailDto(
      id: json['id'] as int? ?? 0,
      deliveryId: json['deliveryId'] as int? ?? 0,
      saleDetailId: json['saleDetailId'] as int?,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'deliveryId': deliveryId,
      if (saleDetailId != null) 'saleDetailId': saleDetailId,
      'productId': productId,
      if (productName != null) 'productName': productName,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
    };
  }
}

class DeliveryDto {
  final int id;
  final String deliveryNumber;
  final int saleId;
  final String? invoiceNumber;
  final int customerId;
  final String? customerName;
  final int? transporterId;
  final String? transporterName;
  final int? vehicleId;
  final String? vehicleNumber;
  final String? driverName;
  final String? driverPhone;
  final String? trackingNumber;
  final String? deliveryAddress;
  final double freightAmount;
  final DateTime deliveryDate;
  final DateTime? dispatchDate;
  final DateTime? deliveredDate;
  final String status; // DRAFT, DISPATCHED, DELIVERED, CANCELLED
  final String? notes;
  final List<DeliveryDetailDto> items;

  const DeliveryDto({
    required this.id,
    required this.deliveryNumber,
    required this.saleId,
    this.invoiceNumber,
    required this.customerId,
    this.customerName,
    this.transporterId,
    this.transporterName,
    this.vehicleId,
    this.vehicleNumber,
    this.driverName,
    this.driverPhone,
    this.trackingNumber,
    this.deliveryAddress,
    this.freightAmount = 0.0,
    required this.deliveryDate,
    this.dispatchDate,
    this.deliveredDate,
    this.status = 'DRAFT',
    this.notes,
    this.items = const [],
  });

  bool get isDispatched => status == 'DISPATCHED' || status == 'DELIVERED';
  bool get isDelivered => status == 'DELIVERED';

  factory DeliveryDto.fromJson(Map<String, dynamic> json) {
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

    return DeliveryDto(
      id: json['id'] as int? ?? 0,
      deliveryNumber: json['deliveryNumber'] as String? ?? '',
      saleId: json['saleId'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String?,
      customerId: json['customerId'] as int? ?? 0,
      customerName: json['customerName'] as String?,
      transporterId: json['transporterId'] as int?,
      transporterName: json['transporterName'] as String?,
      vehicleId: json['vehicleId'] as int?,
      vehicleNumber: json['vehicleNumber'] as String?,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      freightAmount: (json['freightAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryDate: parseDate(json['deliveryDate']),
      dispatchDate: parseNullableDate(json['dispatchDate']),
      deliveredDate: parseNullableDate(json['deliveredDate']),
      status: json['status'] as String? ?? 'DRAFT',
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => DeliveryDetailDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'deliveryNumber': deliveryNumber,
      'saleId': saleId,
      if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (transporterId != null) 'transporterId': transporterId,
      if (transporterName != null) 'transporterName': transporterName,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      if (trackingNumber != null) 'trackingNumber': trackingNumber,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      'freightAmount': freightAmount,
      'deliveryDate': deliveryDate.toIso8601String(),
      if (dispatchDate != null) 'dispatchDate': dispatchDate!.toIso8601String(),
      if (deliveredDate != null) 'deliveredDate': deliveredDate!.toIso8601String(),
      'status': status,
      if (notes != null) 'notes': notes,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
