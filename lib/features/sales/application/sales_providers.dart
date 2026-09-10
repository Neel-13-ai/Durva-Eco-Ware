import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';
import 'package:durvaeco/features/sales/data/repositories/customer_payment_repository.dart';
import 'package:durvaeco/features/sales/data/repositories/sales_repository.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return SalesRepository(client);
});

final customerPaymentRepositoryProvider = Provider<CustomerPaymentRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return CustomerPaymentRepository(client);
});

final salesListProvider = FutureProvider.autoDispose<List<SaleDto>>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (sales) => sales,
    failure: (failure) => throw Exception(failure.message),
  );
});

final saleDetailProvider = FutureProvider.autoDispose.family<SaleDto, int>((ref, id) async {
  final repo = ref.watch(salesRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (sale) => sale,
    failure: (failure) => throw Exception(failure.message),
  );
});

final customerPaymentsProvider = FutureProvider.autoDispose.family<List<CustomerPaymentDto>, int?>((ref, customerId) async {
  final repo = ref.watch(customerPaymentRepositoryProvider);
  final result = await repo.getAll(customerId: customerId);
  return result.when(
    success: (payments) => payments,
    failure: (failure) => throw Exception(failure.message),
  );
});

final salePaymentsProvider = FutureProvider.autoDispose.family<List<CustomerPaymentDto>, int>((ref, saleId) async {
  final repo = ref.watch(customerPaymentRepositoryProvider);
  final result = await repo.getAll(saleId: saleId);
  return result.when(
    success: (payments) => payments,
    failure: (failure) => throw Exception(failure.message),
  );
});
