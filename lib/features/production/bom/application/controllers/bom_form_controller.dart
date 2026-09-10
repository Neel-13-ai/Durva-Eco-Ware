import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/production/bom/data/models/bom_header_dto.dart';
import 'package:durvaeco/features/production/bom/data/models/bom_detail_dto.dart';
import 'package:durvaeco/features/production/bom/application/providers/bom_providers.dart';

enum BomFormStatus { initial, submitting, success, error }

class BomFormState {
  const BomFormState({
    this.id,
    this.bomCode = '',
    this.finishedProductId = 0,
    this.finishedProductName,
    this.finishedProductUnit,
    this.versionNo = '1.0',
    this.batchSize = 1000.0,
    required this.effectiveFrom,
    this.effectiveTo,
    this.notes,
    this.isActive = true,
    this.items = const [],
    this.formStatus = BomFormStatus.initial,
    this.errorMessage,
  });

  final int? id;
  final String bomCode;
  final int finishedProductId;
  final String? finishedProductName;
  final String? finishedProductUnit;
  final String versionNo;
  final double batchSize;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? notes;
  final bool isActive;
  final List<BomDetailDto> items;
  final BomFormStatus formStatus;
  final String? errorMessage;

  bool get isEdit => id != null && id! > 0;
  double get totalBatchCost => items.fold(0.0, (sum, item) => sum + item.itemCost);
  double get costPerUnit => batchSize > 0 ? totalBatchCost / batchSize : 0.0;

  BomFormState copyWith({
    int? id,
    String? bomCode,
    int? finishedProductId,
    String? finishedProductName,
    String? finishedProductUnit,
    String? versionNo,
    double? batchSize,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? notes,
    bool? isActive,
    List<BomDetailDto>? items,
    BomFormStatus? formStatus,
    String? errorMessage,
  }) {
    return BomFormState(
      id: id ?? this.id,
      bomCode: bomCode ?? this.bomCode,
      finishedProductId: finishedProductId ?? this.finishedProductId,
      finishedProductName: finishedProductName ?? this.finishedProductName,
      finishedProductUnit: finishedProductUnit ?? this.finishedProductUnit,
      versionNo: versionNo ?? this.versionNo,
      batchSize: batchSize ?? this.batchSize,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      items: items ?? this.items,
      formStatus: formStatus ?? this.formStatus,
      errorMessage: errorMessage,
    );
  }
}

class BomFormController extends StateNotifier<BomFormState> {
  BomFormController(this._ref)
      : super(BomFormState(
          effectiveFrom: DateTime.now(),
          bomCode: 'BOM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
        ));

  final Ref _ref;

  void initialize(BomHeaderDto? existing) {
    if (existing != null) {
      state = BomFormState(
        id: existing.id,
        bomCode: existing.bomCode,
        finishedProductId: existing.finishedProductId,
        finishedProductName: existing.finishedProductName,
        finishedProductUnit: existing.finishedProductUnit,
        versionNo: existing.versionNo,
        batchSize: existing.batchSize,
        effectiveFrom: existing.effectiveFrom,
        effectiveTo: existing.effectiveTo,
        notes: existing.notes,
        isActive: existing.isActive,
        items: List.from(existing.items),
      );
    } else {
      state = BomFormState(
        effectiveFrom: DateTime.now(),
        bomCode: 'BOM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
      );
    }
  }

  void setFinishedProduct(int id, String name, String? unit) {
    state = state.copyWith(finishedProductId: id, finishedProductName: name, finishedProductUnit: unit);
  }

  void setBomCode(String code) => state = state.copyWith(bomCode: code);
  void setVersionNo(String ver) => state = state.copyWith(versionNo: ver);
  void setBatchSize(double size) => state = state.copyWith(batchSize: size);
  void setEffectiveFrom(DateTime from) => state = state.copyWith(effectiveFrom: from);
  void setEffectiveTo(DateTime? to) => state = state.copyWith(effectiveTo: to);
  void setNotes(String? notes) => state = state.copyWith(notes: notes);
  void setIsActive(bool active) => state = state.copyWith(isActive: active);

  void addItem(BomDetailDto item) {
    // Check if raw material already in recipe
    final existingIndex = state.items.indexWhere((i) => i.rawMaterialId == item.rawMaterialId);
    if (existingIndex >= 0) {
      final updated = List<BomDetailDto>.from(state.items);
      updated[existingIndex] = item;
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void removeItem(int index) {
    final updated = List<BomDetailDto>.from(state.items);
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
      state = state.copyWith(items: updated);
    }
  }

  Future<bool> submit() async {
    if (state.finishedProductId <= 0) {
      state = state.copyWith(formStatus: BomFormStatus.error, errorMessage: 'Finished good is required');
      return false;
    }
    if (state.items.isEmpty) {
      state = state.copyWith(formStatus: BomFormStatus.error, errorMessage: 'At least 1 raw material component is required');
      return false;
    }
    if (state.batchSize <= 0) {
      state = state.copyWith(formStatus: BomFormStatus.error, errorMessage: 'Batch size must be greater than 0');
      return false;
    }

    state = state.copyWith(formStatus: BomFormStatus.submitting);

    final repo = _ref.read(bomRepositoryProvider);
    final headerDto = BomHeaderDto(
      id: state.id ?? 0,
      bomCode: state.bomCode,
      finishedProductId: state.finishedProductId,
      finishedProductName: state.finishedProductName,
      finishedProductUnit: state.finishedProductUnit,
      versionNo: state.versionNo,
      batchSize: state.batchSize,
      effectiveFrom: state.effectiveFrom,
      effectiveTo: state.effectiveTo,
      notes: state.notes,
      isActive: state.isActive,
      items: state.items,
    );

    final result = state.isEdit
        ? await repo.update(state.id!, headerDto)
        : await repo.create(headerDto);

    return result.when(
      success: (saved) {
        state = state.copyWith(formStatus: BomFormStatus.success);
        _ref.invalidate(bomsListProvider);
        if (state.isEdit) {
          _ref.invalidate(bomDetailProvider(state.id!));
        }
        _ref.invalidate(activeBomByProductProvider(saved.finishedProductId));
        return true;
      },
      failure: (f) {
        state = state.copyWith(formStatus: BomFormStatus.error, errorMessage: f.message);
        return false;
      },
    );
  }
}

final bomFormControllerProvider = StateNotifierProvider.autoDispose<BomFormController, BomFormState>((ref) {
  return BomFormController(ref);
});
