class ExpenseDto {
  final int id;
  final String expenseNumber;
  final int expenseCategoryId;
  final String? categoryName;
  final int? warehouseId;
  final String? warehouseName;
  final DateTime expenseDate;
  final String? description;
  final double amount;
  final int paymentMethodId;
  final String? paymentMethodName;
  final String? vendorName;
  final String? referenceNo;
  final String? createdBy;
  final bool isActive;

  const ExpenseDto({
    required this.id,
    required this.expenseNumber,
    required this.expenseCategoryId,
    this.categoryName,
    this.warehouseId,
    this.warehouseName,
    required this.expenseDate,
    this.description,
    required this.amount,
    required this.paymentMethodId,
    this.paymentMethodName,
    this.vendorName,
    this.referenceNo,
    this.createdBy,
    this.isActive = true,
  });

  factory ExpenseDto.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return ExpenseDto(
      id: json['id'] as int? ?? json['expenseId'] as int? ?? 0,
      expenseNumber: json['expenseNumber'] as String? ?? '',
      expenseCategoryId: json['expenseCategoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String?,
      warehouseId: json['warehouseId'] as int?,
      warehouseName: json['warehouseName'] as String?,
      expenseDate: parseDate(json['expenseDate']),
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethodId: json['paymentMethodId'] as int? ?? 0,
      paymentMethodName: json['paymentMethodName'] as String?,
      vendorName: json['vendorName'] as String?,
      referenceNo: json['referenceNo'] as String?,
      createdBy: json['createdBy']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'expenseNumber': expenseNumber,
      'expenseCategoryId': expenseCategoryId,
      if (categoryName != null) 'categoryName': categoryName,
      if (warehouseId != null) 'warehouseId': warehouseId,
      if (warehouseName != null) 'warehouseName': warehouseName,
      'expenseDate': expenseDate.toIso8601String(),
      if (description != null) 'description': description,
      'amount': amount,
      'paymentMethodId': paymentMethodId,
      if (paymentMethodName != null) 'paymentMethodName': paymentMethodName,
      if (vendorName != null) 'vendorName': vendorName,
      if (referenceNo != null) 'referenceNo': referenceNo,
      if (createdBy != null) 'createdBy': createdBy,
      'isActive': isActive,
    };
  }
}
