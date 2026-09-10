import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/production/data/models/production_stage_entry_dto.dart';
import 'package:durvaeco/features/production/data/models/production_material_issue_dto.dart';
import 'package:durvaeco/features/production/data/models/production_output_dto.dart';
import 'package:durvaeco/features/production/data/models/quality_check_dto.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';

class ProductionExecutionController extends StateNotifier<AsyncValue<void>> {
  ProductionExecutionController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> startProduction(int orderId) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(productionRepositoryProvider);
    final result = await repo.updateStatus(orderId, ProductionStatus.inProgress);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(productionOrderDetailProvider(orderId));
        _ref.invalidate(productionOrdersListProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> issueMaterial(ProductionMaterialIssueDto issue) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(productionRepositoryProvider);
    final result = await repo.issueMaterial(issue);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(productionOrderDetailProvider(issue.productionOrderId));
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> startStage(ProductionStageEntryDto entry) async {
    state = const AsyncValue.loading();
    final updated = entry.copyWith(
      status: StageStatus.inProgress,
      startTime: DateTime.now(),
    );
    final repo = _ref.read(productionRepositoryProvider);
    final result = await repo.updateStageEntry(updated);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(productionOrderDetailProvider(entry.productionOrderId));
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> completeStage(ProductionStageEntryDto entry, {String? remarks}) async {
    state = const AsyncValue.loading();
    final updated = entry.copyWith(
      status: StageStatus.completed,
      endTime: DateTime.now(),
      remarks: remarks ?? entry.remarks,
    );
    final repo = _ref.read(productionRepositoryProvider);
    final result = await repo.updateStageEntry(updated);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(productionOrderDetailProvider(entry.productionOrderId));
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> recordQC(QualityCheckDto qc) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(qualityCheckRepositoryProvider);
    final result = await repo.create(qc);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(productionOrderDetailProvider(qc.productionOrderId));
        _ref.invalidate(qualityChecksListProvider(qc.productionOrderId));
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> recordOutput(ProductionOutputDto output) async {
    if (!output.isBalanced) {
      state = const AsyncValue.error('Produced Quantity must equal Good Quantity + Reject Quantity', StackTrace.empty);
      return false;
    }

    state = const AsyncValue.loading();
    final repo = _ref.read(productionRepositoryProvider);
    final result = await repo.recordOutput(output);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(productionOrderDetailProvider(output.productionOrderId));
        _ref.invalidate(productionOrdersListProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> completeProduction(int orderId) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(productionRepositoryProvider);
    final result = await repo.updateStatus(orderId, ProductionStatus.completed);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(productionOrderDetailProvider(orderId));
        _ref.invalidate(productionOrdersListProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final productionExecutionControllerProvider = StateNotifierProvider.autoDispose<
    ProductionExecutionController, AsyncValue<void>>((ref) {
  return ProductionExecutionController(ref);
});
