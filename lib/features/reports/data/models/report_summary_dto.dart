class StockSummaryRowDto {
  final String categoryName;
  final int itemCount;
  final double totalQuantity;
  final double totalValuation;
  final int lowStockCount;

  const StockSummaryRowDto({
    required this.categoryName,
    required this.itemCount,
    required this.totalQuantity,
    required this.totalValuation,
    required this.lowStockCount,
  });

  factory StockSummaryRowDto.fromJson(Map<String, dynamic> json) {
    return StockSummaryRowDto(
      categoryName: json['categoryName'] as String? ?? 'General',
      itemCount: json['itemCount'] as int? ?? 0,
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      totalValuation: (json['totalValuation'] as num?)?.toDouble() ?? 0.0,
      lowStockCount: json['lowStockCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryName': categoryName,
        'itemCount': itemCount,
        'totalQuantity': totalQuantity,
        'totalValuation': totalValuation,
        'lowStockCount': lowStockCount,
      };
}

class ProductionSummaryRowDto {
  final String orderNumber;
  final String productName;
  final double plannedQty;
  final double producedQty;
  final double goodQty;
  final double rejectQty;
  final String status;

  const ProductionSummaryRowDto({
    required this.orderNumber,
    required this.productName,
    required this.plannedQty,
    required this.producedQty,
    required this.goodQty,
    required this.rejectQty,
    required this.status,
  });

  double get yieldPercentage => plannedQty > 0 ? (goodQty / plannedQty) * 100 : 0.0;
  double get rejectRate => producedQty > 0 ? (rejectQty / producedQty) * 100 : 0.0;

  factory ProductionSummaryRowDto.fromJson(Map<String, dynamic> json) {
    return ProductionSummaryRowDto(
      orderNumber: json['orderNumber'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      plannedQty: (json['plannedQty'] as num?)?.toDouble() ?? 0.0,
      producedQty: (json['producedQty'] as num?)?.toDouble() ?? 0.0,
      goodQty: (json['goodQty'] as num?)?.toDouble() ?? 0.0,
      rejectQty: (json['rejectQty'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'COMPLETED',
    );
  }

  Map<String, dynamic> toJson() => {
        'orderNumber': orderNumber,
        'productName': productName,
        'plannedQty': plannedQty,
        'producedQty': producedQty,
        'goodQty': goodQty,
        'rejectQty': rejectQty,
        'status': status,
      };
}

class SalesSummaryRowDto {
  final String periodOrCustomer;
  final int invoiceCount;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final double paidAmount;
  final double outstandingBalance;

  const SalesSummaryRowDto({
    required this.periodOrCustomer,
    required this.invoiceCount,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    this.paidAmount = 0.0,
    this.outstandingBalance = 0.0,
  });

  factory SalesSummaryRowDto.fromJson(Map<String, dynamic> json) {
    return SalesSummaryRowDto(
      periodOrCustomer: json['periodOrCustomer'] as String? ?? json['customerName'] as String? ?? '',
      invoiceCount: json['invoiceCount'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'periodOrCustomer': periodOrCustomer,
        'invoiceCount': invoiceCount,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'grandTotal': grandTotal,
        'paidAmount': paidAmount,
        'outstandingBalance': outstandingBalance,
      };
}
