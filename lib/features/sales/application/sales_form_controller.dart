import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';
import 'package:durvaeco/features/sales/data/repositories/sales_repository.dart';

enum SalesFormStatus { initial, submitting, success, error }

class SalesFormState {
  final int? id;
  final String invoiceNumber;
  final int customerId;
  final int warehouseId;
  final DateTime? saleDate;
  final DateTime? dueDate;
  final String status;
  final String paymentStatus;
  final double transportCharge;
  final String? notes;
  final List<SaleDetailDto> items;
  final SalesFormStatus formStatus;
  final Failure? failure;

  const SalesFormState({
    this.id,
    this.invoiceNumber = '',
    this.customerId = 0,
    this.warehouseId = 0,
    this.saleDate,
    this.dueDate,
    this.status = 'CONFIRMED',
    this.paymentStatus = 'PENDING',
    this.transportCharge = 0.0,
    this.notes,
    this.items = const [],
    this.formStatus = SalesFormStatus.initial,
    this.failure,
  });

  double get itemsSubtotal =>
      items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice - item.discount));
  double get itemsTax => items.fold(0.0, (sum, item) => sum + item.tax);
  double get grandTotal => itemsSubtotal + itemsTax + transportCharge;

  bool get isEditing => id != null && id! > 0;

  SaleDto toDto() {
    return SaleDto(
      id: id ?? 0,
      invoiceNumber: invoiceNumber.trim(),
      customerId: customerId,
      warehouseId: warehouseId,
      saleDate: saleDate ?? DateTime.now(),
      dueDate: dueDate,
      subtotal: itemsSubtotal,
      discount: items.fold(0.0, (sum, item) => sum + item.discount),
      tax: itemsTax,
      transportCharge: transportCharge,
      totalAmount: grandTotal,
      paidAmount: 0.0,
      status: status,
      paymentStatus: paymentStatus,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      items: items,
    );
  }

  SalesFormState copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    int? warehouseId,
    DateTime? saleDate,
    DateTime? dueDate,
    String? status,
    String? paymentStatus,
    double? transportCharge,
    String? notes,
    List<SaleDetailDto>? items,
    SalesFormStatus? formStatus,
    Failure? failure,
  }) {
    return SalesFormState(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      warehouseId: warehouseId ?? this.warehouseId,
      saleDate: saleDate ?? this.saleDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transportCharge: transportCharge ?? this.transportCharge,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      formStatus: formStatus ?? this.formStatus,
      failure: failure ?? this.failure,
    );
  }
}

class SalesFormController extends StateNotifier<SalesFormState> {
  final SalesRepository _repository;
  final Ref _ref;

  SalesFormController(this._repository, this._ref)
      : super(SalesFormState(saleDate: DateTime.now()));

  void initForCreate() {
    state = SalesFormState(saleDate: DateTime.now());
  }

  void initForEdit(SaleDto sale) {
    state = SalesFormState(
      id: sale.id,
      invoiceNumber: sale.invoiceNumber,
      customerId: sale.customerId,
      warehouseId: sale.warehouseId,
      saleDate: sale.saleDate,
      dueDate: sale.dueDate,
      status: sale.status,
      paymentStatus: sale.paymentStatus,
      transportCharge: sale.transportCharge,
      notes: sale.notes,
      items: sale.items,
      formStatus: SalesFormStatus.initial,
    );
  }

  void updateInvoiceNumber(String val) => state = state.copyWith(invoiceNumber: val);
  void updateCustomer(int id) => state = state.copyWith(customerId: id);
  void updateWarehouse(int id) => state = state.copyWith(warehouseId: id);
  void updateSaleDate(DateTime val) => state = state.copyWith(saleDate: val);
  void updateDueDate(DateTime? val) => state = state.copyWith(dueDate: val);
  void updateStatus(String val) => state = state.copyWith(status: val);
  void updateTransportCharge(double val) => state = state.copyWith(transportCharge: val);
  void updateNotes(String val) => state = state.copyWith(notes: val);

  void addItem(SaleDetailDto item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(int index, SaleDetailDto item) {
    if (index >= 0 && index < state.items.length) {
      final updated = List<SaleDetailDto>.from(state.items);
      updated[index] = item;
      state = state.copyWith(items: updated);
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.items.length) {
      final updated = List<SaleDetailDto>.from(state.items)..removeAt(index);
      state = state.copyWith(items: updated);
    }
  }

  Future<bool> submit() async {
    if (state.customerId <= 0 || state.warehouseId <= 0 || state.items.isEmpty) {
      state = state.copyWith(
        formStatus: SalesFormStatus.error,
        failure: const ValidationFailure('Customer, Warehouse, and at least one item are required.'),
      );
      return false;
    }

    state = state.copyWith(formStatus: SalesFormStatus.submitting, failure: null);

    final dto = state.toDto();
    final result = state.isEditing
        ? await _repository.updateSale(state.id!, dto)
        : await _repository.createSale(dto);

    return result.when(
      success: (_) {
        state = state.copyWith(formStatus: SalesFormStatus.success);
        _ref.invalidate(salesListProvider);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(formStatus: SalesFormStatus.error, failure: failure);
        return false;
      },
    );
  }
}

final salesFormControllerProvider =
    StateNotifierProvider.autoDispose<SalesFormController, SalesFormState>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return SalesFormController(repo, ref);
});
