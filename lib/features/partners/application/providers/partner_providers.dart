import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../../data/models/customer_dto.dart';
import '../../data/models/payment_method_dto.dart';
import '../../data/models/supplier_dto.dart';
import '../../data/models/transporter_dto.dart';
import '../../data/models/vehicle_dto.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/payment_method_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../data/repositories/transporter_repository.dart';
import '../../data/repositories/vehicle_repository.dart';

// --- Repositories ---
final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return SupplierRepository(client);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return CustomerRepository(client);
});

final transporterRepositoryProvider = Provider<TransporterRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return TransporterRepository(client);
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return VehicleRepository(client);
});

final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return PaymentMethodRepository(client);
});

// --- Filter State ---
final partnerSearchQueryProvider = StateProvider<String>((ref) => '');

// --- List & Lookup Future Providers ---
final suppliersListProvider = FutureProvider.autoDispose<List<SupplierDto>>((ref) async {
  final repo = ref.watch(supplierRepositoryProvider);
  final search = ref.watch(partnerSearchQueryProvider);
  final result = await repo.getAll(search: search);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final activeSuppliersProvider = FutureProvider<List<SupplierDto>>((ref) async {
  final repo = ref.watch(supplierRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data.where((s) => s.isActive).toList(),
    failure: (f) => [],
  );
});

final customersListProvider = FutureProvider.autoDispose<List<CustomerDto>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final search = ref.watch(partnerSearchQueryProvider);
  final result = await repo.getAll(search: search);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final activeCustomersProvider = FutureProvider<List<CustomerDto>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data.where((c) => c.isActive).toList(),
    failure: (f) => [],
  );
});

final transportersListProvider = FutureProvider.autoDispose<List<TransporterDto>>((ref) async {
  final repo = ref.watch(transporterRepositoryProvider);
  final search = ref.watch(partnerSearchQueryProvider);
  final result = await repo.getAll(search: search);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final activeTransportersProvider = FutureProvider<List<TransporterDto>>((ref) async {
  final repo = ref.watch(transporterRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data.where((t) => t.isActive).toList(),
    failure: (f) => [],
  );
});

final vehiclesListProvider = FutureProvider.autoDispose<List<VehicleDto>>((ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final vehiclesByTransporterProvider = FutureProvider.family.autoDispose<List<VehicleDto>, int>((ref, transporterId) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  final result = await repo.getByTransporter(transporterId);
  return result.when(
    success: (data) => data.where((v) => v.isActive).toList(),
    failure: (f) => [],
  );
});

final paymentMethodsListProvider = FutureProvider.autoDispose<List<PaymentMethodDto>>((ref) async {
  final repo = ref.watch(paymentMethodRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final activePaymentMethodsProvider = FutureProvider<List<PaymentMethodDto>>((ref) async {
  final repo = ref.watch(paymentMethodRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data.where((p) => p.isActive).toList(),
    failure: (f) => [],
  );
});
