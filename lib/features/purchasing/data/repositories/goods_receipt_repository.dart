import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/goods_receipt_dto.dart';

class GoodsReceiptRepository {
  GoodsReceiptRepository(this._client);

  final AuthenticatedApiClient _client;

  Future<Result<List<GoodsReceiptDto>>> getAll({
    int? purchaseId,
    int? warehouseId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        if (purchaseId != null && purchaseId > 0) 'purchaseId': purchaseId.toString(),
        if (warehouseId != null && warehouseId > 0) 'warehouseId': warehouseId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri(path: ApiEndpoints.goodsReceipts, queryParameters: queryParams);

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
        final items = list.map((e) => GoodsReceiptDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<GoodsReceiptDto>> getById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.goodsReceipts}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(GoodsReceiptDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<GoodsReceiptDto>> create(GoodsReceiptDto grn) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.goodsReceipts,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(grn.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(GoodsReceiptDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
