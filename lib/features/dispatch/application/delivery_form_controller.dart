import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/features/dispatch/application/dispatch_providers.dart';
import 'package:durvaeco/features/dispatch/data/models/delivery_dto.dart';
import 'package:durvaeco/features/dispatch/data/repositories/delivery_repository.dart';
import 'package:durvaeco/features/partners/data/models/vehicle_dto.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';

enum DeliveryFormStatus { initial, submitting, success, error }

class DeliveryFormState {
  final int? id;
  final String deliveryNumber;
  final int saleId;
  final int customerId;
  final int? transporterId;
  final int? vehicleId;
  final String? driverName;
  final String? driverPhone;
  final String? trackingNumber;
  final String? deliveryAddress;
  final double freightAmount;
  final DateTime? deliveryDate;
  final DateTime? dispatchDate;
  final DateTime? deliveredDate;
  final String status;
  final String? notes;
  final List<DeliveryDetailDto> items;
  final DeliveryFormStatus formStatus;
  final Failure? failure;

  const DeliveryFormState({
    this.id,
    this.deliveryNumber = '',
    this.saleId = 0,
    this.customerId = 0,
    this.transporterId,
    this.vehicleId,
    this.driverName,
    this.driverPhone,
    this.trackingNumber,
    this.deliveryAddress,
    this.freightAmount = 0.0,
    this.deliveryDate,
    this.dispatchDate,
    this.deliveredDate,
    this.status = 'DRAFT',
    this.notes,
    this.items = const [],
    this.formStatus = DeliveryFormStatus.initial,
    this.failure,
  });

  bool get isEditing => id != null && id! > 0;
  double get totalDispatchedUnits => items.fold(0.0, (sum, i) => sum + i.quantity);

  DeliveryDto toDto() {
    return DeliveryDto(
      id: id ?? 0,
      deliveryNumber: deliveryNumber.trim(),
      saleId: saleId,
      customerId: customerId,
      transporterId: transporterId,
      vehicleId: vehicleId,
      driverName: driverName?.trim().isEmpty == true ? null : driverName?.trim(),
      driverPhone: driverPhone?.trim().isEmpty == true ? null : driverPhone?.trim(),
      trackingNumber: trackingNumber?.trim().isEmpty == true ? null : trackingNumber?.trim(),
      deliveryAddress: deliveryAddress?.trim().isEmpty == true ? null : deliveryAddress?.trim(),
      freightAmount: freightAmount,
      deliveryDate: deliveryDate ?? DateTime.now(),
      dispatchDate: dispatchDate,
      deliveredDate: deliveredDate,
      status: status,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      items: items,
    );
  }

  DeliveryFormState copyWith({
    int? id,
    String? deliveryNumber,
    int? saleId,
    int? customerId,
    int? transporterId,
    int? vehicleId,
    String? driverName,
    String? driverPhone,
    String? trackingNumber,
    String? deliveryAddress,
    double? freightAmount,
    DateTime? deliveryDate,
    DateTime? dispatchDate,
    DateTime? deliveredDate,
    String? status,
    String? notes,
    List<DeliveryDetailDto>? items,
    DeliveryFormStatus? formStatus,
    Failure? failure,
  }) {
    return DeliveryFormState(
      id: id ?? this.id,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      saleId: saleId ?? this.saleId,
      customerId: customerId ?? this.customerId,
      transporterId: transporterId ?? this.transporterId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      freightAmount: freightAmount ?? this.freightAmount,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      dispatchDate: dispatchDate ?? this.dispatchDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      formStatus: formStatus ?? this.formStatus,
      failure: failure ?? this.failure,
    );
  }
}

class DeliveryFormController extends StateNotifier<DeliveryFormState> {
  final DeliveryRepository _repository;
  final Ref _ref;

