import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/production_order_dto.dart';
import '../models/production_stage_dto.dart';
import '../models/production_stage_entry_dto.dart';
import '../models/production_material_issue_dto.dart';
import '../models/production_output_dto.dart';

class ProductionRepository {
  ProductionRepository(this._client);
  final AuthenticatedApiClient _client;

  Future<Result<List<ProductionOrderDto>>> getAll({
    bool includeInactive = false,
    ProductionStatus? status,
    int? productId,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (status != null) 'status': status.toApiValue(),
        if (productId != null && productId > 0) 'productId': productId.toString(),
      };

      final uri = Uri(path: ApiEndpoints.productionOrders, queryParameters: queryParams);
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
        final items = list.map((e) => ProductionOrderDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<ProductionOrderDto>> getById(int id) async {
    try {
      final uri = Uri(path: '${ApiEndpoints.productionOrders}/$id');
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
        return Success(ProductionOrderDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<ProductionOrderDto>> create(ProductionOrderDto order) async {
    try {
      final uri = Uri(path: ApiEndpoints.productionOrders);
      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(order.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : <String, dynamic>{};
        return Success(ProductionOrderDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<ProductionOrderDto>> updateStatus(int id, ProductionStatus status) async {
    try {
      final uri = Uri(path: '${ApiEndpoints.productionOrders}/$id/status');
      final response = await _client.invokeAPI(
        uri.toString(),
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode({'status': status.toApiValue()}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : <String, dynamic>{};
        return Success(ProductionOrderDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<List<ProductionStageDto>>> listStages() async {
    try {
      final uri = Uri(path: ApiEndpoints.productionStages);
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
        final items = list.map((e) => ProductionStageDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<bool>> issueMaterial(ProductionMaterialIssueDto issue) async {
    try {
      final uri = Uri(path: ApiEndpoints.productionMaterialIssues);
      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(issue.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(true);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<bool>> updateStageEntry(ProductionStageEntryDto entry) async {
    try {
      final uri = Uri(path: ApiEndpoints.productionStageEntries);
      final response = await _client.invokeAPI(
        uri.toString(),
        entry.id > 0 ? 'PUT' : 'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(entry.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(true);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<bool>> recordOutput(ProductionOutputDto output) async {
    try {
      final uri = Uri(path: ApiEndpoints.productionOutputs);
      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(output.toJson()),
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
