import '../../../../core/utils/json_reader.dart';

class CustomerPaymentDto {
  final int id;
  final String receiptNumber;
  final int customerId;
  final String? customerName;
  final int saleId;
  final String? invoiceNumber;
  final DateTime paymentDate;
  final double amount;
  final int paymentMethodId;
  final String? paymentMethodName;
  final String? referenceNo;
  final String? notes;
  final String? createdBy;

  const CustomerPaymentDto({
    required this.id,
    required this.receiptNumber,
    required this.customerId,
    this.customerName,
    required this.saleId,
    this.invoiceNumber,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethodId,
    this.paymentMethodName,
    this.referenceNo,
    this.notes,
    this.createdBy,
  });

  factory CustomerPaymentDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final id = reader.getInt('id', aliases: ['customerPaymentId', 'CustomerPaymentId', 'paymentId', 'PaymentId', 'Id']);
    var rNum = reader.getString('receiptNumber', aliases: ['ReceiptNumber', 'receiptNo', 'ReceiptNo', 'paymentNumber', 'PaymentNumber', 'number', 'Number']);
    if (rNum.isEmpty && id > 0) {
      rNum = 'RCP-${id.toString().padLeft(4, '0')}';
    }

    return CustomerPaymentDto(
      id: id,
      receiptNumber: rNum,
      customerId: reader.getInt('customerId', aliases: ['CustomerId', 'Customer_Id']),
      customerName: reader.getOptionalString('customerName', aliases: ['CustomerName']),
      saleId: reader.getInt('saleId', aliases: ['SaleId']),
      invoiceNumber: reader.getOptionalString('invoiceNumber', aliases: ['InvoiceNumber', 'saleNumber', 'SaleNumber']),
      paymentDate: reader.getDateTime('paymentDate', aliases: ['PaymentDate', 'date', 'Date']) ?? DateTime.now(),
      amount: reader.getDouble('amount', aliases: ['Amount', 'paidAmount', 'PaidAmount', 'totalAmount', 'TotalAmount']),
      paymentMethodId: reader.getInt('paymentMethodId', aliases: ['paymentMethodId', 'PaymentMethodId']),
      paymentMethodName: reader.getOptionalString('paymentMethodName', aliases: ['PaymentMethodName']),
      referenceNo: reader.getOptionalString('referenceNo', aliases: ['ReferenceNo', 'referenceNumber', 'ReferenceNumber']),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
      createdBy: reader.getOptionalString('createdBy', aliases: ['CreatedBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      if (receiptNumber.isNotEmpty && !receiptNumber.startsWith('AUTO')) 'receiptNumber': receiptNumber,
      'customerId': customerId,
      'saleId': saleId,
      'paymentDate': paymentDate.toIso8601String(),
      'amount': amount,
      'paymentMethodId': paymentMethodId,
      if (referenceNo != null && referenceNo!.isNotEmpty) 'referenceNo': referenceNo,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdBy': (createdBy != null && int.tryParse(createdBy!) != null) ? int.parse(createdBy!) : 1,
    };
  }
}
