import '../../../../core/utils/json_reader.dart';

class DocumentSequenceDto {
  const DocumentSequenceDto({
    required this.id,
    required this.moduleName,
    required this.prefix,
    required this.nextNumber,
    this.padding = 4,
    this.suffix,
    this.isActive = true,
  });

  final int id;
  final String moduleName;
  final String prefix;
  final int nextNumber;
  final int padding;
  final String? suffix;
  final bool isActive;

  String get sampleGeneratedCode {
    final numStr = nextNumber.toString().padLeft(padding, '0');
    return '$prefix$numStr${suffix ?? ''}';
  }

  factory DocumentSequenceDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return DocumentSequenceDto(
      id: reader.getInt('id', aliases: ['sequenceId', 'SequenceId', 'Id']),
      moduleName: reader.getString('moduleName', aliases: ['documentType', 'DocumentType', 'module', 'Module']),
      prefix: reader.getString('prefix', aliases: ['Prefix']),
      nextNumber: reader.getInt('nextNumber', aliases: ['NextNumber', 'currentNumber', 'CurrentNumber'], defaultValue: 1),
      padding: reader.getInt('padding', aliases: ['numberLength', 'NumberLength', 'Length'], defaultValue: 4),
      suffix: reader.getOptionalString('suffix', aliases: ['Suffix']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moduleName': moduleName,
      'prefix': prefix,
      'nextNumber': nextNumber,
      'padding': padding,
      if (suffix != null) 'suffix': suffix,
      'isActive': isActive,
    };
  }

  DocumentSequenceDto copyWith({
    int? id,
    String? moduleName,
    String? prefix,
    int? nextNumber,
    int? padding,
    String? suffix,
    bool? isActive,
  }) {
    return DocumentSequenceDto(
      id: id ?? this.id,
      moduleName: moduleName ?? this.moduleName,
      prefix: prefix ?? this.prefix,
      nextNumber: nextNumber ?? this.nextNumber,
      padding: padding ?? this.padding,
      suffix: suffix ?? this.suffix,
      isActive: isActive ?? this.isActive,
    );
  }
}
