import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/dispatch/data/models/delivery_dto.dart';
import 'package:durvaeco/features/dispatch/data/repositories/delivery_repository.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return DeliveryRepository(client);
});

final deliveryListProvider = FutureProvider.autoDispose<List<DeliveryDto>>((ref) async {
  final repo = ref.watch(deliveryRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (deliveries) => deliveries,
    failure: (failure) => throw Exception(failure.message),
  );
});

final deliveryDetailProvider = FutureProvider.autoDispose.family<DeliveryDto, int>((ref, id) async {
  final repo = ref.watch(deliveryRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (delivery) => delivery,
    failure: (failure) => throw Exception(failure.message),
  );
});

/// Pending dispatch queue: Confirmed sales orders that still need outward delivery
final pendingDispatchQueueProvider = FutureProvider.autoDispose<List<SaleDto>>((ref) async {
  final salesList = await ref.watch(salesListProvider.future);
  final deliveriesList = await ref.watch(deliveryListProvider.future);

  final completedSaleIds = deliveriesList
      .where((d) => d.status == 'DELIVERED' || d.status == 'DISPATCHED')
      .map((d) => d.saleId)
      .toSet();

  return salesList
      .where((s) => s.status == 'CONFIRMED' && !completedSaleIds.contains(s.id))
      .toList();
});
