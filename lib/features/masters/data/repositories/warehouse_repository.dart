import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/core/utils/json_reader.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';

class WarehouseRepository {
  WarehouseRepository(this._client);

  final AuthenticatedApiClient _client;

  Future<Result<List<WarehouseDto>>> getAll({
    bool includeInactive = false,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri(path: ApiEndpoints.warehouses, queryParameters: queryParams);

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
            .map((e) => WarehouseDto.fromJson(e))
            .toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<WarehouseDto>> getById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.warehouses}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(WarehouseDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<WarehouseDto>> create(WarehouseDto warehouse) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.warehouses,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(warehouse.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final hasName = decoded.containsKey('warehouseName') ||
              decoded.containsKey('WarehouseName') ||
              decoded.containsKey('name');
          if (!hasName) {
            final rawId = decoded['id'] ?? decoded['warehouseId'] ?? decoded['WarehouseId'];
            return Success(
              warehouse.copyWith(id: rawId is int ? rawId : int.tryParse('$rawId')),
            );
          }
          final data = JsonReader.extractObject(decoded);
          return Success(WarehouseDto.fromJson(data));
        }
        return Success(warehouse);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<WarehouseDto>> update(int id, WarehouseDto warehouse) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.update(ApiEndpoints.warehouses, id),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(warehouse.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = JsonReader.extractObject(decoded);
          final hasFields = data.containsKey('warehouseName') ||
              data.containsKey('WarehouseName') ||
              data.containsKey('name');
          if (hasFields) {
            return Success(WarehouseDto.fromJson(data));
          }
        }
        return Success(warehouse.copyWith(id: id));
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.delete(ApiEndpoints.warehouses, id),
        'POST',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(true);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
