class WasteReasonDto {
  const WasteReasonDto({
    required this.id,
    required this.reasonName,
    this.description,
    this.isActive = true,
  });

  final int id;
  final String reasonName;
  final String? description;
  final bool isActive;

  factory WasteReasonDto.fromJson(Map<String, dynamic> json) {
    return WasteReasonDto(
      id: json['id'] as int? ?? json['WasteReasonId'] as int? ?? json['wasteReasonId'] as int? ?? 0,
      reasonName: json['reasonName']?.toString() ?? json['ReasonName']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? json['Description']?.toString(),
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'reasonName': reasonName,
      if (id > 0) 'isActive': isActive,
    };
  }
}
