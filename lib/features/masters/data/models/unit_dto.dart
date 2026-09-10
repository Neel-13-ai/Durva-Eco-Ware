import '../../../../core/utils/json_reader.dart';

class UnitDto {
  const UnitDto({
    required this.id,
    required this.name,
    required this.symbol,
    this.description,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String symbol;
  final String? description;
  final bool isActive;

  factory UnitDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return UnitDto(
      id: reader.getInt('id', aliases: ['unitId', 'UnitId', 'Id']),
      name: reader.getString('name', aliases: ['unitName', 'UnitName', 'Name']),
      symbol: reader.getString('symbol', aliases: ['shortName', 'ShortName', 'unitSymbol', 'UnitSymbol', 'Symbol']),
      description: reader.getOptionalString('description', aliases: ['Description']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }

  UnitDto copyWith({
    int? id,
    String? name,
    String? symbol,
    String? description,
    bool? isActive,
  }) {
    return UnitDto(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
