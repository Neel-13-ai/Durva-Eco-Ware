import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/production/bom/data/models/bom_header_dto.dart';
import 'package:durvaeco/features/production/bom/data/repositories/bom_repository.dart';

final bomRepositoryProvider = Provider<BomRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return BomRepository(client);
});

final bomsListProvider = FutureProvider<List<BomHeaderDto>>((ref) async {
  final repo = ref.watch(bomRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (list) => list,
    failure: (f) => throw Exception(f.message),
  );
});

final bomDetailProvider = FutureProvider.family<BomHeaderDto?, int>((ref, id) async {
  final repo = ref.watch(bomRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (bom) => bom,
    failure: (f) => throw Exception(f.message),
  );
});

/// Family provider resolving the currently effective active BOM recipe for a finished good
final activeBomByProductProvider = FutureProvider.family<BomHeaderDto?, int>((ref, productId) async {
  final repo = ref.watch(bomRepositoryProvider);
  final result = await repo.getAll(finishedProductId: productId);
  return result.when(
    success: (list) {
      final now = DateTime.now();
      return list.where((b) {
        final afterStart = b.effectiveFrom.isBefore(now) || b.effectiveFrom.isAtSameMomentAs(now);
        final beforeEnd = b.effectiveTo == null || b.effectiveTo!.isAfter(now);
        return b.finishedProductId == productId && b.isActive && afterStart && beforeEnd;
      }).firstOrNull;
    },
    failure: (f) => null,
  );
});
