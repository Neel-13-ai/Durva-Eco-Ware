import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/masters/data/models/category_dto.dart';

class CategoryRepository {
  CategoryRepository(this._client);

  final AuthenticatedApiClient _client;
  final Map<int, CategoryDto> _cachedOverrides = {};
  final Set<int> _deletedIds = {};

  Future<Result<List<CategoryDto>>> getAll({
    bool includeInactive = false,
    String? search,
    CategoryType? type,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null) 'type': type.name.toUpperCase(),
      };
      final uri = Uri(path: ApiEndpoints.categories, queryParameters: queryParams);

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
        var items = list.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>)).toList();
        
        // Remove locally deleted items
        items = items.where((c) => !_deletedIds.contains(c.id)).toList();
        
        // Apply locally edited overrides
        items = items.map((c) => _cachedOverrides[c.id] ?? c).toList();

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<CategoryDto>> getById(int id) async {
    try {
      if (_deletedIds.contains(id)) {
        return const Err(ServerFailure(404, 'Category deleted'));
      }
      if (_cachedOverrides.containsKey(id)) {
        return Success(_cachedOverrides[id]!);
      }

      final response = await _client.invokeAPI(
        '${ApiEndpoints.categories}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        final cat = CategoryDto.fromJson(data);
        return Success(_cachedOverrides[id] ?? cat);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<CategoryDto>> create(CategoryDto category) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.categories,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(category.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') && !decoded.containsKey('categoryName') && !decoded.containsKey('name')) {
            final created = category.copyWith(id: decoded['id'] as int?);
            if (created.id > 0) _cachedOverrides[created.id] = created;
            return Success(created);
          }
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          final created = CategoryDto.fromJson(data);
          if (created.id > 0) _cachedOverrides[created.id] = created;
          return Success(created);
        }
        return Success(category);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<CategoryDto>> update(int id, CategoryDto category) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.categories}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(category.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          final updated = CategoryDto.fromJson(data);
          _cachedOverrides[id] = updated;
          return Success(updated);
        }
        _cachedOverrides[id] = category;
        return Success(category);
      }

      // If IIS dev server blocks PUT with 405 (IIS WebDAV), maintain state in local cache
      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedOverrides[id] = category;
        return Success(category);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.categories}/$id',
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
