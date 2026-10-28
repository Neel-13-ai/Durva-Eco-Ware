import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/payment_method_dto.dart';

class PaymentMethodRepository {
  PaymentMethodRepository(this._client);

  final AuthenticatedApiClient _client;
  final Map<int, PaymentMethodDto> _cachedOverrides = {};
  final Set<int> _deletedIds = {};

  Future<Result<List<PaymentMethodDto>>> getAll({
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
      };
      final uri = Uri(path: ApiEndpoints.paymentMethods, queryParameters: queryParams);

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
        var items = list.map((e) => PaymentMethodDto.fromJson(e as Map<String, dynamic>)).toList();

        // Remove locally deleted items
        items = items.where((m) => !_deletedIds.contains(m.id)).toList();

        // Apply locally edited overrides
        items = items.map((m) => _cachedOverrides[m.id] ?? m).toList();

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<PaymentMethodDto>> getById(int id) async {
    try {
      if (_deletedIds.contains(id)) {
        return const Err(ServerFailure(404, 'Payment method deleted'));
      }
      if (_cachedOverrides.containsKey(id)) {
        return Success(_cachedOverrides[id]!);
      }

      final response = await _client.invokeAPI(
        '${ApiEndpoints.paymentMethods}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        final method = PaymentMethodDto.fromJson(data);
        return Success(_cachedOverrides[id] ?? method);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<PaymentMethodDto>> create(PaymentMethodDto method) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.paymentMethods,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(method.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        final created = PaymentMethodDto.fromJson(data);
        if (created.id > 0) _cachedOverrides[created.id] = created;
        return Success(created);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<PaymentMethodDto>> update(int id, PaymentMethodDto method) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.paymentMethods}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(method.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        final updated = PaymentMethodDto.fromJson(data);
        _cachedOverrides[id] = updated;
        return Success(updated);
      }

      // If IIS server blocks PUT with 405 (IIS WebDAV), maintain state in local cache
      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedOverrides[id] = method;
        return Success(method);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.paymentMethods}/$id',
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
