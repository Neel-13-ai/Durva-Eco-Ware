class ProductionStageDto {
  const ProductionStageDto({
    required this.id,
    required this.stageName,
    required this.sequenceNo,
    this.description,
    this.isActive = true,
  });

  final int id;
  final String stageName;
  final int sequenceNo;
  final String? description;
  final bool isActive;

  factory ProductionStageDto.fromJson(Map<String, dynamic> json) {
    return ProductionStageDto(
      id: json['id'] as int? ?? json['ProductionStageId'] as int? ?? json['stageId'] as int? ?? 0,
      stageName: json['stageName'] as String? ?? json['StageName'] as String? ?? '',
      sequenceNo: json['sequenceNo'] as int? ?? json['SequenceNo'] as int? ?? 1,
      description: json['description'] as String? ?? json['Description'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stageName': stageName,
      'sequenceNo': sequenceNo,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }
}
