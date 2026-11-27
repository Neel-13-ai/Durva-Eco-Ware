import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/masters/data/models/category_dto.dart';

class CategoryRepository {
  CategoryRepository(this._client);

  final AuthenticatedApiClient _client;

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
        final items = list.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<CategoryDto>> getById(int id) async {
    try {
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
        return Success(CategoryDto.fromJson(data));
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
          final hasName = decoded.containsKey('categoryName') ||
              decoded.containsKey('CategoryName') ||
              decoded.containsKey('name');
          if (!hasName) {
            final rawId = decoded['id'] ?? decoded['categoryId'] ?? decoded['CategoryId'];
            return Success(
              category.copyWith(id: rawId is int ? rawId : int.tryParse('$rawId')),
            );
          }
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          return Success(CategoryDto.fromJson(data));
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
        ApiEndpoints.update(ApiEndpoints.categories, id),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(category.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          final hasFields = data.containsKey('categoryName') ||
              data.containsKey('CategoryName') ||
              data.containsKey('name');
          if (hasFields) {
            return Success(CategoryDto.fromJson(data));
          }
        }
        return Success(category.copyWith(id: id));
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.delete(ApiEndpoints.categories, id),
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
