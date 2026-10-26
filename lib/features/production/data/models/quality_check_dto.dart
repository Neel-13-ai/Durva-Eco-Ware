import '../../../../core/utils/json_reader.dart';

enum QualityResult {
  pass,
  fail,
  rework;

  static QualityResult fromString(dynamic val) {
    if (val == null) return QualityResult.pass;
    final s = val.toString().toUpperCase().trim();
    switch (s) {
      case 'FAIL':
      case '1':
        return QualityResult.fail;
      case 'REWORK':
      case '2':
        return QualityResult.rework;
      case 'PASS':
      case '0':
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
    final reader = JsonReader(json);
    return QualityCheckDto(
      id: reader.getInt('id', aliases: ['Id', 'QualityCheckId', 'qualityCheckId']),
      productionOrderId: reader.getInt('productionOrderId', aliases: ['ProductionOrderId']),
      productId: reader.getInt('productId', aliases: ['ProductId']),
      productName: reader.getOptionalString('productName', aliases: ['ProductName']),
      productCode: reader.getOptionalString('productCode', aliases: ['ProductCode']),
      batchNo: reader.getString('batchNo', aliases: ['BatchNo'], defaultValue: ''),
      sampleQty: reader.getDouble('sampleQty', aliases: ['SampleQty', 'quantity', 'Quantity']),
      passedQty: reader.getDouble('passedQty', aliases: ['PassedQty', 'passQty', 'PassQty']),
      failedQty: reader.getDouble('failedQty', aliases: ['FailedQty', 'failQty', 'FailQty']),
      result: QualityResult.fromString(reader.getOptionalString('result', aliases: ['Result', 'status', 'Status'])),
      checkedBy: reader.getOptionalString('checkedBy', aliases: ['CheckedBy', 'inspector', 'Inspector']),
      checkDate: reader.getDateTime('checkDate', aliases: ['CheckDate', 'date', 'Date']) ?? DateTime.now(),
      remarks: reader.getOptionalString('remarks', aliases: ['Remarks', 'notes', 'Notes']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
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
