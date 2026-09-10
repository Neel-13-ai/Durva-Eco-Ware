import '../../../../core/utils/json_reader.dart';

enum CategoryType {
  rawMaterial,
  finishedGood,
  packaging,
  general,
}

class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.type = CategoryType.general,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String? code;
  final String? description;
  final CategoryType type;
  final bool isActive;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    CategoryType parseType(String? t) {
      switch (t?.toUpperCase()) {
        case 'RAW_MATERIAL':
        case 'RAWMATERIAL':
        case 'RAW':
          return CategoryType.rawMaterial;
        case 'FINISHED_GOOD':
        case 'FINISHEDGOOD':
        case 'FINISHED':
          return CategoryType.finishedGood;
        case 'PACKAGING':
          return CategoryType.packaging;
        default:
          return CategoryType.general;
      }
    }

    return CategoryDto(
      id: reader.getInt('id', aliases: ['categoryId', 'CategoryId', 'Id']),
      name: reader.getString('name', aliases: ['categoryName', 'CategoryName', 'Name']),
      code: reader.getOptionalString('code', aliases: ['categoryCode', 'CategoryCode', 'Code']),
      description: reader.getOptionalString('description', aliases: ['Description']),
      type: parseType(reader.getOptionalString('type', aliases: ['categoryType', 'CategoryType', 'Type'])),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    String typeToString() {
      switch (type) {
        case CategoryType.rawMaterial:
          return 'RAW_MATERIAL';
        case CategoryType.finishedGood:
          return 'FINISHED_GOOD';
        case CategoryType.packaging:
          return 'PACKAGING';
        case CategoryType.general:
          return 'GENERAL';
      }
    }

    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      'type': typeToString(),
      'isActive': isActive,
    };
  }

  CategoryDto copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    CategoryType? type,
    bool? isActive,
  }) {
    return CategoryDto(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
}
