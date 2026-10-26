import '../../../../core/utils/json_reader.dart';

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
    final reader = JsonReader(json);
    String? prodName = reader.getOptionalString('productName', aliases: ['ProductName']);
    if (prodName == null) {
      final pMap = reader.getMap('product', aliases: ['Product']);
      if (pMap != null) {
        prodName = pMap['name']?.toString() ?? pMap['productName']?.toString();
      }
    }

    return SaleDetailDto(
      id: reader.getInt('id', aliases: ['saleDetailId', 'SaleDetailId', 'Id']),
      saleId: reader.getInt('saleId', aliases: ['SaleId']),
      productId: reader.getInt('productId', aliases: ['ProductId']),
      productName: prodName,
      quantity: reader.getDouble('quantity', aliases: ['Quantity', 'qty', 'Qty']),
      unitPrice: reader.getDouble('unitPrice', aliases: ['UnitPrice', 'price', 'Price', 'rate', 'Rate']),
      discount: reader.getDouble('discount', aliases: ['Discount']),
      tax: reader.getDouble('tax', aliases: ['Tax', 'taxAmount', 'TaxAmount']),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
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
    final reader = JsonReader(json);

    String? custName = reader.getOptionalString('customerName', aliases: ['CustomerName', 'clientName', 'ClientName']);
    if (custName == null) {
      final custMap = reader.getMap('customer', aliases: ['Customer']);
      if (custMap != null) {
        custName = custMap['name']?.toString() ??
            custMap['customerName']?.toString() ??
            custMap['companyName']?.toString();
      }
    }

    String? whName = reader.getOptionalString('warehouseName', aliases: ['WarehouseName']);
    if (whName == null) {
      final whMap = reader.getMap('warehouse', aliases: ['Warehouse']);
      if (whMap != null) {
        whName = whMap['name']?.toString() ?? whMap['warehouseName']?.toString();
      }
    }

    final rawItems = reader.getList('items', aliases: ['saleDetails', 'SaleDetails', 'details', 'Details']);
    final itemList = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => SaleDetailDto.fromJson(e))
        .toList();

    final id = reader.getInt('id', aliases: ['saleId', 'SaleId', 'Id']);
    var invNum = reader.getString('invoiceNumber', aliases: [
      'InvoiceNumber',
      'saleNumber',
      'SaleNumber',
      'orderNumber',
      'OrderNumber',
      'invoiceNo',
      'InvoiceNo',
      'saleNo',
      'SaleNo',
      'number',
      'Number'
    ]);
    if (invNum.isEmpty && id > 0) {
      invNum = 'INV-${id.toString().padLeft(4, '0')}';
    }

    final subtotal = reader.getDouble('subtotal', aliases: ['Subtotal', 'subTotal', 'SubTotal']);
    final discount = reader.getDouble('discount', aliases: ['Discount']);
    final tax = reader.getDouble('tax', aliases: ['Tax', 'taxAmount', 'TaxAmount']);
    final transport = reader.getDouble('transportCharge', aliases: ['TransportCharge', 'transportCost', 'TransportCost', 'freight', 'Freight']);
    var total = reader.getDouble('totalAmount', aliases: ['TotalAmount', 'total', 'Total', 'grandTotal', 'GrandTotal', 'netAmount', 'NetAmount']);

    if (total == 0.0) {
      if (subtotal > 0.0) {
        total = subtotal - discount + tax + transport;
      } else if (itemList.isNotEmpty) {
        final sumItems = itemList.fold(0.0, (sum, i) => sum + i.lineTotal);
        total = sumItems - discount + tax + transport;
      }
    }

    final paid = reader.getDouble('paidAmount', aliases: ['PaidAmount', 'paid', 'Paid']);

    return SaleDto(
      id: id,
      invoiceNumber: invNum,
      customerId: reader.getInt('customerId', aliases: ['CustomerId', 'Customer_Id']),
      customerName: custName,
      warehouseId: reader.getInt('warehouseId', aliases: ['WarehouseId']),
      warehouseName: whName,
      saleDate: reader.getDateTime('saleDate', aliases: ['SaleDate', 'date', 'Date', 'createdAt', 'CreatedAt']) ?? DateTime.now(),
      dueDate: reader.getDateTime('dueDate', aliases: ['DueDate', 'paymentDueDate', 'PaymentDueDate']),
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      transportCharge: transport,
      totalAmount: total,
      paidAmount: paid,
      status: reader.getString('status', aliases: ['Status'], defaultValue: 'CONFIRMED'),
      paymentStatus: reader.getString('paymentStatus', aliases: ['PaymentStatus'], defaultValue: 'PENDING'),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      if (invoiceNumber.isNotEmpty && !invoiceNumber.startsWith('AUTO')) 'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'warehouseId': warehouseId,
      'saleDate': saleDate.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'transportCharge': transportCharge,
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdBy': 1,
      if (items.isNotEmpty) 'saleDetails': items.map((i) => i.toJson()).toList(),
    };
  }
}

