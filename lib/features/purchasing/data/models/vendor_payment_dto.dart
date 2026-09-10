class VendorPaymentDto {
  const VendorPaymentDto({
    required this.id,
    required this.paymentNumber,
    required this.supplierId,
    this.supplierName,
    required this.purchaseId,
    this.purchaseNumber,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethodId,
    this.paymentMethodName,
    this.referenceNo,
    this.notes,
  });

  final int id;
  final String paymentNumber;
  final int supplierId;
  final String? supplierName;
  final int purchaseId;
  final String? purchaseNumber;
  final DateTime paymentDate;
  final double amount;
  final int paymentMethodId;
  final String? paymentMethodName;
  final String? referenceNo;
  final String? notes;

  factory VendorPaymentDto.fromJson(Map<String, dynamic> json) {
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

    return VendorPaymentDto(
      id: json['id'] as int? ?? json['paymentId'] as int? ?? 0,
      paymentNumber: json['paymentNumber'] as String? ?? json['voucherNumber'] as String? ?? '',
      supplierId: json['supplierId'] as int? ?? 0,
      supplierName: json['supplierName'] as String?,
      purchaseId: json['purchaseId'] as int? ?? 0,
      purchaseNumber: json['purchaseNumber'] as String?,
      paymentDate: parseDate(json['paymentDate'] ?? json['date']),
      amount: parseDouble(json['amount'] ?? json['paidAmount']),
      paymentMethodId: json['paymentMethodId'] as int? ?? 0,
      paymentMethodName: json['paymentMethodName'] as String?,
      referenceNo: json['referenceNo'] as String? ?? json['transactionRef'] as String?,
      notes: json['notes'] as String? ?? json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentNumber': paymentNumber,
      'supplierId': supplierId,
      if (supplierName != null) 'supplierName': supplierName,
      'purchaseId': purchaseId,
      if (purchaseNumber != null) 'purchaseNumber': purchaseNumber,
      'paymentDate': paymentDate.toIso8601String(),
      'amount': amount,
      'paymentMethodId': paymentMethodId,
      if (paymentMethodName != null) 'paymentMethodName': paymentMethodName,
      if (referenceNo != null) 'referenceNo': referenceNo,
      if (notes != null) 'notes': notes,
    };
  }

  VendorPaymentDto copyWith({
    int? id,
    String? paymentNumber,
    int? supplierId,
    String? supplierName,
    int? purchaseId,
    String? purchaseNumber,
    DateTime? paymentDate,
    double? amount,
    int? paymentMethodId,
    String? paymentMethodName,
    String? referenceNo,
    String? notes,
  }) {
    return VendorPaymentDto(
      id: id ?? this.id,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseId: purchaseId ?? this.purchaseId,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      referenceNo: referenceNo ?? this.referenceNo,
      notes: notes ?? this.notes,
    );
  }
}
