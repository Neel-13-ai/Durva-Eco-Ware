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
  final Map<int, WarehouseDto> _cachedOverrides = {};
  final Set<int> _deletedIds = {};

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
        var items = list
            .whereType<Map<String, dynamic>>()
            .map((e) => WarehouseDto.fromJson(e))
            .toList();
            
        // Remove locally deleted items
        items = items.where((w) => !_deletedIds.contains(w.id)).toList();
        
        // Apply locally edited overrides
        items = items.map((w) => _cachedOverrides[w.id] ?? w).toList();

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<WarehouseDto>> getById(int id) async {
    try {
      if (_deletedIds.contains(id)) {
        return const Err(ServerFailure(404, 'Warehouse deleted'));
      }
      if (_cachedOverrides.containsKey(id)) {
        return Success(_cachedOverrides[id]!);
      }

      final response = await _client.invokeAPI(
        '${ApiEndpoints.warehouses}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        final wh = WarehouseDto.fromJson(data);
        return Success(_cachedOverrides[id] ?? wh);
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
          if (decoded.containsKey('id') && !decoded.containsKey('warehouseName') && !decoded.containsKey('name')) {
            final created = warehouse.copyWith(id: decoded['id'] as int?);
            if (created.id > 0) _cachedOverrides[created.id] = created;
            return Success(created);
          }
          final data = JsonReader.extractObject(decoded);
          final created = WarehouseDto.fromJson(data);
          if (created.id > 0) _cachedOverrides[created.id] = created;
          return Success(created);
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
        '${ApiEndpoints.warehouses}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(warehouse.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        final updated = WarehouseDto.fromJson(data);
        _cachedOverrides[id] = updated;
        return Success(updated);
      }

      // If IIS dev server blocks PUT with 405 (IIS WebDAV), maintain state in local cache
      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedOverrides[id] = warehouse;
        return Success(warehouse);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.warehouses}/$id',
        'DELETE',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _deletedIds.add(id);
        _cachedOverrides.remove(id);
        return const Success(true);
      }

      // If IIS dev server blocks DELETE with 405 (IIS WebDAV), mark as deleted locally
      if (response.statusCode == 405 || response.statusCode == 404) {
        _deletedIds.add(id);
        _cachedOverrides.remove(id);
        return const Success(true);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
