import 'bom_detail_dto.dart';

class BomHeaderDto {
  const BomHeaderDto({
    required this.id,
    required this.bomCode,
    required this.finishedProductId,
    this.finishedProductName,
    this.finishedProductCode,
    this.finishedProductUnit,
    this.versionNo = '1.0',
    this.batchSize = 1000.0,
    required this.effectiveFrom,
    this.effectiveTo,
    this.notes,
    this.isActive = true,
    this.items = const [],
  });

  final int id;
  final String bomCode;
  final int finishedProductId;
  final String? finishedProductName;
  final String? finishedProductCode;
  final String? finishedProductUnit;
  final String versionNo;
  final double batchSize;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? notes;
  final bool isActive;
  final List<BomDetailDto> items;

  /// Total recipe cost to manufacture this batch size
  double get totalBatchCost => items.fold(0.0, (sum, item) => sum + item.itemCost);

  /// Production cost per unit
  double get costPerUnit => batchSize > 0 ? totalBatchCost / batchSize : 0.0;

  /// Total component count in recipe
  int get componentCount => items.length;

  /// Whether this BOM recipe is currently in its active validity period
  bool get isEffectiveNow {
    if (!isActive) return false;
    final now = DateTime.now();
    final afterStart = effectiveFrom.isBefore(now) || effectiveFrom.isAtSameMomentAs(now);
    final beforeEnd = effectiveTo == null || effectiveTo!.isAfter(now);
    return afterStart && beforeEnd;
  }

  factory BomHeaderDto.fromJson(Map<String, dynamic> json) {
    List<BomDetailDto> parseItems(dynamic rawItems) {
      if (rawItems is List) {
        return rawItems
            .map((e) => BomDetailDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    }

    return BomHeaderDto(
      id: json['id'] as int? ?? json['BOMHeaderId'] as int? ?? 0,
      bomCode: json['bomCode'] as String? ?? json['BOMCode'] as String? ?? '',
      finishedProductId: json['finishedProductId'] as int? ?? json['FinishedProductId'] as int? ?? 0,
      finishedProductName: json['finishedProductName'] as String? ?? json['FinishedProductName'] as String?,
      finishedProductCode: json['finishedProductCode'] as String? ?? json['FinishedProductCode'] as String?,
      finishedProductUnit: json['finishedProductUnit'] as String? ?? json['FinishedProductUnit'] as String?,
      versionNo: json['versionNo'] as String? ?? json['VersionNo'] as String? ?? '1.0',
      batchSize: (json['batchSize'] as num? ?? json['BatchSize'] as num? ?? 1000.0).toDouble(),
      effectiveFrom: json['effectiveFrom'] != null
          ? DateTime.parse(json['effectiveFrom'].toString())
          : (json['EffectiveFrom'] != null
              ? DateTime.parse(json['EffectiveFrom'].toString())
              : DateTime.now()),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.parse(json['effectiveTo'].toString())
          : (json['EffectiveTo'] != null
              ? DateTime.parse(json['EffectiveTo'].toString())
              : null),
      notes: json['notes'] as String? ?? json['Notes'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
      items: parseItems(json['items'] ?? json['BOMDetails'] ?? json['bomDetails'] ?? json['details']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bomCode': bomCode,
      'finishedProductId': finishedProductId,
      if (finishedProductName != null) 'finishedProductName': finishedProductName,
      if (finishedProductCode != null) 'finishedProductCode': finishedProductCode,
      if (finishedProductUnit != null) 'finishedProductUnit': finishedProductUnit,
      'versionNo': versionNo,
      'batchSize': batchSize,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      if (effectiveTo != null) 'effectiveTo': effectiveTo!.toIso8601String(),
      if (notes != null) 'notes': notes,
      'isActive': isActive,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  BomHeaderDto copyWith({
    int? id,
    String? bomCode,
    int? finishedProductId,
    String? finishedProductName,
    String? finishedProductCode,
    String? finishedProductUnit,
    String? versionNo,
    double? batchSize,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? notes,
    bool? isActive,
    List<BomDetailDto>? items,
  }) {
    return BomHeaderDto(
      id: id ?? this.id,
      bomCode: bomCode ?? this.bomCode,
      finishedProductId: finishedProductId ?? this.finishedProductId,
      finishedProductName: finishedProductName ?? this.finishedProductName,
      finishedProductCode: finishedProductCode ?? this.finishedProductCode,
      finishedProductUnit: finishedProductUnit ?? this.finishedProductUnit,
      versionNo: versionNo ?? this.versionNo,
      batchSize: batchSize ?? this.batchSize,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      items: items ?? this.items,
    );
  }
}
