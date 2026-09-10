import 'production_stage_entry_dto.dart';
import 'production_material_issue_dto.dart';
import 'production_output_dto.dart';
import 'quality_check_dto.dart';

enum ProductionStatus {
  draft,
  planned,
  inProgress,
  completed,
  cancelled;

  static ProductionStatus fromString(String? val) {
    if (val == null) return ProductionStatus.draft;
    switch (val.toUpperCase()) {
      case 'PLANNED':
        return ProductionStatus.planned;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        return ProductionStatus.inProgress;
      case 'COMPLETED':
        return ProductionStatus.completed;
      case 'CANCELLED':
        return ProductionStatus.cancelled;
      case 'DRAFT':
      default:
        return ProductionStatus.draft;
    }
  }

  String toApiValue() {
    switch (this) {
      case ProductionStatus.draft:
        return 'DRAFT';
      case ProductionStatus.planned:
        return 'PLANNED';
      case ProductionStatus.inProgress:
        return 'IN_PROGRESS';
      case ProductionStatus.completed:
        return 'COMPLETED';
      case ProductionStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class ProductionOrderDto {
  const ProductionOrderDto({
    required this.id,
    required this.productionNumber,
    required this.bomId,
    this.bomCode,
    required this.finishedProductId,
    this.finishedProductName,
    this.finishedProductCode,
    this.finishedProductUnit,
    required this.warehouseId,
    this.warehouseName,
    required this.productionDate,
    this.shiftName = 'General Shift',
    required this.plannedQty,
    this.actualProducedQty = 0.0,
    this.status = ProductionStatus.draft,
    this.notes,
    this.isActive = true,
    this.materials = const [],
    this.stages = const [],
    this.outputs = const [],
    this.qualityChecks = const [],
  });

  final int id;
  final String productionNumber;
  final int bomId;
  final String? bomCode;
  final int finishedProductId;
  final String? finishedProductName;
  final String? finishedProductCode;
  final String? finishedProductUnit;
  final int warehouseId;
  final String? warehouseName;
  final DateTime productionDate;
  final String shiftName;
  final double plannedQty;
  final double actualProducedQty;
  final ProductionStatus status;
  final String? notes;
  final bool isActive;
  final List<ProductionMaterialIssueDto> materials;
  final List<ProductionStageEntryDto> stages;
  final List<ProductionOutputDto> outputs;
  final List<QualityCheckDto> qualityChecks;

  /// Progress fraction of stages completed (0.0 to 1.0)
  double get stageProgress {
    if (stages.isEmpty) return status == ProductionStatus.completed ? 1.0 : 0.0;
    final completedCount = stages.where((s) => s.isCompleted).length;
    return completedCount / stages.length;
  }

  /// Total good units produced across all output logs
  double get totalGoodOutput => outputs.fold(0.0, (sum, o) => sum + o.goodQty);

  /// Whether all materials have been issued
  bool get isMaterialsFullyIssued => materials.isNotEmpty && materials.every((m) => m.isFullyIssued);

  /// Whether latest QC passed
  bool get isQcPassed => qualityChecks.isNotEmpty && qualityChecks.last.isPassed;

  factory ProductionOrderDto.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) mapper) {
      if (raw is List) {
        return raw.map((e) => mapper(e as Map<String, dynamic>)).toList();
      }
      return const [];
    }

    return ProductionOrderDto(
      id: json['id'] as int? ?? json['ProductionOrderId'] as int? ?? 0,
      productionNumber: json['productionNumber'] as String? ?? json['ProductionNumber'] as String? ?? '',
      bomId: json['bomId'] as int? ?? json['BOMId'] as int? ?? json['bomHeaderId'] as int? ?? 0,
      bomCode: json['bomCode'] as String? ?? json['BOMCode'] as String?,
      finishedProductId: json['finishedProductId'] as int? ?? json['FinishedProductId'] as int? ?? 0,
      finishedProductName: json['finishedProductName'] as String? ?? json['FinishedProductName'] as String?,
      finishedProductCode: json['finishedProductCode'] as String? ?? json['FinishedProductCode'] as String?,
      finishedProductUnit: json['finishedProductUnit'] as String? ?? json['FinishedProductUnit'] as String?,
      warehouseId: json['warehouseId'] as int? ?? json['WarehouseId'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String? ?? json['WarehouseName'] as String?,
      productionDate: json['productionDate'] != null
          ? DateTime.parse(json['productionDate'].toString())
          : (json['ProductionDate'] != null
              ? DateTime.parse(json['ProductionDate'].toString())
              : DateTime.now()),
      shiftName: json['shiftName'] as String? ?? json['ShiftName'] as String? ?? 'General Shift',
      plannedQty: (json['plannedQty'] as num? ?? json['PlannedQty'] as num? ?? 0.0).toDouble(),
      actualProducedQty: (json['actualProducedQty'] as num? ?? json['ActualProducedQty'] as num? ?? 0.0).toDouble(),
      status: ProductionStatus.fromString(json['status'] as String? ?? json['Status'] as String?),
      notes: json['notes'] as String? ?? json['Notes'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
      materials: parseList(json['materials'] ?? json['ProductionMaterialIssues'] ?? json['materialIssues'], ProductionMaterialIssueDto.fromJson),
      stages: parseList(json['stages'] ?? json['ProductionStageEntries'] ?? json['stageEntries'], ProductionStageEntryDto.fromJson),
      outputs: parseList(json['outputs'] ?? json['ProductionOutputs'], ProductionOutputDto.fromJson),
      qualityChecks: parseList(json['qualityChecks'] ?? json['QualityChecks'], QualityCheckDto.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productionNumber': productionNumber,
      'bomId': bomId,
      if (bomCode != null) 'bomCode': bomCode,
      'finishedProductId': finishedProductId,
      if (finishedProductName != null) 'finishedProductName': finishedProductName,
      if (finishedProductCode != null) 'finishedProductCode': finishedProductCode,
      if (finishedProductUnit != null) 'finishedProductUnit': finishedProductUnit,
      'warehouseId': warehouseId,
      if (warehouseName != null) 'warehouseName': warehouseName,
      'productionDate': productionDate.toIso8601String(),
      'shiftName': shiftName,
      'plannedQty': plannedQty,
      'actualProducedQty': actualProducedQty,
      'status': status.toApiValue(),
      if (notes != null) 'notes': notes,
      'isActive': isActive,
      'materials': materials.map((e) => e.toJson()).toList(),
      'stages': stages.map((e) => e.toJson()).toList(),
      'outputs': outputs.map((e) => e.toJson()).toList(),
      'qualityChecks': qualityChecks.map((e) => e.toJson()).toList(),
    };
  }

  ProductionOrderDto copyWith({
    int? id,
    String? productionNumber,
    int? bomId,
    String? bomCode,
    int? finishedProductId,
    String? finishedProductName,
    String? finishedProductCode,
    String? finishedProductUnit,
    int? warehouseId,
    String? warehouseName,
    DateTime? productionDate,
    String? shiftName,
    double? plannedQty,
    double? actualProducedQty,
    ProductionStatus? status,
    String? notes,
    bool? isActive,
    List<ProductionMaterialIssueDto>? materials,
    List<ProductionStageEntryDto>? stages,
    List<ProductionOutputDto>? outputs,
    List<QualityCheckDto>? qualityChecks,
  }) {
    return ProductionOrderDto(
      id: id ?? this.id,
      productionNumber: productionNumber ?? this.productionNumber,
      bomId: bomId ?? this.bomId,
      bomCode: bomCode ?? this.bomCode,
      finishedProductId: finishedProductId ?? this.finishedProductId,
      finishedProductName: finishedProductName ?? this.finishedProductName,
      finishedProductCode: finishedProductCode ?? this.finishedProductCode,
      finishedProductUnit: finishedProductUnit ?? this.finishedProductUnit,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      productionDate: productionDate ?? this.productionDate,
      shiftName: shiftName ?? this.shiftName,
      plannedQty: plannedQty ?? this.plannedQty,
      actualProducedQty: actualProducedQty ?? this.actualProducedQty,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      materials: materials ?? this.materials,
      stages: stages ?? this.stages,
      outputs: outputs ?? this.outputs,
      qualityChecks: qualityChecks ?? this.qualityChecks,
    );
  }
}
