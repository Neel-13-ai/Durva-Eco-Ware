import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/stock_balance_dto.dart';
import '../models/stock_adjustment_request.dart';

class InventoryRepository {
  InventoryRepository(this._client);
  final AuthenticatedApiClient _client;

  Future<Result<List<StockBalanceDto>>> listStockBalances({
    int? warehouseId,
    String? productType,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (warehouseId != null) 'warehouseId': warehouseId.toString(),
        if (productType != null && productType.isNotEmpty) 'productType': productType,
      };

      final uri = Uri(path: ApiEndpoints.stockBalances, queryParameters: queryParams);
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
            .map((item) => StockBalanceDto.fromJson(item as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<StockBalanceDto>> getStockBalance(int id) async {
    try {
      final uri = Uri(path: '${ApiEndpoints.stockBalances}/$id');
      final response = await _client.invokeAPI(
        uri.toString(),
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? decoded
            : (decoded['data'] as Map<String, dynamic>);
        return Success(StockBalanceDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<StockBalanceDto>> adjustStock(StockAdjustmentRequest request) async {
    try {
      final uri = Uri(path: ApiEndpoints.stockTransactions);
      final payload = {
        'productId': request.productId,
        'warehouseId': request.warehouseId,
        'transactionType': 'ADJUSTMENT',
        'quantityIn': request.mode == AdjustmentMode.increase ? request.quantity : 0.0,
        'quantityOut': request.mode == AdjustmentMode.decrease ? request.quantity : 0.0,
        'unitCost': request.unitCost,
        'notes': '${request.reason}: ${request.notes ?? ""}',
        'transactionDate': DateTime.now().toIso8601String(),
      };

      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? decoded
            : (decoded is Map ? (decoded['data'] as Map<String, dynamic>? ?? {}) : <String, dynamic>{});
        return Success(StockBalanceDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }
}