  DeliveryFormController(this._repository, this._ref)
      : super(DeliveryFormState(
          deliveryDate: DateTime.now(),
          deliveryNumber: 'DEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        ));

  void initForCreate() {
    state = DeliveryFormState(
      deliveryDate: DateTime.now(),
      deliveryNumber: 'DEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
  }

  void initFromSale(SaleDto sale) {
    final deliveryItems = sale.items
        .map((i) => DeliveryDetailDto(
              id: 0,
              deliveryId: 0,
              saleDetailId: i.id,
              productId: i.productId,
              productName: i.productName,
              quantity: i.quantity,
            ))
        .toList();

    state = DeliveryFormState(
      deliveryNumber: 'DEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      saleId: sale.id,
      customerId: sale.customerId,
      deliveryDate: DateTime.now(),
      items: deliveryItems,
      freightAmount: sale.transportCharge,
      notes: 'Fulfillment for Invoice ${sale.invoiceNumber}',
    );
  }

  void initForEdit(DeliveryDto delivery) {
    state = DeliveryFormState(
      id: delivery.id,
      deliveryNumber: delivery.deliveryNumber,
      saleId: delivery.saleId,
      customerId: delivery.customerId,
      transporterId: delivery.transporterId,
      vehicleId: delivery.vehicleId,
      driverName: delivery.driverName,
      driverPhone: delivery.driverPhone,
      trackingNumber: delivery.trackingNumber,
      deliveryAddress: delivery.deliveryAddress,
      freightAmount: delivery.freightAmount,
      deliveryDate: delivery.deliveryDate,
      dispatchDate: delivery.dispatchDate,
      deliveredDate: delivery.deliveredDate,
      status: delivery.status,
      notes: delivery.notes,
      items: delivery.items,
      formStatus: DeliveryFormStatus.initial,
    );
  }

  void updateDeliveryNumber(String val) => state = state.copyWith(deliveryNumber: val);
  void updateSaleId(int id) => state = state.copyWith(saleId: id);
  void updateCustomerId(int id) => state = state.copyWith(customerId: id);
  void updateTransporterId(int? id) => state = state.copyWith(transporterId: id);

  void updateVehicle(VehicleDto vehicle) {
    state = state.copyWith(
      vehicleId: vehicle.id,
      driverName: vehicle.driverName ?? state.driverName,
      driverPhone: vehicle.driverPhone ?? state.driverPhone,
    );
  }

  void updateDriverName(String val) => state = state.copyWith(driverName: val);
  void updateDriverPhone(String val) => state = state.copyWith(driverPhone: val);
  void updateTrackingNumber(String val) => state = state.copyWith(trackingNumber: val);
  void updateDeliveryAddress(String val) => state = state.copyWith(deliveryAddress: val);
  void updateFreightAmount(double val) => state = state.copyWith(freightAmount: val);
  void updateStatus(String val) => state = state.copyWith(status: val);
  void updateNotes(String val) => state = state.copyWith(notes: val);

  void updateItemQuantity(int index, double quantity) {
    if (index >= 0 && index < state.items.length) {
      final updated = List<DeliveryDetailDto>.from(state.items);
      final current = updated[index];
      updated[index] = DeliveryDetailDto(
        id: current.id,
        deliveryId: current.deliveryId,
        saleDetailId: current.saleDetailId,
        productId: current.productId,
        productName: current.productName,
        quantity: quantity,
        notes: current.notes,
      );
      state = state.copyWith(items: updated);
    }
  }

  Future<bool> submit() async {
    if (state.saleId <= 0 || state.customerId <= 0 || state.items.isEmpty) {
      state = state.copyWith(
        formStatus: DeliveryFormStatus.error,
        failure: const ValidationFailure('Sales Order, Customer, and line items are required.'),
      );
      return false;
    }

    state = state.copyWith(formStatus: DeliveryFormStatus.submitting, failure: null);

    final dto = state.toDto();
    final result = state.isEditing
        ? await _repository.updateDelivery(state.id!, dto)
        : await _repository.createDelivery(dto);

    return result.when(
      success: (_) {
        state = state.copyWith(formStatus: DeliveryFormStatus.success);
        _ref.invalidate(deliveryListProvider);
        _ref.invalidate(pendingDispatchQueueProvider);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(formStatus: DeliveryFormStatus.error, failure: failure);
        return false;
      },
    );
  }
}

final deliveryFormControllerProvider =
    StateNotifierProvider.autoDispose<DeliveryFormController, DeliveryFormState>((ref) {
  final repo = ref.watch(deliveryRepositoryProvider);
  return DeliveryFormController(repo, ref);
});
