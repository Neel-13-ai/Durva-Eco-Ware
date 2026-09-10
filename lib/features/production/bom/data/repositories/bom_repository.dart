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
                : [];
        final items = list.map((e) => BomHeaderDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<BomHeaderDto>> getById(int id) async {
    try {
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
        return Success(bom);
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
        jsonEncode(bom.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : <String, dynamic>{};
        return Success(BomHeaderDto.fromJson(data));
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
        jsonEncode(bom.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : <String, dynamic>{};
        return Success(BomHeaderDto.fromJson(data));
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
        return const Success(true);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }
}
