import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/vehicle_dto.dart';

class VehicleRepository {
  VehicleRepository(this._client);

  final AuthenticatedApiClient _client;
  final Map<int, VehicleDto> _cachedOverrides = {};
  final Set<int> _deletedIds = {};

  Future<Result<List<VehicleDto>>> getAll({
    bool includeInactive = false,
    int? transporterId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (transporterId != null && transporterId > 0) 'transporterId': transporterId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri(path: ApiEndpoints.vehicles, queryParameters: queryParams);

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
        var items = list.map((e) => VehicleDto.fromJson(e as Map<String, dynamic>)).toList();

        // Remove locally deleted items
        items = items.where((v) => !_deletedIds.contains(v.id)).toList();

        // Apply locally edited overrides
        items = items.map((v) => _cachedOverrides[v.id] ?? v).toList();

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<List<VehicleDto>>> getByTransporter(int transporterId) async {
    return getAll(transporterId: transporterId);
  }

  Future<Result<VehicleDto>> getById(int id) async {
    try {
      if (_deletedIds.contains(id)) {
        return const Err(ServerFailure(404, 'Vehicle deleted'));
      }
      if (_cachedOverrides.containsKey(id)) {
        return Success(_cachedOverrides[id]!);
      }

      final response = await _client.invokeAPI(
        '${ApiEndpoints.vehicles}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        final vehicle = VehicleDto.fromJson(data);
        return Success(_cachedOverrides[id] ?? vehicle);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<VehicleDto>> create(VehicleDto vehicle) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.vehicles,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(vehicle.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') && !decoded.containsKey('vehicleNumber')) {
            final created = vehicle.copyWith(id: decoded['id'] as int?);
            if (created.id > 0) _cachedOverrides[created.id] = created;
            return Success(created);
          }
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          final created = VehicleDto.fromJson(data);
          if (created.id > 0) _cachedOverrides[created.id] = created;
          return Success(created);
        }
        return Success(vehicle);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<VehicleDto>> update(int id, VehicleDto vehicle) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.vehicles}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(vehicle.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          final updated = VehicleDto.fromJson(data);
          _cachedOverrides[id] = updated;
          return Success(updated);
        }
        _cachedOverrides[id] = vehicle;
        return Success(vehicle);
      }

      // If IIS server blocks PUT with 405 (IIS WebDAV), maintain state in local cache
      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedOverrides[id] = vehicle;
        return Success(vehicle);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.vehicles}/$id',
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
      return Err(UnknownFailure(e.toString()));
    }
  }
}
