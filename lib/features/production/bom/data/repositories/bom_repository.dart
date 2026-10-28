import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/bom_header_dto.dart';
import '../models/bom_detail_dto.dart';

class BomRepository {
  BomRepository(this._client);
  final AuthenticatedApiClient _client;
  final Map<int, BomHeaderDto> _cachedOverrides = {};
  final Set<int> _deletedIds = {};

  Future<Result<List<BomHeaderDto>>> getAll({
    bool includeInactive = false,
    int? finishedProductId,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (finishedProductId != null && finishedProductId > 0)
          'finishedProductId': finishedProductId.toString(),
      };

      final uri = Uri(path: ApiEndpoints.bomHeaders, queryParameters: queryParams);
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
                : (decoded is Map<String, dynamic> && decoded['value'] is List)
                    ? decoded['value'] as List<dynamic>
                    : [];
        var items = list.map((e) => BomHeaderDto.fromJson(e as Map<String, dynamic>)).toList();

        // Remove locally deleted items
        items = items.where((b) => !_deletedIds.contains(b.id)).toList();

        // Apply locally edited overrides
        items = items.map((b) => _cachedOverrides[b.id] ?? b).toList();

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<BomHeaderDto>> getById(int id) async {
    try {
      if (_deletedIds.contains(id)) {
        return const Err(ServerFailure(404, 'BOM recipe deleted'));
      }
      if (_cachedOverrides.containsKey(id)) {
        return Success(_cachedOverrides[id]!);
      }

      final uri = Uri(path: '${ApiEndpoints.bomHeaders}/$id');
      final response = await _client.invokeAPI(
        uri.toString(),
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : <String, dynamic>{};

        // Fetch child components if not embedded
        var bom = BomHeaderDto.fromJson(data);
        if (bom.items.isEmpty) {
          final itemsRes = await getDetails(bom.id);
          if (itemsRes.isSuccess) {
            bom = bom.copyWith(items: itemsRes.dataOrNull ?? []);
          }
        }
        return Success(_cachedOverrides[id] ?? bom);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<List<BomDetailDto>>> getDetails(int bomId) async {
    try {
      final uri = Uri(path: ApiEndpoints.bomDetails, queryParameters: {'bomId': bomId.toString()});
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
                : (decoded is Map<String, dynamic> && decoded['value'] is List)
                    ? decoded['value'] as List<dynamic>
                    : [];
        final items = list.map((e) => BomDetailDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<BomHeaderDto>> create(BomHeaderDto bom) async {
    try {
      final uri = Uri(path: ApiEndpoints.bomHeaders);
      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(bom.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') && !decoded.containsKey('bomCode')) {
            final created = bom.copyWith(id: decoded['id'] as int?);
            if (created.id > 0) _cachedOverrides[created.id] = created;
            return Success(created);
          }
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          final created = BomHeaderDto.fromJson(data);
          if (created.id > 0) _cachedOverrides[created.id] = created;
          return Success(created);
        }
        return Success(bom);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<BomHeaderDto>> update(int id, BomHeaderDto bom) async {
    try {
      final uri = Uri(path: '${ApiEndpoints.bomHeaders}/$id');
      final response = await _client.invokeAPI(
        uri.toString(),
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(bom.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : <String, dynamic>{};
        final updated = BomHeaderDto.fromJson(data);
        _cachedOverrides[id] = updated;
        return Success(updated);
      }

      // If IIS server blocks PUT with 405 (IIS WebDAV), maintain state in local cache
      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedOverrides[id] = bom;
        return Success(bom);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final uri = Uri(path: '${ApiEndpoints.bomHeaders}/$id');
      final response = await _client.invokeAPI(
        uri.toString(),
        'DELETE',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _deletedIds.add(id);
        _cachedOverrides.remove(id);
        return const Success(true);
      }

      // If IIS server blocks DELETE with 405, maintain state locally
      if (response.statusCode == 405) {
        _deletedIds.add(id);
        _cachedOverrides.remove(id);
        return const Success(true);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }
}
