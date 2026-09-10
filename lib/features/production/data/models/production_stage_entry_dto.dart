enum StageStatus {
  pending,
  inProgress,
  completed;

  static StageStatus fromString(String? val) {
    if (val == null) return StageStatus.pending;
    switch (val.toUpperCase()) {
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        return StageStatus.inProgress;
      case 'COMPLETED':
      case 'DONE':
        return StageStatus.completed;
      case 'PENDING':
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
    return ProductionStageEntryDto(
      id: json['id'] as int? ?? json['ProductionStageEntryId'] as int? ?? 0,
      productionOrderId: json['productionOrderId'] as int? ?? json['ProductionOrderId'] as int? ?? 0,
      stageId: json['stageId'] as int? ?? json['StageId'] as int? ?? 0,
      stageName: json['stageName'] as String? ?? json['StageName'] as String?,
      sequenceNo: json['sequenceNo'] as int? ?? json['SequenceNo'] as int? ?? 1,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'].toString()) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'].toString()) : null,
      status: StageStatus.fromString(json['status'] as String? ?? json['Status'] as String?),
      operatorName: json['operatorName'] as String? ?? json['OperatorName'] as String?,
      remarks: json['remarks'] as String? ?? json['Remarks'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
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
