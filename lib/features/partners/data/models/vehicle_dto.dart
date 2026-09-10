import '../../../../core/utils/json_reader.dart';

class VehicleDto {
  const VehicleDto({
    required this.id,
    required this.transporterId,
    this.transporterName,
    required this.vehicleNumber,
    this.driverName,
    this.driverPhone,
    this.vehicleType = 'Truck (10 Ton)',
    this.capacity,
    this.isActive = true,
  });

  final int id;
  final int transporterId;
  final String? transporterName;
  final String vehicleNumber;
  final String? driverName;
  final String? driverPhone;
  final String vehicleType;
  final String? capacity;
  final bool isActive;

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return VehicleDto(
      id: reader.getInt('id', aliases: ['vehicleId', 'VehicleId', 'Id']),
      transporterId: reader.getInt('transporterId', aliases: ['TransporterId']),
      transporterName: reader.getOptionalString('transporterName', aliases: ['TransporterName']),
      vehicleNumber: reader.getString('vehicleNumber', aliases: ['VehicleNumber', 'registrationNumber', 'RegistrationNumber', 'number', 'Number']),
      driverName: reader.getOptionalString('driverName', aliases: ['DriverName']),
      driverPhone: reader.getOptionalString('driverPhone', aliases: ['DriverPhone', 'phone', 'Phone']),
      vehicleType: reader.getString('vehicleType', aliases: ['VehicleType', 'type', 'Type'], defaultValue: 'Truck (10 Ton)'),
      capacity: reader.getOptionalString('capacity', aliases: ['Capacity']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transporterId': transporterId,
      if (transporterName != null) 'transporterName': transporterName,
      'vehicleNumber': vehicleNumber,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      'vehicleType': vehicleType,
      if (capacity != null) 'capacity': capacity,
      'isActive': isActive,
    };
  }

  VehicleDto copyWith({
    int? id,
    int? transporterId,
    String? transporterName,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    String? vehicleType,
    String? capacity,
    bool? isActive,
  }) {
    return VehicleDto(
      id: id ?? this.id,
      transporterId: transporterId ?? this.transporterId,
      transporterName: transporterName ?? this.transporterName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleType: vehicleType ?? this.vehicleType,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
    );
  }
}
