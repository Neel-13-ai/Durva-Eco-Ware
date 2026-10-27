import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/core/utils/json_reader.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';

class ProductRepository {
  ProductRepository(this._client);

  final AuthenticatedApiClient _client;

  Future<Result<List<ProductDto>>> getAll({
    bool includeInactive = false,
    String? search,
    int? categoryId,
    ProductType? productType,
  }) async {
    try {
      String? typeToString(ProductType? t) {
        if (t == null) return null;
        switch (t) {
          case ProductType.rawMaterial:
            return 'RAW_MATERIAL';
          case ProductType.packaging:
            return 'PACKAGING';
          case ProductType.finishedGood:
            return 'FINISHED_GOOD';
        }
      }

      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId > 0) 'categoryId': categoryId.toString(),
        if (productType != null) 'productType': typeToString(productType)!,
      };
      final uri = Uri(path: ApiEndpoints.products, queryParameters: queryParams);

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
            .map((e) => ProductDto.fromJson(e))
            .toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ProductDto>> getById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.products}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(ProductDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ProductDto>> create(ProductDto product) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.products,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(product.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') && !decoded.containsKey('name')) {
            return Success(product.copyWith(id: decoded['id'] as int?));
          }
          final data = JsonReader.extractObject(decoded);
          if (data.isNotEmpty && data.containsKey('name')) {
            return Success(ProductDto.fromJson(data));
          }
        }
        return Success(product);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ProductDto>> update(int id, ProductDto product) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.products}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(product.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = JsonReader.extractObject(decoded);
          if (data.isNotEmpty && data.containsKey('name')) {
            return Success(ProductDto.fromJson(data));
          }
        }
        return Success(product);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.products}/$id',
        'DELETE',
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
