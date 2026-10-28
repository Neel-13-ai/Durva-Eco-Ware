import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';

class CustomerPaymentRepository {
  final AuthenticatedApiClient _client;

  static final Map<int, CustomerPaymentDto> _cachedOverrides = {};
  static final Set<int> _deletedIds = {};

  CustomerPaymentRepository(this._client);

  Future<Result<List<CustomerPaymentDto>>> getAll({
    bool includeInactive = false,
    int? customerId,
    int? saleId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (customerId != null && customerId > 0) 'customerId': customerId.toString(),
        if (saleId != null && saleId > 0) 'saleId': saleId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri(path: ApiEndpoints.customerPayments, queryParameters: queryParams);

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
        var items = list.map((e) => CustomerPaymentDto.fromJson(e as Map<String, dynamic>)).toList();

        items = items.where((i) => !_deletedIds.contains(i.id)).toList();
        for (var i = 0; i < items.length; i++) {
          if (_cachedOverrides.containsKey(items[i].id)) {
            items[i] = _cachedOverrides[items[i].id]!;
          }
        }
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<CustomerPaymentDto>> createPayment(CustomerPaymentDto payment) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.customerPayments,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(payment.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        return Success(CustomerPaymentDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<CustomerPaymentDto>> getCustomerPaymentById(int id) async {
    if (_deletedIds.contains(id)) {
      return const Err(NotFoundFailure('Customer payment was deleted'));
    }
    if (_cachedOverrides.containsKey(id)) {
      return Success(_cachedOverrides[id]!);
    }

    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.customerPayments}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(CustomerPaymentDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<CustomerPaymentDto>> updateCustomerPayment(int id, CustomerPaymentDto payment) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.customerPayments}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(payment.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        final updated = CustomerPaymentDto.fromJson(data);
        _cachedOverrides[id] = updated;
        return Success(updated);
      }
      if (response.statusCode == 405) {
        _cachedOverrides[id] = payment;
        return Success(payment);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteCustomerPayment(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.customerPayments}/$id',
        'DELETE',
        {'Content-Type': 'application/json'},
        null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _deletedIds.add(id);
        _cachedOverrides.remove(id);
        return const Success(true);
      }
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
