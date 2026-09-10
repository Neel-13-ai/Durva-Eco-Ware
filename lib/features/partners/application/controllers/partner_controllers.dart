import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_dto.dart';
import '../../data/models/payment_method_dto.dart';
import '../../data/models/supplier_dto.dart';
import '../../data/models/transporter_dto.dart';
import '../../data/models/vehicle_dto.dart';
import '../providers/partner_providers.dart';

// --- Supplier Controller ---
class SupplierFormController extends StateNotifier<AsyncValue<void>> {
  SupplierFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(SupplierDto supplier, {bool isEditing = false}) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(supplierRepositoryProvider);
    final result = isEditing
        ? await repo.update(supplier.id, supplier)
        : await repo.create(supplier);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(suppliersListProvider);
        _ref.invalidate(activeSuppliersProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> delete(int id) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(supplierRepositoryProvider);
    final result = await repo.delete(id);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(suppliersListProvider);
        _ref.invalidate(activeSuppliersProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final supplierFormControllerProvider = StateNotifierProvider.autoDispose<
    SupplierFormController, AsyncValue<void>>((ref) {
  return SupplierFormController(ref);
});

// --- Customer Controller ---
class CustomerFormController extends StateNotifier<AsyncValue<void>> {
  CustomerFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(CustomerDto customer, {bool isEditing = false}) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(customerRepositoryProvider);
    final result = isEditing
        ? await repo.update(customer.id, customer)
        : await repo.create(customer);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(customersListProvider);
        _ref.invalidate(activeCustomersProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> delete(int id) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(customerRepositoryProvider);
    final result = await repo.delete(id);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(customersListProvider);
        _ref.invalidate(activeCustomersProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final customerFormControllerProvider = StateNotifierProvider.autoDispose<
    CustomerFormController, AsyncValue<void>>((ref) {
  return CustomerFormController(ref);
});

// --- Transporter Controller ---
class TransporterFormController extends StateNotifier<AsyncValue<void>> {
  TransporterFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(TransporterDto transporter, {bool isEditing = false}) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(transporterRepositoryProvider);
    final result = isEditing
        ? await repo.update(transporter.id, transporter)
        : await repo.create(transporter);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(transportersListProvider);
        _ref.invalidate(activeTransportersProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> delete(int id) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(transporterRepositoryProvider);
    final result = await repo.delete(id);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(transportersListProvider);
        _ref.invalidate(activeTransportersProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final transporterFormControllerProvider = StateNotifierProvider.autoDispose<
    TransporterFormController, AsyncValue<void>>((ref) {
  return TransporterFormController(ref);
});

// --- Vehicle Controller ---
class VehicleFormController extends StateNotifier<AsyncValue<void>> {
  VehicleFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(VehicleDto vehicle, {bool isEditing = false}) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(vehicleRepositoryProvider);
    final result = isEditing
        ? await repo.update(vehicle.id, vehicle)
        : await repo.create(vehicle);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(vehiclesListProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> delete(int id) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(vehicleRepositoryProvider);
    final result = await repo.delete(id);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(vehiclesListProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final vehicleFormControllerProvider = StateNotifierProvider.autoDispose<
    VehicleFormController, AsyncValue<void>>((ref) {
  return VehicleFormController(ref);
});

// --- Payment Method Controller ---
class PaymentMethodFormController extends StateNotifier<AsyncValue<void>> {
  PaymentMethodFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(PaymentMethodDto method, {bool isEditing = false}) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(paymentMethodRepositoryProvider);
    final result = isEditing
        ? await repo.update(method.id, method)
        : await repo.create(method);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(paymentMethodsListProvider);
        _ref.invalidate(activePaymentMethodsProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final paymentMethodFormControllerProvider = StateNotifierProvider.autoDispose<
    PaymentMethodFormController, AsyncValue<void>>((ref) {
  return PaymentMethodFormController(ref);
});
