import '../../../../core/utils/json_reader.dart';

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
    final reader = JsonReader(json);
    return ProductionStageDto(
      id: reader.getInt('id', aliases: ['Id', 'ProductionStageId', 'productionStageId', 'stageId', 'StageId']),
      stageName: reader.getString('stageName', aliases: ['StageName', 'name', 'Name']),
      sequenceNo: reader.getInt('sequenceNo', aliases: ['SequenceNo', 'sequence', 'Sequence', 'order', 'Order'], defaultValue: 1),
      description: reader.getOptionalString('description', aliases: ['Description']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
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
