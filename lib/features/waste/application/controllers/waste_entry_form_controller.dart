import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/waste/data/models/waste_entry_dto.dart';
import 'package:durvaeco/features/waste/application/providers/waste_providers.dart';
import 'package:durvaeco/features/inventory/application/providers/inventory_providers.dart';

enum WasteFormStatus { initial, submitting, success, error }

class WasteFormState {
  const WasteFormState({
    this.wasteNumber = '',
    required this.wasteDate,
    this.warehouseId = 0,
    this.productId = 0,
    this.productName,
    this.wasteReasonId = 0,
    this.quantity = 1.0,
    this.unitCost = 0.0,
    this.disposalMethod = DisposalMethod.recycled,
    this.productionOrderId,
    this.batchNo,
    this.notes,
    this.formStatus = WasteFormStatus.initial,
    this.errorMessage,
  });

  final String wasteNumber;
  final DateTime wasteDate;
  final int warehouseId;
  final int productId;
  final String? productName;
  final int wasteReasonId;
  final double quantity;
  final double unitCost;
  final DisposalMethod disposalMethod;
  final int? productionOrderId;
  final String? batchNo;
  final String? notes;
  final WasteFormStatus formStatus;
  final String? errorMessage;

  double get totalLossAmount => quantity * unitCost;

  WasteFormState copyWith({
    String? wasteNumber,
    DateTime? wasteDate,
    int? warehouseId,
    int? productId,
    String? productName,
    int? wasteReasonId,
    double? quantity,
    double? unitCost,
    DisposalMethod? disposalMethod,
    int? productionOrderId,
    String? batchNo,
    String? notes,
    WasteFormStatus? formStatus,
    String? errorMessage,
  }) {
    return WasteFormState(
      wasteNumber: wasteNumber ?? this.wasteNumber,
      wasteDate: wasteDate ?? this.wasteDate,
      warehouseId: warehouseId ?? this.warehouseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      wasteReasonId: wasteReasonId ?? this.wasteReasonId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      disposalMethod: disposalMethod ?? this.disposalMethod,
      productionOrderId: productionOrderId ?? this.productionOrderId,
      batchNo: batchNo ?? this.batchNo,
      notes: notes ?? this.notes,
      formStatus: formStatus ?? this.formStatus,
      errorMessage: errorMessage,
    );
  }
}

class WasteEntryFormController extends StateNotifier<WasteFormState> {
  WasteEntryFormController(this._ref)
      : super(WasteFormState(
          wasteDate: DateTime.now(),
          wasteNumber: 'WST-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
        ));

  final Ref _ref;

  void initialize() {
    state = WasteFormState(
      wasteDate: DateTime.now(),
      wasteNumber: 'WST-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
  }

  void setWarehouseId(int id) => state = state.copyWith(warehouseId: id);
  void setProduct(int id, String name, double cost) => state = state.copyWith(productId: id, productName: name, unitCost: cost);
  void setWasteReasonId(int id) => state = state.copyWith(wasteReasonId: id);
  void setQuantity(double qty) => state = state.copyWith(quantity: qty);
  void setUnitCost(double cost) => state = state.copyWith(unitCost: cost);
  void setDisposalMethod(DisposalMethod method) => state = state.copyWith(disposalMethod: method);
  void setBatchNo(String? batch) => state = state.copyWith(batchNo: batch);
  void setProductionOrderId(int? orderId) => state = state.copyWith(productionOrderId: orderId);
  void setNotes(String? notes) => state = state.copyWith(notes: notes);

  Future<bool> submit() async {
    if (state.productId <= 0) {
      state = state.copyWith(formStatus: WasteFormStatus.error, errorMessage: 'Material/Product is required');
      return false;
    }
    if (state.warehouseId <= 0) {
      state = state.copyWith(formStatus: WasteFormStatus.error, errorMessage: 'Warehouse is required');
      return false;
    }
    if (state.wasteReasonId <= 0) {
      state = state.copyWith(formStatus: WasteFormStatus.error, errorMessage: 'Waste reason is required');
      return false;
    }
    if (state.quantity <= 0) {
      state = state.copyWith(formStatus: WasteFormStatus.error, errorMessage: 'Quantity must be > 0');
      return false;
    }

    state = state.copyWith(formStatus: WasteFormStatus.submitting);

    final entry = WasteEntryDto(
      id: 0,
      wasteNumber: state.wasteNumber,
      wasteDate: state.wasteDate,
      warehouseId: state.warehouseId,
      productId: state.productId,
      productName: state.productName,
      wasteReasonId: state.wasteReasonId,
      quantity: state.quantity,
      unitCost: state.unitCost,
      productionOrderId: state.productionOrderId,
      batchNo: state.batchNo,
      disposalMethod: state.disposalMethod,
      notes: state.notes,
    );

    final repo = _ref.read(wasteRepositoryProvider);
    final result = await repo.createEntry(entry);

    return result.when(
      success: (_) {
        state = state.copyWith(formStatus: WasteFormStatus.success);
        _ref.invalidate(wasteEntriesListProvider);
        _ref.invalidate(stockBalancesListProvider);
        return true;
      },
      failure: (f) {
        state = state.copyWith(formStatus: WasteFormStatus.error, errorMessage: f.message);
        return false;
      },
    );
  }
}

final wasteEntryFormControllerProvider = StateNotifierProvider.autoDispose<
    WasteEntryFormController, WasteFormState>((ref) {
  return WasteEntryFormController(ref);
});
