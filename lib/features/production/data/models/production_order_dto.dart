import '../../../../core/utils/json_reader.dart';
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
    final reader = JsonReader(json);

    final id = reader.getInt('id', aliases: ['Id', 'productionOrderId', 'ProductionOrderId']);
    var prdNum = reader.getString('productionNumber', aliases: ['ProductionNumber', 'orderNumber', 'OrderNumber', 'number', 'Number']);
    if (prdNum.isEmpty && id > 0) {
      prdNum = 'PRD-${id.toString().padLeft(4, '0')}';
    }

    String? prodName = reader.getOptionalString('finishedProductName', aliases: ['FinishedProductName', 'productName', 'ProductName']);
    if (prodName == null) {
      final pMap = reader.getMap('finishedProduct', aliases: ['FinishedProduct', 'product', 'Product']);
      if (pMap != null) {
        prodName = pMap['name']?.toString() ?? pMap['productName']?.toString();
      }
    }

    String? whName = reader.getOptionalString('warehouseName', aliases: ['WarehouseName']);
    if (whName == null) {
      final whMap = reader.getMap('warehouse', aliases: ['Warehouse']);
      if (whMap != null) {
        whName = whMap['name']?.toString() ?? whMap['warehouseName']?.toString();
      }
    }

    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) mapper) {
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map((e) => mapper(e)).toList();
      }
      return const [];
    }

    final rawMaterials = reader.getList('materials', aliases: ['ProductionMaterialIssues', 'materialIssues', 'MaterialIssues']);
    final rawStages = reader.getList('stages', aliases: ['ProductionStageEntries', 'stageEntries', 'StageEntries']);
    final rawOutputs = reader.getList('outputs', aliases: ['ProductionOutputs', 'outputs']);
    final rawQc = reader.getList('qualityChecks', aliases: ['QualityChecks', 'qualityChecks']);

    return ProductionOrderDto(
      id: id,
      productionNumber: prdNum,
      bomId: reader.getInt('bomId', aliases: ['BOMId', 'bomHeaderId', 'BOMHeaderId', 'BomId']),
      bomCode: reader.getOptionalString('bomCode', aliases: ['BOMCode', 'BomCode']),
      finishedProductId: reader.getInt('finishedProductId', aliases: ['FinishedProductId', 'productId', 'ProductId']),
      finishedProductName: prodName,
      finishedProductCode: reader.getOptionalString('finishedProductCode', aliases: ['FinishedProductCode', 'productCode', 'ProductCode']),
      finishedProductUnit: reader.getOptionalString('finishedProductUnit', aliases: ['FinishedProductUnit', 'unit', 'Unit']),
      warehouseId: reader.getInt('warehouseId', aliases: ['WarehouseId']),
      warehouseName: whName,
      productionDate: reader.getDateTime('productionDate', aliases: ['ProductionDate', 'date', 'Date']) ?? DateTime.now(),
      shiftName: reader.getString('shiftName', aliases: ['ShiftName'], defaultValue: 'General Shift'),
      plannedQty: reader.getDouble('plannedQty', aliases: ['PlannedQty', 'plannedQuantity', 'PlannedQuantity', 'quantity', 'Quantity']),
      actualProducedQty: reader.getDouble('actualProducedQty', aliases: ['ActualProducedQty', 'producedQty', 'ProducedQty', 'actualQty']),
      status: ProductionStatus.fromString(reader.getOptionalString('status', aliases: ['Status'])),
      notes: reader.getOptionalString('notes', aliases: ['Notes', 'remarks', 'Remarks']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
      materials: parseList(rawMaterials, ProductionMaterialIssueDto.fromJson),
      stages: parseList(rawStages, ProductionStageEntryDto.fromJson),
      outputs: parseList(rawOutputs, ProductionOutputDto.fromJson),
      qualityChecks: parseList(rawQc, QualityCheckDto.fromJson),
    );
  }

  Map<String, dynamic> toApiJson({int createdBy = 1, bool isUpdate = false}) {
    return {
      if (isUpdate && id > 0) 'id': id,
      'productionNumber': productionNumber,
      'bomId': bomId,
      'finishedProductId': finishedProductId,
      'warehouseId': warehouseId,
      'productionDate': productionDate.toIso8601String(),
      'shiftName': shiftName,
      'plannedQty': plannedQty,
      'status': status.toApiValue(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdBy': createdBy,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
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
