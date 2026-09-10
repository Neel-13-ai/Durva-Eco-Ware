import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/core/error/failure.dart';
import '../../data/models/purchase_detail_dto.dart';
import '../../data/models/purchase_dto.dart';
import '../../data/repositories/purchase_repository.dart';
import '../providers/purchase_providers.dart';

enum PurchaseFormStatus { initial, submitting, success, error }

class PurchaseFormState {
  const PurchaseFormState({
    this.id,
    this.purchaseNumber = '',
    this.supplierId = 0,
    this.warehouseId = 0,
    this.purchaseDate,
    this.expectedDeliveryDate,
    this.status = PurchaseStatus.draft,
    this.transportCost = 0.0,
    this.otherCost = 0.0,
    this.referenceNo,
    this.notes,
    this.items = const [],
    this.formStatus = PurchaseFormStatus.initial,
    this.failure,
  });

  final int? id;
  final String purchaseNumber;
  final int supplierId;
  final int warehouseId;
  final DateTime? purchaseDate;
  final DateTime? expectedDeliveryDate;
  final PurchaseStatus status;
  final double transportCost;
  final double otherCost;
  final String? referenceNo;
  final String? notes;
  final List<PurchaseDetailDto> items;
  final PurchaseFormStatus formStatus;
  final Failure? failure;

  double get subtotal => items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitCost - item.discount));
  double get totalTax => items.fold(0.0, (sum, item) => sum + item.tax);
  double get grandTotal => subtotal + totalTax + transportCost + otherCost;

  bool get isEditing => id != null && id! > 0;

  PurchaseDto toDto() {
    return PurchaseDto(
      id: id ?? 0,
      purchaseNumber: purchaseNumber.trim(),
      supplierId: supplierId,
      warehouseId: warehouseId,
      purchaseDate: purchaseDate ?? DateTime.now(),
      expectedDeliveryDate: expectedDeliveryDate,
      status: status,
      subtotal: subtotal,
      taxAmount: totalTax,
      transportCost: transportCost,
      otherCost: otherCost,
      totalAmount: grandTotal,
      referenceNo: referenceNo?.trim().isEmpty ?? true ? null : referenceNo!.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      items: items,
    );
  }

  PurchaseFormState copyWith({
    int? id,
    String? purchaseNumber,
    int? supplierId,
    int? warehouseId,
    DateTime? purchaseDate,
    DateTime? expectedDeliveryDate,
    PurchaseStatus? status,
    double? transportCost,
    double? otherCost,
    String? referenceNo,
    String? notes,
    List<PurchaseDetailDto>? items,
    PurchaseFormStatus? formStatus,
    Failure? failure,
  }) {
    return PurchaseFormState(
      id: id ?? this.id,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      supplierId: supplierId ?? this.supplierId,
      warehouseId: warehouseId ?? this.warehouseId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      status: status ?? this.status,
      transportCost: transportCost ?? this.transportCost,
      otherCost: otherCost ?? this.otherCost,
      referenceNo: referenceNo ?? this.referenceNo,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      formStatus: formStatus ?? this.formStatus,
      failure: failure ?? this.failure,
    );
  }
}

class PurchaseFormController extends StateNotifier<PurchaseFormState> {
  PurchaseFormController(this._repo, this._ref) : super(PurchaseFormState(purchaseDate: DateTime.now()));

  final PurchaseRepository _repo;
  final Ref _ref;

  void initialize(PurchaseDto? purchase) {
    if (purchase != null) {
      state = PurchaseFormState(
        id: purchase.id,
        purchaseNumber: purchase.purchaseNumber,
        supplierId: purchase.supplierId,
        warehouseId: purchase.warehouseId,
        purchaseDate: purchase.purchaseDate,
        expectedDeliveryDate: purchase.expectedDeliveryDate,
        status: purchase.status,
        transportCost: purchase.transportCost,
        otherCost: purchase.otherCost,
        referenceNo: purchase.referenceNo,
        notes: purchase.notes,
        items: List.from(purchase.items),
      );
    } else {
      state = PurchaseFormState(purchaseDate: DateTime.now());
    }
  }

  void setSupplierId(int val) => state = state.copyWith(supplierId: val);
  void setWarehouseId(int val) => state = state.copyWith(warehouseId: val);
  void setPurchaseDate(DateTime val) => state = state.copyWith(purchaseDate: val);
  void setExpectedDeliveryDate(DateTime? val) => state = state.copyWith(expectedDeliveryDate: val);
  void setStatus(PurchaseStatus val) => state = state.copyWith(status: val);
  void setTransportCost(double val) => state = state.copyWith(transportCost: val);
  void setOtherCost(double val) => state = state.copyWith(otherCost: val);
  void setReferenceNo(String? val) => state = state.copyWith(referenceNo: val);
  void setNotes(String? val) => state = state.copyWith(notes: val);

  void addItem(PurchaseDetailDto item) {
    final updated = List<PurchaseDetailDto>.from(state.items)..add(item);
    state = state.copyWith(items: updated);
  }

  void updateItem(int index, PurchaseDetailDto item) {
    final updated = List<PurchaseDetailDto>.from(state.items);
    if (index >= 0 && index < updated.length) {
      updated[index] = item;
      state = state.copyWith(items: updated);
    }
  }

  void removeItem(int index) {
    final updated = List<PurchaseDetailDto>.from(state.items);
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
      state = state.copyWith(items: updated);
    }
  }

  Future<bool> submit() async {
    if (state.supplierId <= 0 || state.warehouseId <= 0) {
      state = state.copyWith(
        formStatus: PurchaseFormStatus.error,
        failure: const ValidationFailure('Supplier and Warehouse are required'),
      );
      return false;
    }

    if (state.items.isEmpty) {
      state = state.copyWith(
        formStatus: PurchaseFormStatus.error,
        failure: const ValidationFailure('At least one item is required in the Purchase Order'),
      );
      return false;
    }

    state = state.copyWith(formStatus: PurchaseFormStatus.submitting, failure: null);
    final dto = state.toDto();

    final result = state.isEditing
        ? await _repo.update(state.id!, dto)
        : await _repo.create(dto);

    return result.when(
      success: (_) {
        state = state.copyWith(formStatus: PurchaseFormStatus.success);
        _ref.invalidate(purchasesListProvider);
        return true;
      },
      failure: (f) {
        state = state.copyWith(formStatus: PurchaseFormStatus.error, failure: f);
        return false;
      },
    );
  }
}

final purchaseFormControllerProvider = StateNotifierProvider.autoDispose<
    PurchaseFormController, PurchaseFormState>((ref) {
  final repo = ref.watch(purchaseRepositoryProvider);
  return PurchaseFormController(repo, ref);
});
