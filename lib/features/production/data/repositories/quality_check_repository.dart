import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/quality_check_dto.dart';

class QualityCheckRepository {
  QualityCheckRepository(this._client);
  final AuthenticatedApiClient _client;

  Future<Result<List<QualityCheckDto>>> getAll({
    int? productionOrderId,
    int? productId,
    QualityResult? result,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (productionOrderId != null && productionOrderId > 0)
          'productionOrderId': productionOrderId.toString(),
        if (productId != null && productId > 0) 'productId': productId.toString(),
        if (result != null) 'result': result.toApiValue(),
      };

      final uri = Uri(path: ApiEndpoints.qualityChecks, queryParameters: queryParams);
      final response = await _client.invokeAPI(
        uri.toString(),
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : [];
        final items = list.map((e) => QualityCheckDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<QualityCheckDto>> create(QualityCheckDto qc) async {
    try {
      final uri = Uri(path: ApiEndpoints.qualityChecks);
      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(qc.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : <String, dynamic>{};
        return Success(QualityCheckDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }
}
