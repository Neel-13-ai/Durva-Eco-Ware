import '../../../../core/utils/json_reader.dart';

class SupplierDto {
  const SupplierDto({
    required this.id,
    required this.supplierCode,
    required this.supplierName,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.taxNumber,
    this.paymentTermsDays = 30,
    this.openingBalance = 0.0,
    this.isActive = true,
  });

  final int id;
  final String supplierCode;
  final String supplierName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? taxNumber;
  final int paymentTermsDays;
  final double openingBalance;
  final bool isActive;

  factory SupplierDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return SupplierDto(
      id: reader.getInt('id', aliases: ['supplierId', 'SupplierId', 'Id']),
      supplierCode: reader.getString('supplierCode', aliases: ['SupplierCode', 'code', 'Code']),
      supplierName: reader.getString('supplierName', aliases: ['SupplierName', 'name', 'Name']),
      contactPerson: reader.getOptionalString('contactPerson', aliases: ['ContactPerson', 'contactName']),
      phone: reader.getOptionalString('phone', aliases: ['Phone', 'contactNumber', 'ContactNumber', 'mobile']),
      email: reader.getOptionalString('email', aliases: ['Email']),
      address: reader.getOptionalString('address', aliases: ['Address']),
      city: reader.getOptionalString('city', aliases: ['City']),
      state: reader.getOptionalString('state', aliases: ['State']),
      zipCode: reader.getOptionalString('zipCode', aliases: ['ZipCode', 'pincode', 'Pincode', 'postalCode']),
      taxNumber: reader.getOptionalString('taxNumber', aliases: ['TaxNumber', 'gstNumber', 'GstNumber', 'gstin', 'GSTIN']),
      paymentTermsDays: reader.getInt('paymentTermsDays', aliases: ['PaymentTermsDays', 'paymentTerms'], defaultValue: 30),
      openingBalance: reader.getDouble('openingBalance', aliases: ['OpeningBalance', 'balance', 'Balance']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierCode': supplierCode,
      'supplierName': supplierName,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (taxNumber != null) 'taxNumber': taxNumber,
      'paymentTermsDays': paymentTermsDays,
      'openingBalance': openingBalance,
      'isActive': isActive,
    };
  }

  SupplierDto copyWith({
    int? id,
    String? supplierCode,
    String? supplierName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? taxNumber,
    int? paymentTermsDays,
    double? openingBalance,
    bool? isActive,
  }) {
    return SupplierDto(
      id: id ?? this.id,
      supplierCode: supplierCode ?? this.supplierCode,
      supplierName: supplierName ?? this.supplierName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      taxNumber: taxNumber ?? this.taxNumber,
      paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
      openingBalance: openingBalance ?? this.openingBalance,
      isActive: isActive ?? this.isActive,
    );
  }
}
