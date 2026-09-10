enum QualityResult {
  pass,
  fail,
  rework;

  static QualityResult fromString(String? val) {
    if (val == null) return QualityResult.pass;
    switch (val.toUpperCase()) {
      case 'FAIL':
        return QualityResult.fail;
      case 'REWORK':
        return QualityResult.rework;
      case 'PASS':
      default:
        return QualityResult.pass;
    }
  }

  String toApiValue() {
    switch (this) {
      case QualityResult.pass:
        return 'PASS';
      case QualityResult.fail:
        return 'FAIL';
      case QualityResult.rework:
        return 'REWORK';
    }
  }
}

class QualityCheckDto {
  const QualityCheckDto({
    required this.id,
    required this.productionOrderId,
    required this.productId,
    this.productName,
    this.productCode,
    required this.batchNo,
    required this.sampleQty,
    required this.passedQty,
    this.failedQty = 0.0,
    required this.result,
    this.checkedBy,
    required this.checkDate,
    this.remarks,
    this.isActive = true,
  });

  final int id;
  final int productionOrderId;
  final int productId;
  final String? productName;
  final String? productCode;
  final String batchNo;
  final double sampleQty;
  final double passedQty;
  final double failedQty;
  final QualityResult result;
  final String? checkedBy;
  final DateTime checkDate;
  final String? remarks;
  final bool isActive;

  bool get isPassed => result == QualityResult.pass;
  double get passRatePercent => sampleQty > 0 ? (passedQty / sampleQty) * 100.0 : 0.0;

  factory QualityCheckDto.fromJson(Map<String, dynamic> json) {
    return QualityCheckDto(
      id: json['id'] as int? ?? json['QualityCheckId'] as int? ?? 0,
      productionOrderId: json['productionOrderId'] as int? ?? json['ProductionOrderId'] as int? ?? 0,
      productId: json['productId'] as int? ?? json['ProductId'] as int? ?? 0,
      productName: json['productName'] as String? ?? json['ProductName'] as String?,
      productCode: json['productCode'] as String? ?? json['ProductCode'] as String?,
      batchNo: json['batchNo'] as String? ?? json['BatchNo'] as String? ?? '',
      sampleQty: (json['sampleQty'] as num? ?? json['SampleQty'] as num? ?? 0.0).toDouble(),
      passedQty: (json['passedQty'] as num? ?? json['PassedQty'] as num? ?? 0.0).toDouble(),
      failedQty: (json['failedQty'] as num? ?? json['FailedQty'] as num? ?? 0.0).toDouble(),
      result: QualityResult.fromString(json['result'] as String? ?? json['Result'] as String?),
      checkedBy: json['checkedBy'] as String? ?? json['CheckedBy'] as String?,
      checkDate: json['checkDate'] != null
          ? DateTime.parse(json['checkDate'].toString())
          : (json['CheckDate'] != null
              ? DateTime.parse(json['CheckDate'].toString())
              : DateTime.now()),
      remarks: json['remarks'] as String? ?? json['Remarks'] as String?,
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productionOrderId': productionOrderId,
      'productId': productId,
      if (productName != null) 'productName': productName,
      if (productCode != null) 'productCode': productCode,
      'batchNo': batchNo,
      'sampleQty': sampleQty,
      'passedQty': passedQty,
      'failedQty': failedQty,
      'result': result.toApiValue(),
      if (checkedBy != null) 'checkedBy': checkedBy,
      'checkDate': checkDate.toIso8601String(),
      if (remarks != null) 'remarks': remarks,
      'isActive': isActive,
    };
  }
}
