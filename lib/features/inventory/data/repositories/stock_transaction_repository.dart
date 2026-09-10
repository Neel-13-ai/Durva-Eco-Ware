import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/stock_transaction_dto.dart';

class StockTransactionRepository {
  StockTransactionRepository(this._client);
  final AuthenticatedApiClient _client;

  Future<Result<List<StockTransactionDto>>> listTransactions({
    int? productId,
    int? warehouseId,
    StockTransactionType? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (productId != null) 'productId': productId.toString(),
        if (warehouseId != null) 'warehouseId': warehouseId.toString(),
        if (type != null) 'type': type.toApiValue(),
        if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
      };

      final uri = Uri(path: ApiEndpoints.stockTransactions, queryParameters: queryParams);
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
            .map((item) => StockTransactionDto.fromJson(item as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<StockTransactionDto>> createTransaction(StockTransactionDto dto) async {
    try {
      final uri = Uri(path: ApiEndpoints.stockTransactions);
      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(dto.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? decoded
            : (decoded is Map ? (decoded['data'] as Map<String, dynamic>? ?? {}) : <String, dynamic>{});
        return Success(StockTransactionDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }
}
