class AuditLogDto {
  const AuditLogDto({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.action,
    this.changedBy,
    this.oldValues,
    this.newValues,
    required this.changeDate,
  });

  final int id;
  final String tableName;
  final int recordId;
  final String action;
  final String? changedBy;
  final String? oldValues;
  final String? newValues;
  final DateTime changeDate;

  factory AuditLogDto.fromJson(Map<String, dynamic> json) {
    return AuditLogDto(
      id: json['id'] as int? ?? json['AuditLogId'] as int? ?? 0,
      tableName: json['tableName'] as String? ?? json['TableName'] as String? ?? '',
      recordId: json['recordId'] as int? ?? json['RecordId'] as int? ?? 0,
      action: json['action'] as String? ?? json['Action'] as String? ?? '',
      changedBy: json['changedBy'] as String? ?? json['ChangedBy'] as String?,
      oldValues: json['oldValues'] as String? ?? json['OldValues'] as String?,
      newValues: json['newValues'] as String? ?? json['NewValues'] as String?,
      changeDate: json['changeDate'] != null
          ? DateTime.parse(json['changeDate'].toString())
          : (json['ChangeDate'] != null
              ? DateTime.parse(json['ChangeDate'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableName': tableName,
      'recordId': recordId,
      'action': action,
      if (changedBy != null) 'changedBy': changedBy,
      if (oldValues != null) 'oldValues': oldValues,
      if (newValues != null) 'newValues': newValues,
      'changeDate': changeDate.toIso8601String(),
    };
  }
}
