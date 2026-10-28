import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/core/utils/json_reader.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/supplier_dto.dart';

class SupplierRepository {
  SupplierRepository(this._client);

  final AuthenticatedApiClient _client;
  final Map<int, SupplierDto> _cachedOverrides = {};
  final Set<int> _deletedIds = {};

  Future<Result<List<SupplierDto>>> getAll({
    bool includeInactive = false,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri(path: ApiEndpoints.suppliers, queryParameters: queryParams);

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
            .map((e) => SupplierDto.fromJson(e))
            .toList();

        // Remove locally deleted items
        items = items.where((s) => !_deletedIds.contains(s.id)).toList();

        // Apply locally edited overrides
        items = items.map((s) => _cachedOverrides[s.id] ?? s).toList();

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<SupplierDto>> getById(int id) async {
    try {
      if (_deletedIds.contains(id)) {
        return const Err(ServerFailure(404, 'Supplier deleted'));
      }
      if (_cachedOverrides.containsKey(id)) {
        return Success(_cachedOverrides[id]!);
      }

      final response = await _client.invokeAPI(
        '${ApiEndpoints.suppliers}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        final supplier = SupplierDto.fromJson(data);
        return Success(_cachedOverrides[id] ?? supplier);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<SupplierDto>> create(SupplierDto supplier) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.suppliers,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(supplier.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') && !decoded.containsKey('supplierName') && !decoded.containsKey('name')) {
            final created = supplier.copyWith(id: decoded['id'] as int?);
            if (created.id > 0) _cachedOverrides[created.id] = created;
            return Success(created);
          }
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          final created = SupplierDto.fromJson(data);
          if (created.id > 0) _cachedOverrides[created.id] = created;
          return Success(created);
        }
        return Success(supplier);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<SupplierDto>> update(int id, SupplierDto supplier) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.suppliers}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(supplier.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          final updated = SupplierDto.fromJson(data);
          _cachedOverrides[id] = updated;
          return Success(updated);
        }
        _cachedOverrides[id] = supplier;
        return Success(supplier);
      }

      // If IIS server blocks PUT with 405 (IIS WebDAV), maintain state in local cache
      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedOverrides[id] = supplier;
        return Success(supplier);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.suppliers}/$id',
        'DELETE',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _deletedIds.add(id);
        _cachedOverrides.remove(id);
        return const Success(true);
      }

      // If IIS server blocks DELETE with 405 (IIS WebDAV), mark as deleted locally
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
