class ExpenseCategoryDto {
  final int id;
  final String categoryName;
  final String? description;
  final bool isActive;

  const ExpenseCategoryDto({
    required this.id,
    required this.categoryName,
    this.description,
    this.isActive = true,
  });

  factory ExpenseCategoryDto.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryDto(
      id: json['id'] as int? ??
          json['Id'] as int? ??
          json['expenseCategoryId'] as int? ??
          json['ExpenseCategoryId'] as int? ??
          0,
      categoryName: json['categoryName']?.toString() ??
          json['CategoryName']?.toString() ??
          json['expenseCategoryName']?.toString() ??
          json['ExpenseCategoryName']?.toString() ??
          json['name']?.toString() ??
          json['Name']?.toString() ??
          '',
      description: json['description']?.toString() ?? json['Description']?.toString(),
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toApiJson({bool isUpdate = false}) {
    return {
      if (isUpdate && id > 0) 'id': id,
      'categoryName': categoryName,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'categoryName': categoryName,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }

  ExpenseCategoryDto copyWith({
    int? id,
    String? categoryName,
    String? description,
    bool? isActive,
  }) {
    return ExpenseCategoryDto(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
