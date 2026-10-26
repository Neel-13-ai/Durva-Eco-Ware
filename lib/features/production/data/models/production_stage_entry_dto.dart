import '../../../../core/utils/json_reader.dart';

enum StageStatus {
  pending,
  inProgress,
  completed;

  static StageStatus fromString(dynamic val) {
    if (val == null) return StageStatus.pending;
    final s = val.toString().toUpperCase().trim();
    switch (s) {
      case 'IN_PROGRESS':
      case 'INPROGRESS':
      case '1':
        return StageStatus.inProgress;
      case 'COMPLETED':
      case 'DONE':
      case '2':
        return StageStatus.completed;
      case 'PENDING':
      case '0':
      default:
        return StageStatus.pending;
    }
  }

  String toApiValue() {
    switch (this) {
      case StageStatus.pending:
        return 'PENDING';
      case StageStatus.inProgress:
        return 'IN_PROGRESS';
      case StageStatus.completed:
        return 'COMPLETED';
    }
  }
}

class ProductionStageEntryDto {
  const ProductionStageEntryDto({
    required this.id,
    required this.productionOrderId,
    required this.stageId,
    this.stageName,
    this.sequenceNo = 1,
    this.startTime,
    this.endTime,
    this.status = StageStatus.pending,
    this.operatorName,
    this.remarks,
    this.isActive = true,
  });

  final int id;
  final int productionOrderId;
  final int stageId;
  final String? stageName;
  final int sequenceNo;
  final DateTime? startTime;
  final DateTime? endTime;
  final StageStatus status;
  final String? operatorName;
  final String? remarks;
  final bool isActive;

  bool get isCompleted => status == StageStatus.completed;
  bool get isInProgress => status == StageStatus.inProgress;
  bool get isPending => status == StageStatus.pending;

  factory ProductionStageEntryDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ProductionStageEntryDto(
      id: reader.getInt('id', aliases: ['Id', 'ProductionStageEntryId', 'productionStageEntryId']),
      productionOrderId: reader.getInt('productionOrderId', aliases: ['ProductionOrderId']),
      stageId: reader.getInt('stageId', aliases: ['StageId']),
      stageName: reader.getOptionalString('stageName', aliases: ['StageName']),
      sequenceNo: reader.getInt('sequenceNo', aliases: ['SequenceNo', 'order', 'Order'], defaultValue: 1),
      startTime: reader.getDateTime('startTime', aliases: ['StartTime']),
      endTime: reader.getDateTime('endTime', aliases: ['EndTime']),
      status: StageStatus.fromString(reader.getOptionalString('status', aliases: ['Status'])),
      operatorName: reader.getOptionalString('operatorName', aliases: ['OperatorName', 'operator', 'Operator']),
      remarks: reader.getOptionalString('remarks', aliases: ['Remarks', 'notes', 'Notes']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productionOrderId': productionOrderId,
      'stageId': stageId,
      if (stageName != null) 'stageName': stageName,
      'sequenceNo': sequenceNo,
      if (startTime != null) 'startTime': startTime!.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      'status': status.toApiValue(),
      if (operatorName != null) 'operatorName': operatorName,
      if (remarks != null) 'remarks': remarks,
      'isActive': isActive,
    };
  }

  ProductionStageEntryDto copyWith({
    int? id,
    int? productionOrderId,
    int? stageId,
    String? stageName,
    int? sequenceNo,
    DateTime? startTime,
    DateTime? endTime,
    StageStatus? status,
    String? operatorName,
    String? remarks,
    bool? isActive,
  }) {
    return ProductionStageEntryDto(
      id: id ?? this.id,
      productionOrderId: productionOrderId ?? this.productionOrderId,
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      sequenceNo: sequenceNo ?? this.sequenceNo,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      operatorName: operatorName ?? this.operatorName,
      remarks: remarks ?? this.remarks,
      isActive: isActive ?? this.isActive,
    );
  }
}
