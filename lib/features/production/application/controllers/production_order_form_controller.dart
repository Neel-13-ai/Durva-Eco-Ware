import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/production/data/models/production_material_issue_dto.dart';
import 'package:durvaeco/features/production/data/models/production_stage_entry_dto.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';
import 'package:durvaeco/features/production/bom/application/providers/bom_providers.dart';

enum ProductionFormStatus { initial, submitting, success, error }

class ProductionFormState {
  const ProductionFormState({
    this.productionNumber = '',
    this.bomId = 0,
    this.bomCode,
    this.finishedProductId = 0,
    this.finishedProductName,
    this.finishedProductUnit,
    this.warehouseId = 0,
    required this.productionDate,
    this.shiftName = 'General Shift (08:00 - 16:00)',
    this.plannedQty = 1000.0,
    this.notes,
    this.materials = const [],
    this.stages = const [],
    this.formStatus = ProductionFormStatus.initial,
    this.errorMessage,
  });

  final String productionNumber;
  final int bomId;
  final String? bomCode;
  final int finishedProductId;
  final String? finishedProductName;
  final String? finishedProductUnit;
  final int warehouseId;
  final DateTime productionDate;
  final String shiftName;
  final double plannedQty;
  final String? notes;
  final List<ProductionMaterialIssueDto> materials;
  final List<ProductionStageEntryDto> stages;
  final ProductionFormStatus formStatus;
  final String? errorMessage;

  ProductionFormState copyWith({
    String? productionNumber,
    int? bomId,
    String? bomCode,
    int? finishedProductId,
    String? finishedProductName,
    String? finishedProductUnit,
    int? warehouseId,
    DateTime? productionDate,
    String? shiftName,
    double? plannedQty,
    String? notes,
    List<ProductionMaterialIssueDto>? materials,
    List<ProductionStageEntryDto>? stages,
    ProductionFormStatus? formStatus,
    String? errorMessage,
  }) {
    return ProductionFormState(
      productionNumber: productionNumber ?? this.productionNumber,
      bomId: bomId ?? this.bomId,
      bomCode: bomCode ?? this.bomCode,
      finishedProductId: finishedProductId ?? this.finishedProductId,
      finishedProductName: finishedProductName ?? this.finishedProductName,
      finishedProductUnit: finishedProductUnit ?? this.finishedProductUnit,
      warehouseId: warehouseId ?? this.warehouseId,
      productionDate: productionDate ?? this.productionDate,
      shiftName: shiftName ?? this.shiftName,
      plannedQty: plannedQty ?? this.plannedQty,
      notes: notes ?? this.notes,
      materials: materials ?? this.materials,
      stages: stages ?? this.stages,
      formStatus: formStatus ?? this.formStatus,
      errorMessage: errorMessage,
    );
  }
}

class ProductionOrderFormController extends StateNotifier<ProductionFormState> {
  ProductionOrderFormController(this._ref)
      : super(ProductionFormState(
          productionDate: DateTime.now(),
          productionNumber: 'PRD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
        ));

  final Ref _ref;

  void initialize() {
    state = ProductionFormState(
      productionDate: DateTime.now(),
      productionNumber: 'PRD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
  }

  void setWarehouseId(int id) => state = state.copyWith(warehouseId: id);
  void setShiftName(String shift) => state = state.copyWith(shiftName: shift);
  void setProductionDate(DateTime date) => state = state.copyWith(productionDate: date);
  void setNotes(String? notes) => state = state.copyWith(notes: notes);

  Future<void> setFinishedProduct(int productId, String productName, String? unit) async {
    state = state.copyWith(
      finishedProductId: productId,
      finishedProductName: productName,
      finishedProductUnit: unit,
    );

    // Auto-resolve active BOM and generate material requisitions
    await _recalculateFromBom();
  }

  Future<void> setPlannedQty(double qty) async {
    state = state.copyWith(plannedQty: qty);
    await _recalculateFromBom();
  }

  Future<void> _recalculateFromBom() async {
    if (state.finishedProductId <= 0 || state.plannedQty <= 0) return;

    final bom = await _ref.read(activeBomByProductProvider(state.finishedProductId).future);
    if (bom != null) {
      final batchFactor = bom.batchSize > 0 ? (state.plannedQty / bom.batchSize) : 1.0;
      final generatedMaterials = bom.items.map((item) {
        final reqQty = item.effectiveQuantity * batchFactor;
        return ProductionMaterialIssueDto(
          id: 0,
          productionOrderId: 0,
          productId: item.rawMaterialId,
          productName: item.rawMaterialName,
          productCode: item.rawMaterialCode,
          unitName: item.unitName,
          requiredQty: reqQty,
          issuedQty: 0.0,
          unitCost: item.unitCost,
        );
      }).toList();

      state = state.copyWith(
        bomId: bom.id,
        bomCode: bom.bomCode,
        materials: generatedMaterials,
      );
    }
  }

  Future<bool> submit() async {
    if (state.finishedProductId <= 0) {
      state = state.copyWith(formStatus: ProductionFormStatus.error, errorMessage: 'Output finished good is required');
      return false;
    }
    if (state.warehouseId <= 0) {
      state = state.copyWith(formStatus: ProductionFormStatus.error, errorMessage: 'Production warehouse is required');
      return false;
    }
    if (state.plannedQty <= 0) {
      state = state.copyWith(formStatus: ProductionFormStatus.error, errorMessage: 'Planned quantity must be > 0');
      return false;
    }

    state = state.copyWith(formStatus: ProductionFormStatus.submitting);

    // Fetch stages to initialize stage entries
    final stages = await _ref.read(productionStagesListProvider.future);
    final initialStageEntries = stages.map((s) => ProductionStageEntryDto(
      id: 0,
      productionOrderId: 0,
      stageId: s.id,
      stageName: s.stageName,
      sequenceNo: s.sequenceNo,
      status: StageStatus.pending,
    )).toList();

    final order = ProductionOrderDto(
      id: 0,
      productionNumber: state.productionNumber,
      bomId: state.bomId,
      bomCode: state.bomCode,
      finishedProductId: state.finishedProductId,
      finishedProductName: state.finishedProductName,
      finishedProductCode: null,
      finishedProductUnit: state.finishedProductUnit,
      warehouseId: state.warehouseId,
      productionDate: state.productionDate,
      shiftName: state.shiftName,
      plannedQty: state.plannedQty,
      status: ProductionStatus.planned,
      notes: state.notes,
      materials: state.materials,
      stages: initialStageEntries,
    );

    final repo = _ref.read(productionRepositoryProvider);
    final result = await repo.create(order);

    return result.when(
      success: (_) {
        state = state.copyWith(formStatus: ProductionFormStatus.success);
        _ref.invalidate(productionOrdersListProvider);
        return true;
      },
      failure: (f) {
        state = state.copyWith(formStatus: ProductionFormStatus.error, errorMessage: f.message);
        return false;
      },
    );
  }
}

final productionOrderFormControllerProvider = StateNotifierProvider.autoDispose<
    ProductionOrderFormController, ProductionFormState>((ref) {
  return ProductionOrderFormController(ref);
});
