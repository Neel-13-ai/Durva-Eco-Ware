import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/masters/data/models/category_dto.dart';
import 'package:durvaeco/features/masters/data/models/document_sequence_dto.dart';
import 'package:durvaeco/features/masters/data/models/unit_dto.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';

// --- Category Controller ---
class CategoryFormController extends StateNotifier<AsyncValue<void>> {
  CategoryFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(CategoryDto category, {bool isEditing = false}) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(categoryRepositoryProvider);
    final result = isEditing
        ? await repo.update(category.id, category)
        : await repo.create(category);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(categoriesListProvider);
        _ref.invalidate(activeCategoriesProvider);
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
    final repo = _ref.read(categoryRepositoryProvider);
    final result = await repo.delete(id);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(categoriesListProvider);
        _ref.invalidate(activeCategoriesProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final categoryFormControllerProvider = StateNotifierProvider.autoDispose<
    CategoryFormController, AsyncValue<void>>((ref) {
  return CategoryFormController(ref);
});

// --- Unit Controller ---
class UnitFormController extends StateNotifier<AsyncValue<void>> {
  UnitFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(UnitDto unit, {bool isEditing = false}) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(unitRepositoryProvider);
    final result = isEditing
        ? await repo.update(unit.id, unit)
        : await repo.create(unit);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(unitsListProvider);
        _ref.invalidate(activeUnitsProvider);
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
    final repo = _ref.read(unitRepositoryProvider);
    final result = await repo.delete(id);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(unitsListProvider);
        _ref.invalidate(activeUnitsProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final unitFormControllerProvider = StateNotifierProvider.autoDispose<
    UnitFormController, AsyncValue<void>>((ref) {
  return UnitFormController(ref);
});

// --- Warehouse Controller ---
class WarehouseFormController extends StateNotifier<AsyncValue<void>> {
  WarehouseFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(WarehouseDto warehouse, {bool isEditing = false}) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(warehouseRepositoryProvider);
    final result = isEditing
        ? await repo.update(warehouse.id, warehouse)
        : await repo.create(warehouse);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(warehousesListProvider);
        _ref.invalidate(activeWarehousesProvider);
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
    final repo = _ref.read(warehouseRepositoryProvider);
    final result = await repo.delete(id);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(warehousesListProvider);
        _ref.invalidate(activeWarehousesProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final warehouseFormControllerProvider = StateNotifierProvider.autoDispose<
    WarehouseFormController, AsyncValue<void>>((ref) {
  return WarehouseFormController(ref);
});

// --- Sequence Controller ---
class SequenceFormController extends StateNotifier<AsyncValue<void>> {
  SequenceFormController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(DocumentSequenceDto seq) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(sequenceRepositoryProvider);
    final result = await repo.update(seq.id, seq);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(sequencesListProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final sequenceFormControllerProvider = StateNotifierProvider.autoDispose<
    SequenceFormController, AsyncValue<void>>((ref) {
  return SequenceFormController(ref);
});
