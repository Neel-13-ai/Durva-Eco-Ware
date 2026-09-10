import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';

class CustomerPaymentRepository {
  final AuthenticatedApiClient _client;

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
                : [];
        final items = list.map((e) => CustomerPaymentDto.fromJson(e as Map<String, dynamic>)).toList();
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
}
