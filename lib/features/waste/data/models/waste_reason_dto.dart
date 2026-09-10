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
      reasonName: json['reasonName'] as String? ?? json['ReasonName'] as String? ?? '',
      description: json['description'] as String? ?? json['Description'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reasonName': reasonName,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }
}
