import '../../../../core/utils/json_reader.dart';

class TransporterDto {
  const TransporterDto({
    required this.id,
    required this.transporterCode,
    required this.transporterName,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.isActive = true,
  });

  final int id;
  final String transporterCode;
  final String transporterName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final bool isActive;

  factory TransporterDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return TransporterDto(
      id: reader.getInt('id', aliases: ['transporterId', 'TransporterId', 'Id']),
      transporterCode: reader.getString('transporterCode', aliases: ['TransporterCode', 'code', 'Code']),
      transporterName: reader.getString('transporterName', aliases: ['TransporterName', 'name', 'Name']),
      contactPerson: reader.getOptionalString('contactPerson', aliases: ['ContactPerson']),
      phone: reader.getOptionalString('phone', aliases: ['Phone', 'contactNumber', 'ContactNumber']),
      email: reader.getOptionalString('email', aliases: ['Email']),
      address: reader.getOptionalString('address', aliases: ['Address']),
      gstNumber: reader.getOptionalString('gstNumber', aliases: ['GstNumber', 'taxNumber', 'TaxNumber', 'gstin']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transporterCode': transporterCode,
      'transporterName': transporterName,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (gstNumber != null) 'gstNumber': gstNumber,
      'isActive': isActive,
    };
  }

  TransporterDto copyWith({
    int? id,
    String? transporterCode,
    String? transporterName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    bool? isActive,
  }) {
    return TransporterDto(
      id: id ?? this.id,
      transporterCode: transporterCode ?? this.transporterCode,
      transporterName: transporterName ?? this.transporterName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      isActive: isActive ?? this.isActive,
    );
  }
}
