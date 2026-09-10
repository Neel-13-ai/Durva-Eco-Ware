import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/vendor_payment_dto.dart';

class VendorPaymentRepository {
  VendorPaymentRepository(this._client);

  final AuthenticatedApiClient _client;

  Future<Result<List<VendorPaymentDto>>> getAll({
    int? supplierId,
    int? purchaseId,
  }) async {
    try {
      final queryParams = <String, String>{
        if (supplierId != null && supplierId > 0) 'supplierId': supplierId.toString(),
        if (purchaseId != null && purchaseId > 0) 'purchaseId': purchaseId.toString(),
      };
      final uri = Uri(path: ApiEndpoints.vendorPayments, queryParameters: queryParams);

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
        final items = list.map((e) => VendorPaymentDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<VendorPaymentDto>> create(VendorPaymentDto payment) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.vendorPayments,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(payment.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(VendorPaymentDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
