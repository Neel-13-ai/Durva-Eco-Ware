import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/core/utils/json_reader.dart';
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
        final list = JsonReader.extractList(decoded);
        final items = list
            .whereType<Map<String, dynamic>>()
            .map((item) => StockBalanceDto.fromJson(item))
            .toList();
        return Success(items);
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
        final data = JsonReader.extractObject(decoded);
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
        StockBalanceDto balance;
        try {
          final dynamic decoded = jsonDecode(response.body);
          final data = JsonReader.extractObject(decoded);
          if (data.containsKey('productId') && data['productId'] != null && (data['productId'] as num) > 0) {
            balance = StockBalanceDto.fromJson(data);
          } else {
            balance = StockBalanceDto(
              id: (data['id'] as num?)?.toInt() ?? 0,
              productId: request.productId,
              warehouseId: request.warehouseId,
              quantity: request.quantity,
              averageCost: request.unitCost,
            );
          }
        } catch (_) {
          balance = StockBalanceDto(
            id: 0,
            productId: request.productId,
            warehouseId: request.warehouseId,
            quantity: request.quantity,
            averageCost: request.unitCost,
          );
        }
        return Success(balance);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<StockBalanceDto>> createStockBalance(Map<String, dynamic> payload) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.stockBalances,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(StockBalanceDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<StockBalanceDto>> updateStockBalance(int id, Map<String, dynamic> payload) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.stockBalances}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(StockBalanceDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<bool>> deleteStockBalance(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.stockBalances}/$id',
        'DELETE',
        {'Content-Type': 'application/json'},
        null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(true);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }
}
