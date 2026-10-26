import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';

class SalesRepository {
  final AuthenticatedApiClient _client;

  SalesRepository(this._client);

  Future<Result<List<SaleDto>>> getAll({
    bool includeInactive = false,
    String? status,
    String? paymentStatus,
    int? customerId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (paymentStatus != null && paymentStatus.isNotEmpty) 'paymentStatus': paymentStatus,
        if (customerId != null && customerId > 0) 'customerId': customerId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri(path: ApiEndpoints.sales, queryParameters: queryParams);

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
        final items = list.map((e) => SaleDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<SaleDto>> getById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.sales}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        var sale = SaleDto.fromJson(data);

        if (sale.items.isEmpty) {
          try {
            final detailsRes = await _client.invokeAPI(
              '${ApiEndpoints.saleDetails}?saleId=$id',
              'GET',
              {'Content-Type': 'application/json'},
              null,
            );
            if (detailsRes.statusCode >= 200 && detailsRes.statusCode < 300) {
              final dynamic dDecoded = jsonDecode(detailsRes.body);
              final List<dynamic> dList = dDecoded is List
                  ? dDecoded
                  : (dDecoded is Map<String, dynamic> && dDecoded['data'] is List)
                      ? dDecoded['data'] as List<dynamic>
                      : (dDecoded is Map<String, dynamic> && dDecoded['value'] is List)
                          ? dDecoded['value'] as List<dynamic>
                          : [];
              if (dList.isNotEmpty) {
                final fetchedItems = dList
                    .whereType<Map<String, dynamic>>()
                    .map((e) => SaleDetailDto.fromJson(e))
                    .toList();
                sale = SaleDto(
                  id: sale.id,
                  invoiceNumber: sale.invoiceNumber,
                  customerId: sale.customerId,
                  customerName: sale.customerName,
                  warehouseId: sale.warehouseId,
                  warehouseName: sale.warehouseName,
                  saleDate: sale.saleDate,
                  dueDate: sale.dueDate,
                  subtotal: sale.subtotal,
                  discount: sale.discount,
                  tax: sale.tax,
                  transportCharge: sale.transportCharge,
                  totalAmount: sale.totalAmount > 0 ? sale.totalAmount : fetchedItems.fold(0.0, (s, i) => s + i.lineTotal),
                  paidAmount: sale.paidAmount,
                  status: sale.status,
                  paymentStatus: sale.paymentStatus,
                  notes: sale.notes,
                  items: fetchedItems,
                );
              }
            }
          } catch (_) {}
        }

        return Success(sale);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<SaleDto>> createSale(SaleDto sale) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.sales,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(sale.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        var createdSale = SaleDto.fromJson(data);

        // If items were provided in form, post them to saleDetails
        if (createdSale.items.isEmpty && sale.items.isNotEmpty && createdSale.id > 0) {
          final createdItems = <SaleDetailDto>[];
          for (final item in sale.items) {
            try {
              final detailPayload = {
                'saleId': createdSale.id,
                'productId': item.productId,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'discount': item.discount,
                'tax': item.tax,
                if (item.notes != null) 'notes': item.notes,
              };
              final detailRes = await _client.invokeAPI(
                ApiEndpoints.saleDetails,
                'POST',
                {'Content-Type': 'application/json'},
                jsonEncode(detailPayload),
              );
              if (detailRes.statusCode >= 200 && detailRes.statusCode < 300) {
                final dynamic detailDecoded = jsonDecode(detailRes.body);
                final detailData = detailDecoded is Map<String, dynamic> && detailDecoded['data'] is Map<String, dynamic>
                    ? detailDecoded['data'] as Map<String, dynamic>
                    : (detailDecoded is Map<String, dynamic> ? detailDecoded : <String, dynamic>{});
                createdItems.add(SaleDetailDto.fromJson(detailData));
              }
            } catch (_) {}
          }
          if (createdItems.isNotEmpty) {
            createdSale = SaleDto(
              id: createdSale.id,
              invoiceNumber: createdSale.invoiceNumber,
              customerId: createdSale.customerId,
              customerName: createdSale.customerName ?? sale.customerName,
              warehouseId: createdSale.warehouseId,
              warehouseName: createdSale.warehouseName,
              saleDate: createdSale.saleDate,
              dueDate: createdSale.dueDate,
              subtotal: createdSale.subtotal > 0 ? createdSale.subtotal : sale.subtotal,
              discount: createdSale.discount,
              tax: createdSale.tax,
              transportCharge: createdSale.transportCharge,
              totalAmount: createdSale.totalAmount > 0 ? createdSale.totalAmount : sale.totalAmount,
              paidAmount: createdSale.paidAmount,
              status: createdSale.status,
              paymentStatus: createdSale.paymentStatus,
              notes: createdSale.notes,
              items: createdItems,
            );
          }
        }
        return Success(createdSale);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<SaleDto>> updateSale(int id, SaleDto sale) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.sales}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(sale.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        return Success(SaleDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteSale(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.sales}/$id',
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
