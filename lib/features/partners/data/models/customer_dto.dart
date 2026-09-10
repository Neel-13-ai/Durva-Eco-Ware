import '../../../../core/utils/json_reader.dart';

class CustomerDto {
  const CustomerDto({
    required this.id,
    required this.customerCode,
    required this.customerName,
    this.companyName,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.taxNumber,
    this.creditLimit = 0.0,
    this.openingBalance = 0.0,
    this.isActive = true,
  });

  final int id;
  final String customerCode;
  final String customerName;
  final String? companyName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? taxNumber;
  final double creditLimit;
  final double openingBalance;
  final bool isActive;

  factory CustomerDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return CustomerDto(
      id: reader.getInt('id', aliases: ['customerId', 'CustomerId', 'Id']),
      customerCode: reader.getString('customerCode', aliases: ['CustomerCode', 'code', 'Code']),
      customerName: reader.getString('customerName', aliases: ['CustomerName', 'name', 'Name']),
      companyName: reader.getOptionalString('companyName', aliases: ['CompanyName']),
      contactPerson: reader.getOptionalString('contactPerson', aliases: ['ContactPerson', 'contactName']),
      phone: reader.getOptionalString('phone', aliases: ['Phone', 'contactNumber', 'ContactNumber', 'mobile']),
      email: reader.getOptionalString('email', aliases: ['Email']),
      address: reader.getOptionalString('address', aliases: ['Address']),
      city: reader.getOptionalString('city', aliases: ['City']),
      state: reader.getOptionalString('state', aliases: ['State']),
      zipCode: reader.getOptionalString('zipCode', aliases: ['ZipCode', 'pincode', 'Pincode', 'postalCode']),
      taxNumber: reader.getOptionalString('taxNumber', aliases: ['TaxNumber', 'gstNumber', 'GstNumber', 'gstin', 'GSTIN']),
      creditLimit: reader.getDouble('creditLimit', aliases: ['CreditLimit', 'limit', 'Limit']),
      openingBalance: reader.getDouble('openingBalance', aliases: ['OpeningBalance', 'balance', 'Balance']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerCode': customerCode,
      'customerName': customerName,
      if (companyName != null) 'companyName': companyName,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (taxNumber != null) 'taxNumber': taxNumber,
      'creditLimit': creditLimit,
      'openingBalance': openingBalance,
      'isActive': isActive,
    };
  }

  CustomerDto copyWith({
    int? id,
    String? customerCode,
    String? customerName,
    String? companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? taxNumber,
    double? creditLimit,
    double? openingBalance,
    bool? isActive,
  }) {
    return CustomerDto(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      taxNumber: taxNumber ?? this.taxNumber,
      creditLimit: creditLimit ?? this.creditLimit,
      openingBalance: openingBalance ?? this.openingBalance,
      isActive: isActive ?? this.isActive,
    );
  }
}
