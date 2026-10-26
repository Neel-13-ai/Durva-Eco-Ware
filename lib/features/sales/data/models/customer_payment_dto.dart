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
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return CustomerPaymentDto(
      id: json['id'] as int? ?? 0,
      receiptNumber: json['receiptNumber'] as String? ?? '',
      customerId: json['customerId'] as int? ?? 0,
      customerName: json['customerName'] as String?,
      saleId: json['saleId'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String?,
      paymentDate: parseDate(json['paymentDate']),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethodId: json['paymentMethodId'] as int? ?? 0,
      paymentMethodName: json['paymentMethodName'] as String?,
      referenceNo: json['referenceNo'] as String?,
      notes: (json['notes'] ?? json['Notes'])?.toString(),
      createdBy: (json['createdBy'] ?? json['CreatedBy'])?.toString(),
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
