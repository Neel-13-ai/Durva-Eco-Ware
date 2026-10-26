import '../../../../core/utils/json_reader.dart';

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
    final reader = JsonReader(json);
    String? prodName = reader.getOptionalString('productName', aliases: ['ProductName']);
    if (prodName == null) {
      final pMap = reader.getMap('product', aliases: ['Product']);
      if (pMap != null) {
        prodName = pMap['name']?.toString() ?? pMap['productName']?.toString();
      }
    }

    return DeliveryDetailDto(
      id: reader.getInt('id', aliases: ['Id', 'deliveryDetailId', 'DeliveryDetailId']),
      deliveryId: reader.getInt('deliveryId', aliases: ['DeliveryId']),
      saleDetailId: reader.getOptionalInt('saleDetailId', aliases: ['SaleDetailId']),
      productId: reader.getInt('productId', aliases: ['ProductId']),
      productName: prodName,
      quantity: reader.getDouble('quantity', aliases: ['Quantity', 'qty', 'Qty']),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'deliveryId': deliveryId,
      if (saleDetailId != null) 'saleDetailId': saleDetailId,
      'productId': productId,
      'quantity': quantity,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
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
    final reader = JsonReader(json);

    String? custName = reader.getOptionalString('customerName', aliases: ['CustomerName']);
    if (custName == null) {
      final cMap = reader.getMap('customer', aliases: ['Customer']);
      if (cMap != null) {
        custName = cMap['customerName']?.toString() ?? cMap['name']?.toString();
      }
    }

    String? invNum = reader.getOptionalString('invoiceNumber', aliases: ['InvoiceNumber', 'saleNumber', 'SaleNumber']);
    if (invNum == null) {
      final sMap = reader.getMap('sale', aliases: ['Sale']);
      if (sMap != null) {
        invNum = sMap['invoiceNumber']?.toString() ?? sMap['saleNumber']?.toString();
      }
    }

    String? transName = reader.getOptionalString('transporterName', aliases: ['TransporterName']);
    if (transName == null) {
      final tMap = reader.getMap('transporter', aliases: ['Transporter']);
      if (tMap != null) {
        transName = tMap['transporterName']?.toString() ?? tMap['name']?.toString();
      }
    }

    String? vehNum = reader.getOptionalString('vehicleNumber', aliases: ['VehicleNumber']);
    if (vehNum == null) {
      final vMap = reader.getMap('vehicle', aliases: ['Vehicle']);
      if (vMap != null) {
        vehNum = vMap['vehicleNumber']?.toString() ?? vMap['registrationNumber']?.toString();
      }
    }

    final rawItems = reader.getList('items', aliases: ['deliveryDetails', 'DeliveryDetails', 'details', 'Details']);
    final itemList = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => DeliveryDetailDto.fromJson(e))
        .toList();

    final id = reader.getInt('id', aliases: ['Id', 'deliveryId', 'DeliveryId']);
    var delivNum = reader.getString('deliveryNumber', aliases: ['DeliveryNumber', 'number', 'Number', 'challanNumber', 'ChallanNumber']);
    if (delivNum.isEmpty && id > 0) {
      delivNum = 'DEL-${id.toString().padLeft(4, '0')}';
    }

    return DeliveryDto(
      id: id,
      deliveryNumber: delivNum,
      saleId: reader.getInt('saleId', aliases: ['SaleId']),
      invoiceNumber: invNum,
      customerId: reader.getInt('customerId', aliases: ['CustomerId']),
      customerName: custName,
      transporterId: reader.getOptionalInt('transporterId', aliases: ['TransporterId']),
      transporterName: transName,
      vehicleId: reader.getOptionalInt('vehicleId', aliases: ['VehicleId']),
      vehicleNumber: vehNum,
      driverName: reader.getOptionalString('driverName', aliases: ['DriverName']),
      driverPhone: reader.getOptionalString('driverPhone', aliases: ['DriverPhone']),
      trackingNumber: reader.getOptionalString('trackingNumber', aliases: ['TrackingNumber']),
      deliveryAddress: reader.getOptionalString('deliveryAddress', aliases: ['DeliveryAddress']),
      freightAmount: reader.getDouble('freightAmount', aliases: ['FreightAmount', 'freight', 'Freight']),
      deliveryDate: reader.getDateTime('deliveryDate', aliases: ['DeliveryDate', 'date', 'Date']) ?? DateTime.now(),
      dispatchDate: reader.getDateTime('dispatchDate', aliases: ['DispatchDate']),
      deliveredDate: reader.getDateTime('deliveredDate', aliases: ['DeliveredDate']),
      status: reader.getString('status', aliases: ['Status'], defaultValue: 'DRAFT'),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      if (deliveryNumber.isNotEmpty && !deliveryNumber.startsWith('AUTO')) 'deliveryNumber': deliveryNumber,
      'saleId': saleId,
      'customerId': customerId,
      if (transporterId != null && transporterId! > 0) 'transporterId': transporterId,
      if (vehicleId != null && vehicleId! > 0) 'vehicleId': vehicleId,
      if (driverName != null && driverName!.isNotEmpty) 'driverName': driverName,
      if (driverPhone != null && driverPhone!.isNotEmpty) 'driverPhone': driverPhone,
      if (trackingNumber != null && trackingNumber!.isNotEmpty) 'trackingNumber': trackingNumber,
      if (deliveryAddress != null && deliveryAddress!.isNotEmpty) 'deliveryAddress': deliveryAddress,
      'freightAmount': freightAmount,
      'deliveryDate': deliveryDate.toIso8601String(),
      if (dispatchDate != null) 'dispatchDate': dispatchDate!.toIso8601String(),
      if (deliveredDate != null) 'deliveredDate': deliveredDate!.toIso8601String(),
      'status': status,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdBy': 1,
      if (items.isNotEmpty) 'deliveryDetails': items.map((i) => i.toJson()).toList(),
    };
  }
}
