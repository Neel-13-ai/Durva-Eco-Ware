import '../../../../core/utils/json_reader.dart';

class WarehouseDto {
  const WarehouseDto({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.city,
    this.state,
    this.managerName,
    this.contactPhone,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String code;
  final String? address;
  final String? city;
  final String? state;
  final String? managerName;
  final String? contactPhone;
  final bool isActive;

  factory WarehouseDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WarehouseDto(
      id: reader.getInt('id', aliases: ['warehouseId', 'WarehouseId', 'Id']),
      name: reader.getString('name', aliases: ['warehouseName', 'WarehouseName', 'Name']),
      code: reader.getString('code', aliases: ['warehouseCode', 'WarehouseCode', 'Code']),
      address: reader.getOptionalString('address', aliases: ['Address']),
      city: reader.getOptionalString('city', aliases: ['City']),
      state: reader.getOptionalString('state', aliases: ['State']),
      managerName: reader.getOptionalString('managerName', aliases: ['ManagerName', 'manager']),
      contactPhone: reader.getOptionalString('contactPhone', aliases: ['ContactPhone', 'phone', 'Phone']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (managerName != null) 'managerName': managerName,
      if (contactPhone != null) 'contactPhone': contactPhone,
      'isActive': isActive,
    };
  }

  WarehouseDto copyWith({
    int? id,
    String? name,
    String? code,
    String? address,
    String? city,
    String? state,
    String? managerName,
    String? contactPhone,
    bool? isActive,
  }) {
    return WarehouseDto(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      managerName: managerName ?? this.managerName,
      contactPhone: contactPhone ?? this.contactPhone,
      isActive: isActive ?? this.isActive,
    );
  }
}
