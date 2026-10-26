import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/goods_receipt_dto.dart';
import '../models/goods_receipt_detail_dto.dart';

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
                : (decoded is Map<String, dynamic> && decoded['value'] is List)
                    ? decoded['value'] as List<dynamic>
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
        var grn = GoodsReceiptDto.fromJson(data);

        // Fetch details if empty
        if (grn.items.isEmpty) {
          try {
            final dRes = await _client.invokeAPI(
              ApiEndpoints.goodsReceiptDetails,
              'GET',
              {'Content-Type': 'application/json'},
              null,
            );
            if (dRes.statusCode >= 200 && dRes.statusCode < 300) {
              final dynamic dDecoded = jsonDecode(dRes.body);
              final List<dynamic> list = dDecoded is List
                  ? dDecoded
                  : (dDecoded is Map<String, dynamic> && dDecoded['data'] is List)
                      ? dDecoded['data'] as List<dynamic>
                      : (dDecoded is Map<String, dynamic> && dDecoded['value'] is List)
                          ? dDecoded['value'] as List<dynamic>
                          : [];
              final fetchedItems = list
                  .map((e) => GoodsReceiptDetailDto.fromJson(e as Map<String, dynamic>))
                  .where((d) => d.grnId == id || d.grnId == 0)
                  .toList();
              if (fetchedItems.isNotEmpty) {
                grn = grn.copyWith(items: fetchedItems);
              }
            }
          } catch (_) {}
        }

        return Success(grn);
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
            : (decoded is Map<String, dynamic> ? decoded : <String, dynamic>{});
        
        final assignedId = (data['id'] ?? data['grnId'] ?? data['GRNId']) as int? ?? 0;
        var createdGrn = grn.copyWith(id: assignedId > 0 ? assignedId : grn.id);

        // If items are present, save each to goodsReceiptDetails
        if (createdGrn.id > 0 && grn.items.isNotEmpty) {
          final createdItems = <GoodsReceiptDetailDto>[];
          for (final item in grn.items) {
            try {
              final payload = item.copyWith(grnId: createdGrn.id).toJson();
              final detailRes = await _client.invokeAPI(
                ApiEndpoints.goodsReceiptDetails,
                'POST',
                {'Content-Type': 'application/json'},
                jsonEncode(payload),
              );
              if (detailRes.statusCode >= 200 && detailRes.statusCode < 300) {
                final dynamic detailDecoded = jsonDecode(detailRes.body);
                final detailData = detailDecoded is Map<String, dynamic> && detailDecoded['data'] is Map<String, dynamic>
                    ? detailDecoded['data'] as Map<String, dynamic>
                    : (detailDecoded is Map<String, dynamic> ? detailDecoded : <String, dynamic>{});
                createdItems.add(GoodsReceiptDetailDto.fromJson(detailData));
              }
            } catch (_) {}
          }
          if (createdItems.isNotEmpty) {
            createdGrn = createdGrn.copyWith(items: createdItems);
          }
        }

        return Success(createdGrn);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<GoodsReceiptDto>> update(int id, GoodsReceiptDto grn) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.goodsReceipts}/$id',
        'PUT',
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

  Future<Result<bool>> delete(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.goodsReceipts}/$id',
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

  Future<Result<bool>> updateDetail(int detailId, Map<String, dynamic> payload) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.goodsReceiptDetails}/$detailId',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(true);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteDetail(int detailId) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.goodsReceiptDetails}/$detailId',
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
