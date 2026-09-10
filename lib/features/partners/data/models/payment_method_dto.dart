import '../../../../core/utils/json_reader.dart';

class PaymentMethodDto {
  const PaymentMethodDto({
    required this.id,
    required this.methodName,
    this.description,
    this.isActive = true,
  });

  final int id;
  final String methodName;
  final String? description;
  final bool isActive;

  factory PaymentMethodDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PaymentMethodDto(
      id: reader.getInt('id', aliases: ['paymentMethodId', 'PaymentMethodId', 'Id']),
      methodName: reader.getString('methodName', aliases: ['MethodName', 'name', 'Name']),
      description: reader.getOptionalString('description', aliases: ['Description']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'methodName': methodName,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }

  PaymentMethodDto copyWith({
    int? id,
    String? methodName,
    String? description,
    bool? isActive,
  }) {
    return PaymentMethodDto(
      id: id ?? this.id,
      methodName: methodName ?? this.methodName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
