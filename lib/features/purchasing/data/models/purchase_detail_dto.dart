import '../../../../core/utils/json_reader.dart';

class PurchaseDetailDto {
  const PurchaseDetailDto({
    required this.id,
    required this.purchaseId,
    required this.productId,
    this.productName,
    this.productCode,
    this.unitName,
    required this.quantity,
    required this.unitCost,
    this.discount = 0.0,
    this.tax = 0.0,
    this.receivedQuantity = 0.0,
  });

  final int id;
  final int purchaseId;
  final int productId;
  final String? productName;
  final String? productCode;
  final String? unitName;
  final double quantity;
  final double unitCost;
  final double discount;
  final double tax;
  final double receivedQuantity;

  double get lineTotal => (quantity * unitCost) - discount + tax;
  double get pendingQuantity => (quantity - receivedQuantity).clamp(0.0, double.infinity);

  factory PurchaseDetailDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PurchaseDetailDto(
      id: reader.getInt('id', aliases: ['purchaseDetailId', 'PurchaseDetailId', 'Id']),
      purchaseId: reader.getInt('purchaseId', aliases: ['PurchaseId']),
      productId: reader.getInt('productId', aliases: ['ProductId']),
      productName: reader.getOptionalString('productName', aliases: ['ProductName']),
      productCode: reader.getOptionalString('productCode', aliases: ['ProductCode']),
      unitName: reader.getOptionalString('unitName', aliases: ['UnitName']),
      quantity: reader.getDouble('quantity', aliases: ['Quantity', 'qty', 'Qty']),
      unitCost: reader.getDouble('unitCost', aliases: ['UnitCost', 'rate', 'Rate', 'price', 'Price']),
      discount: reader.getDouble('discount', aliases: ['Discount']),
      tax: reader.getDouble('tax', aliases: ['Tax', 'taxAmount', 'TaxAmount']),
      receivedQuantity: reader.getDouble('receivedQuantity', aliases: ['ReceivedQuantity', 'receivedQty', 'ReceivedQty']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      if (productName != null) 'productName': productName,
      if (productCode != null) 'productCode': productCode,
      if (unitName != null) 'unitName': unitName,
      'quantity': quantity,
      'unitCost': unitCost,
      'discount': discount,
      'tax': tax,
      'receivedQuantity': receivedQuantity,
    };
  }

  PurchaseDetailDto copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    String? productName,
    String? productCode,
    String? unitName,
    double? quantity,
    double? unitCost,
    double? discount,
    double? tax,
    double? receivedQuantity,
  }) {
    return PurchaseDetailDto(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitName: unitName ?? this.unitName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
    );
  }
}
