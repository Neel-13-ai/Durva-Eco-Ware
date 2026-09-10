enum AdjustmentMode {
  increase,
  decrease,
  recount;

  String toApiValue() {
    switch (this) {
      case AdjustmentMode.increase:
        return 'INCREASE';
      case AdjustmentMode.decrease:
        return 'DECREASE';
      case AdjustmentMode.recount:
        return 'RECOUNT';
    }
  }
}

class StockAdjustmentRequest {
  const StockAdjustmentRequest({
    required this.productId,
    required this.warehouseId,
    required this.mode,
    required this.quantity,
    required this.reason,
    this.unitCost = 0.0,
    this.notes,
  });

  final int productId;
  final int warehouseId;
  final AdjustmentMode mode;
  final double quantity;
  final String reason;
  final double unitCost;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'warehouseId': warehouseId,
      'mode': mode.toApiValue(),
      'quantity': quantity,
      'reason': reason,
      'unitCost': unitCost,
      if (notes != null) 'notes': notes,
    };
  }
}
