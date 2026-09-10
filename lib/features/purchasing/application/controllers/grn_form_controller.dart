import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/core/error/failure.dart';
import '../../data/models/goods_receipt_detail_dto.dart';
import '../../data/models/goods_receipt_dto.dart';
import '../../data/models/purchase_dto.dart';
import '../../data/repositories/goods_receipt_repository.dart';
import '../providers/purchase_providers.dart';

class GRNFormState {
  const GRNFormState({
    this.purchaseId = 0,
    this.purchaseNumber = '',
    this.warehouseId = 0,
    this.warehouseName,
    this.supplierName,
    this.receiptDate,
    this.receivedBy,
    this.vehicleNumber,
    this.challanNumber,
    this.items = const [],
    this.isLoading = false,
    this.failure,
  });

  final int purchaseId;
  final String purchaseNumber;
  final int warehouseId;
  final String? warehouseName;
  final String? supplierName;
  final DateTime? receiptDate;
  final String? receivedBy;
  final String? vehicleNumber;
  final String? challanNumber;
  final List<GoodsReceiptDetailDto> items;
  final bool isLoading;
  final Failure? failure;

  double get totalQuantity => items.fold(0.0, (sum, i) => sum + i.acceptedQuantity);
  double get totalAmount => items.fold(0.0, (sum, i) => sum + i.totalCost);

  GoodsReceiptDto toDto() {
    return GoodsReceiptDto(
      id: 0,
      grnNumber: '',
      purchaseId: purchaseId,
      purchaseNumber: purchaseNumber,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      supplierName: supplierName,
      receiptDate: receiptDate ?? DateTime.now(),
      status: GRNStatus.confirmed,
      receivedBy: receivedBy?.trim().isEmpty ?? true ? null : receivedBy!.trim(),
      vehicleNumber: vehicleNumber?.trim().isEmpty ?? true ? null : vehicleNumber!.trim(),
      challanNumber: challanNumber?.trim().isEmpty ?? true ? null : challanNumber!.trim(),
      totalItems: items.length,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
      items: items,
    );
  }

  GRNFormState copyWith({
    int? purchaseId,
    String? purchaseNumber,
    int? warehouseId,
    String? warehouseName,
    String? supplierName,
    DateTime? receiptDate,
    String? receivedBy,
    String? vehicleNumber,
    String? challanNumber,
    List<GoodsReceiptDetailDto>? items,
    bool? isLoading,
    Failure? failure,
  }) {
    return GRNFormState(
      purchaseId: purchaseId ?? this.purchaseId,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      supplierName: supplierName ?? this.supplierName,
      receiptDate: receiptDate ?? this.receiptDate,
      receivedBy: receivedBy ?? this.receivedBy,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      challanNumber: challanNumber ?? this.challanNumber,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      failure: failure ?? this.failure,
    );
  }
}

class GRNFormController extends StateNotifier<GRNFormState> {
  GRNFormController(this._repo, this._ref) : super(GRNFormState(receiptDate: DateTime.now()));

  final GoodsReceiptRepository _repo;
  final Ref _ref;

  void initializeFromPurchase(PurchaseDto po) {
    final grnItems = po.items.map((line) {
      final pending = line.pendingQuantity > 0 ? line.pendingQuantity : line.quantity;
      return GoodsReceiptDetailDto(
        id: 0,
        grnId: 0,
        productId: line.productId,
        productName: line.productName,
        productCode: line.productCode,
        unitName: line.unitName,
        orderedQuantity: line.quantity,
        receivedQuantity: pending,
        rejectedQuantity: 0.0,
        unitCost: line.unitCost,
      );
    }).toList();

    state = GRNFormState(
      purchaseId: po.id,
      purchaseNumber: po.purchaseNumber,
      warehouseId: po.warehouseId,
      warehouseName: po.warehouseName,
      supplierName: po.supplierName,
      receiptDate: DateTime.now(),
      items: grnItems,
    );
  }

  void updateLineQty(int index, {double? received, double? rejected, String? batchNo}) {
    final updated = List<GoodsReceiptDetailDto>.from(state.items);
    if (index >= 0 && index < updated.length) {
      final current = updated[index];
      updated[index] = current.copyWith(
        receivedQuantity: received ?? current.receivedQuantity,
        rejectedQuantity: rejected ?? current.rejectedQuantity,
        batchNumber: batchNo ?? current.batchNumber,
      );
      state = state.copyWith(items: updated);
    }
  }

  void setReceivedBy(String val) => state = state.copyWith(receivedBy: val);
  void setVehicleNumber(String val) => state = state.copyWith(vehicleNumber: val);
  void setChallanNumber(String val) => state = state.copyWith(challanNumber: val);

  Future<bool> submit() async {
    state = state.copyWith(isLoading: true, failure: null);
    final dto = state.toDto();

    final result = await _repo.create(dto);
    return result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
        _ref.invalidate(goodsReceiptsListProvider);
        _ref.invalidate(purchasesListProvider);
        return true;
      },
      failure: (f) {
        state = state.copyWith(isLoading: false, failure: f);
        return false;
      },
    );
  }
}

final grnFormControllerProvider = StateNotifierProvider.autoDispose<
    GRNFormController, GRNFormState>((ref) {
  final repo = ref.watch(goodsReceiptRepositoryProvider);
  return GRNFormController(repo, ref);
});
