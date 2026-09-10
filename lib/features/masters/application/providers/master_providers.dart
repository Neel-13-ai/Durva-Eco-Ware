import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/masters/data/models/category_dto.dart';
import 'package:durvaeco/features/masters/data/models/document_sequence_dto.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/features/masters/data/models/unit_dto.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';
import 'package:durvaeco/features/masters/data/repositories/category_repository.dart';
import 'package:durvaeco/features/masters/data/repositories/product_repository.dart';
import 'package:durvaeco/features/masters/data/repositories/sequence_repository.dart';
import 'package:durvaeco/features/masters/data/repositories/unit_repository.dart';
import 'package:durvaeco/features/masters/data/repositories/warehouse_repository.dart';

// --- Repositories ---
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return CategoryRepository(client);
});

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return UnitRepository(client);
});

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return WarehouseRepository(client);
});

final sequenceRepositoryProvider = Provider<SequenceRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return SequenceRepository(client);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return ProductRepository(client);
});

// --- Filter State Providers ---
final productSearchQueryProvider = StateProvider<String>((ref) => '');
final productSelectedCategoryProvider = StateProvider<int?>((ref) => null);
final productSelectedTypeProvider = StateProvider<ProductType?>((ref) => null);

// --- List & Lookup Future Providers ---
final categoriesListProvider = FutureProvider.autoDispose<List<CategoryDto>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final activeCategoriesProvider = FutureProvider<List<CategoryDto>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data.where((c) => c.isActive).toList(),
    failure: (f) => [],
  );
});

final unitsListProvider = FutureProvider.autoDispose<List<UnitDto>>((ref) async {
  final repo = ref.watch(unitRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final activeUnitsProvider = FutureProvider<List<UnitDto>>((ref) async {
  final repo = ref.watch(unitRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data.where((u) => u.isActive).toList(),
    failure: (f) => [],
  );
});

final warehousesListProvider = FutureProvider.autoDispose<List<WarehouseDto>>((ref) async {
  final repo = ref.watch(warehouseRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final activeWarehousesProvider = FutureProvider<List<WarehouseDto>>((ref) async {
  final repo = ref.watch(warehouseRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data.where((w) => w.isActive).toList(),
    failure: (f) => [],
  );
});

final sequencesListProvider = FutureProvider.autoDispose<List<DocumentSequenceDto>>((ref) async {
  final repo = ref.watch(sequenceRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final productsListProvider = FutureProvider.autoDispose<List<ProductDto>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final search = ref.watch(productSearchQueryProvider);
  final categoryId = ref.watch(productSelectedCategoryProvider);
  final productType = ref.watch(productSelectedTypeProvider);

  final result = await repo.getAll(
    search: search,
    categoryId: categoryId,
    productType: productType,
  );
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final productDetailProvider = FutureProvider.family.autoDispose<ProductDto, int>((ref, id) async {
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});
