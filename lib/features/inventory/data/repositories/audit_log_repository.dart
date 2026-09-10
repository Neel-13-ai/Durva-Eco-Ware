import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/audit_log_dto.dart';

class AuditLogRepository {
  AuditLogRepository(this._client);
  final AuthenticatedApiClient _client;

  Future<Result<List<AuditLogDto>>> listAuditLogs({
    String? tableName,
    int? recordId,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (tableName != null && tableName.isNotEmpty) 'tableName': tableName,
        if (recordId != null) 'recordId': recordId.toString(),
      };

      final uri = Uri(path: ApiEndpoints.auditLogs, queryParameters: queryParams);
      final response = await _client.invokeAPI(
        uri.toString(),
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> ? (decoded['data'] as List<dynamic>? ?? []) : []);

        final list = data
            .map((item) => AuditLogDto.fromJson(item as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }
}
