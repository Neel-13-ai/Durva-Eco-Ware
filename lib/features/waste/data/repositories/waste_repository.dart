import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/core/utils/json_reader.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/waste_reason_dto.dart';
import '../models/waste_entry_dto.dart';

class WasteRepository {
  WasteRepository(this._client);
  final AuthenticatedApiClient _client;

  Future<Result<List<WasteReasonDto>>> listReasons({bool includeInactive = false}) async {
    try {
      final uri = Uri(
        path: ApiEndpoints.wasteReasons,
        queryParameters: {'includeInactive': includeInactive.toString()},
      );
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
            .map((e) => WasteReasonDto.fromJson(e))
            .toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<WasteReasonDto>> createReason(WasteReasonDto reason) async {
    try {
      final uri = Uri(path: ApiEndpoints.wasteReasons);
      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(reason.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(WasteReasonDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<List<WasteEntryDto>>> listEntries({
    int? productId,
    int? reasonId,
    DisposalMethod? disposalMethod,
    int? warehouseId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (productId != null && productId > 0) 'productId': productId.toString(),
        if (reasonId != null && reasonId > 0) 'reasonId': reasonId.toString(),
        if (disposalMethod != null) 'disposalMethod': disposalMethod.toApiValue(),
        if (warehouseId != null && warehouseId > 0) 'warehouseId': warehouseId.toString(),
        if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
      };

      final uri = Uri(path: ApiEndpoints.wasteEntries, queryParameters: queryParams);
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
            .map((e) => WasteEntryDto.fromJson(e))
            .toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<WasteEntryDto>> createEntry(WasteEntryDto entry) async {
    try {
      final uri = Uri(path: ApiEndpoints.wasteEntries);
      final response = await _client.invokeAPI(
        uri.toString(),
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(entry.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(WasteEntryDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<WasteReasonDto>> getReasonById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.wasteReasons}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(WasteReasonDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<WasteReasonDto>> updateReason(int id, WasteReasonDto reason) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.wasteReasons}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(reason.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(WasteReasonDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<bool>> deleteReason(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.wasteReasons}/$id',
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

  Future<Result<WasteEntryDto>> getEntryById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.wasteEntries}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(WasteEntryDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<WasteEntryDto>> updateEntry(int id, WasteEntryDto entry) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.wasteEntries}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(entry.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        return Success(WasteEntryDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(ServerFailure(500, e.toString()));
    }
  }

  Future<Result<bool>> deleteEntry(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.wasteEntries}/$id',
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
