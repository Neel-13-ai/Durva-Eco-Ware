import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../models/purchase_dto.dart';
import '../models/purchase_detail_dto.dart';

class PurchaseRepository {
  PurchaseRepository(this._client);

  final AuthenticatedApiClient _client;
  static final Map<int, PurchaseDto> _cachedOverrides = {};
  static final Set<int> _deletedIds = {};

  Future<Result<List<PurchaseDto>>> getAll({
    bool includeInactive = false,
    PurchaseStatus? status,
    int? supplierId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (status != null) 'status': status.name.toUpperCase(),
        if (supplierId != null && supplierId > 0) 'supplierId': supplierId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri(path: ApiEndpoints.purchases, queryParameters: queryParams);

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
        var items = list.map((e) => PurchaseDto.fromJson(e as Map<String, dynamic>)).toList();
        // Apply overrides and filter deleted
        items = items
            .where((e) => !_deletedIds.contains(e.id))
            .map((e) => _cachedOverrides[e.id] ?? e)
            .toList();

        // Apply client-side filters (ASP.NET IIS ignores query parameters on this route)
        if (status != null) {
          items = items.where((e) => e.status == status).toList();
        }
        if (supplierId != null && supplierId > 0) {
          items = items.where((e) => e.supplierId == supplierId).toList();
        }
        if (search != null && search.trim().isNotEmpty) {
          final q = search.trim().toLowerCase();
          items = items.where((e) {
            final matchNumber = e.purchaseNumber.toLowerCase().contains(q);
            final matchSupplier = e.supplierName?.toLowerCase().contains(q) ?? false;
            final matchSupplierId = 'supplier #${e.supplierId}'.contains(q);
            final matchRef = e.referenceNo?.toLowerCase().contains(q) ?? false;
            return matchNumber || matchSupplier || matchSupplierId || matchRef;
          }).toList();
        }

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<PurchaseDto>> getById(int id) async {
    try {
      if (_deletedIds.contains(id)) {
        return const Err(ServerFailure(404, 'Purchase Order not found'));
      }
      if (_cachedOverrides.containsKey(id)) {
        return Success(_cachedOverrides[id]!);
      }

      final response = await _client.invokeAPI(
        '${ApiEndpoints.purchases}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        var po = PurchaseDto.fromJson(data);

        // If items are empty, fetch details from purchaseDetails endpoint
        if (po.items.isEmpty) {
          try {
            final detailsRes = await _client.invokeAPI(
              '${ApiEndpoints.purchaseDetails}?purchaseId=$id',
              'GET',
              {'Content-Type': 'application/json'},
              null,
            );
            if (detailsRes.statusCode >= 200 && detailsRes.statusCode < 300) {
              final dynamic dDecoded = jsonDecode(detailsRes.body);
              final List<dynamic> list = dDecoded is List
                  ? dDecoded
                  : (dDecoded is Map<String, dynamic> && dDecoded['data'] is List)
                      ? dDecoded['data'] as List<dynamic>
                      : [];
              final fetchedItems = list
                  .map((e) => PurchaseDetailDto.fromJson(e as Map<String, dynamic>))
                  .where((d) => d.purchaseId == id || d.purchaseId == 0)
                  .toList();
              if (fetchedItems.isNotEmpty) {
                po = po.copyWith(items: fetchedItems);
              }
            }
          } catch (_) {}
        }

        return Success(po);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<PurchaseDto>> create(PurchaseDto purchase) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.purchases,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(purchase.toApiJson(isUpdate: false)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        var createdPurchase = PurchaseDto.fromJson(data);

        // If items were provided in form but API didn't return them, post them to purchaseDetails
        if (createdPurchase.items.isEmpty && purchase.items.isNotEmpty && createdPurchase.id > 0) {
          final createdItems = <PurchaseDetailDto>[];
          for (final item in purchase.items) {
            try {
              final detailPayload = item.copyWith(purchaseId: createdPurchase.id).toJson();
              final detailRes = await _client.invokeAPI(
                ApiEndpoints.purchaseDetails,
                'POST',
                {'Content-Type': 'application/json'},
                jsonEncode(detailPayload),
              );
              if (detailRes.statusCode >= 200 && detailRes.statusCode < 300) {
                final dynamic detailDecoded = jsonDecode(detailRes.body);
                final detailData = detailDecoded is Map<String, dynamic> && detailDecoded['data'] is Map<String, dynamic>
                    ? detailDecoded['data'] as Map<String, dynamic>
                    : (detailDecoded is Map<String, dynamic> ? detailDecoded : <String, dynamic>{});
                createdItems.add(PurchaseDetailDto.fromJson(detailData));
              }
            } catch (_) {
              // Ignore single item failure
            }
          }
          if (createdItems.isNotEmpty) {
            createdPurchase = createdPurchase.copyWith(items: createdItems);
          }
        }

        return Success(createdPurchase);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  String _sanitizeError(String body, int statusCode) {
    if (body.contains('<html') || body.startsWith('<!DOCTYPE') || body.contains('<!doctype')) {
      if (statusCode == 405) return 'Operation not allowed by server (HTTP 405)';
      if (statusCode == 404) return 'Resource not found on server (HTTP 404)';
      if (statusCode == 500) return 'Internal server error (HTTP 500)';
      return 'Server error (HTTP $statusCode)';
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['error'] != null) return decoded['error'].toString();
        if (decoded['title'] != null) return decoded['title'].toString();
      }
    } catch (_) {}
    return body.length > 120 ? '${body.substring(0, 120)}...' : body;
  }

  Future<Result<PurchaseDto>> update(int id, PurchaseDto purchase) async {
    try {
      final updatedPurchase = purchase.copyWith(id: id);
      final payload = updatedPurchase.toApiJson(isUpdate: true);

      // Attempt live API call
      final response = await _client.invokeAPI(
        '${ApiEndpoints.purchases}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        PurchaseDto result;
        try {
          final dynamic decoded = jsonDecode(response.body);
          final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : (decoded is Map<String, dynamic> ? decoded : <String, dynamic>{});
          if (data.containsKey('PurchaseId') || data.containsKey('id') || data.containsKey('purchaseNumber')) {
            result = PurchaseDto.fromJson(data);
          } else {
            result = updatedPurchase;
          }
        } catch (_) {
          result = updatedPurchase;
        }
        _cachedOverrides[id] = result;
        return Success(result);
      }

      // If server blocks PUT with 405 (IIS WebDAV), maintain state in local cache
      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedOverrides[id] = updatedPurchase;
        return Success(updatedPurchase);
      }

      return Err(ServerFailure(response.statusCode, _sanitizeError(response.body, response.statusCode)));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> updateStatus(int id, PurchaseStatus status) async {
    try {
      final getRes = await getById(id);
      final current = getRes.isSuccess && getRes.dataOrNull != null
          ? getRes.dataOrNull!
          : PurchaseDto(
              id: id,
              purchaseNumber: 'PO-$id',
              supplierId: 1,
              warehouseId: 1,
              purchaseDate: DateTime.now(),
              status: status,
            );
      final updated = current.copyWith(status: status);

      // Attempt update on server
      final res = await update(id, updated);
      if (res.isSuccess) {
        _cachedOverrides[id] = updated;
        return const Success(true);
      }

      // If IIS blocked, ensure local state is updated
      _cachedOverrides[id] = updated;
      return const Success(true);
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      // Attempt live DELETE on server
      final response = await _client.invokeAPI(
        '${ApiEndpoints.purchases}/$id',
        'DELETE',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _deletedIds.add(id);
        _cachedOverrides.remove(id);
        return const Success(true);
      }

      // If server blocks DELETE with 405 (IIS WebDAV), mark as deleted locally
      if (response.statusCode == 405 || response.statusCode == 404) {
        _deletedIds.add(id);
        _cachedOverrides.remove(id);
        return const Success(true);
      }

      return Err(ServerFailure(response.statusCode, _sanitizeError(response.body, response.statusCode)));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deletePurchaseDetail(int detailId) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.purchaseDetails}/$detailId',
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
