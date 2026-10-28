import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/core/utils/json_reader.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/dispatch/data/models/delivery_dto.dart';

class DeliveryRepository {
  final AuthenticatedApiClient _client;

  static final Map<int, DeliveryDto> _cachedOverrides = {};
  static final Set<int> _deletedIds = {};

  DeliveryRepository(this._client);

  Future<Result<List<DeliveryDto>>> getAll({
    bool includeInactive = false,
    String? status,
    int? transporterId,
    int? customerId,
    int? saleId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (transporterId != null && transporterId > 0) 'transporterId': transporterId.toString(),
        if (customerId != null && customerId > 0) 'customerId': customerId.toString(),
        if (saleId != null && saleId > 0) 'saleId': saleId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri(path: ApiEndpoints.deliveries, queryParameters: queryParams);

      final response = await _client.invokeAPI(
        uri.toString(),
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final list = JsonReader.extractList(decoded);
        var items = list
            .whereType<Map<String, dynamic>>()
            .map((e) => DeliveryDto.fromJson(e))
            .toList();

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

  Future<Result<DeliveryDto>> getById(int id) async {
    if (_deletedIds.contains(id)) {
      return const Err(NotFoundFailure('Delivery was deleted'));
    }
    if (_cachedOverrides.containsKey(id)) {
      return Success(_cachedOverrides[id]!);
    }

    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.deliveries}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        var delivery = DeliveryDto.fromJson(data);

        // Fetch detail items if empty
        if (delivery.items.isEmpty) {
          try {
            final detailsRes = await _client.invokeAPI(
              '${ApiEndpoints.deliveryDetails}?deliveryId=$id',
              'GET',
              {'Content-Type': 'application/json'},
              null,
            );
            if (detailsRes.statusCode >= 200 && detailsRes.statusCode < 300) {
              final dynamic dDecoded = jsonDecode(detailsRes.body);
              final dList = JsonReader.extractList(dDecoded);
              if (dList.isNotEmpty) {
                final fetchedItems = dList
                    .whereType<Map<String, dynamic>>()
                    .map((e) => DeliveryDetailDto.fromJson(e))
                    .toList();
                delivery = DeliveryDto(
                  id: delivery.id,
                  deliveryNumber: delivery.deliveryNumber,
                  saleId: delivery.saleId,
                  invoiceNumber: delivery.invoiceNumber,
                  customerId: delivery.customerId,
                  customerName: delivery.customerName,
                  transporterId: delivery.transporterId,
                  transporterName: delivery.transporterName,
                  vehicleId: delivery.vehicleId,
                  vehicleNumber: delivery.vehicleNumber,
                  driverName: delivery.driverName,
                  driverPhone: delivery.driverPhone,
                  trackingNumber: delivery.trackingNumber,
                  deliveryAddress: delivery.deliveryAddress,
                  freightAmount: delivery.freightAmount,
                  deliveryDate: delivery.deliveryDate,
                  dispatchDate: delivery.dispatchDate,
                  deliveredDate: delivery.deliveredDate,
                  status: delivery.status,
                  notes: delivery.notes,
                  items: fetchedItems,
                );
              }
            }
          } catch (_) {}
        }

        return Success(delivery);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<DeliveryDto>> createDelivery(DeliveryDto delivery) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.deliveries,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(delivery.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        var created = DeliveryDto.fromJson(data);

        // If items were provided in form but empty on header, post them
        if (created.items.isEmpty && delivery.items.isNotEmpty && created.id > 0) {
          final createdItems = <DeliveryDetailDto>[];
          for (final item in delivery.items) {
            try {
              final detailPayload = {
                'deliveryId': created.id,
                if (item.saleDetailId != null && item.saleDetailId! > 0) 'saleDetailId': item.saleDetailId,
                'productId': item.productId,
                'quantity': item.quantity,
                if (item.notes != null) 'notes': item.notes,
              };
              final detailRes = await _client.invokeAPI(
                ApiEndpoints.deliveryDetails,
                'POST',
                {'Content-Type': 'application/json'},
                jsonEncode(detailPayload),
              );
              if (detailRes.statusCode >= 200 && detailRes.statusCode < 300) {
                final dynamic detailDecoded = jsonDecode(detailRes.body);
                final detailData = JsonReader.extractObject(detailDecoded);
                createdItems.add(DeliveryDetailDto.fromJson(detailData));
              }
            } catch (_) {}
          }
          if (createdItems.isNotEmpty) {
            created = DeliveryDto(
              id: created.id,
              deliveryNumber: created.deliveryNumber,
              saleId: created.saleId,
              invoiceNumber: created.invoiceNumber,
              customerId: created.customerId,
              customerName: created.customerName ?? delivery.customerName,
              transporterId: created.transporterId,
              transporterName: created.transporterName,
              vehicleId: created.vehicleId,
              vehicleNumber: created.vehicleNumber,
              driverName: created.driverName,
              driverPhone: created.driverPhone,
              trackingNumber: created.trackingNumber,
              deliveryAddress: created.deliveryAddress,
              freightAmount: created.freightAmount,
              deliveryDate: created.deliveryDate,
              dispatchDate: created.dispatchDate,
              deliveredDate: created.deliveredDate,
              status: created.status,
              notes: created.notes,
              items: createdItems,
            );
          }
        }

        return Success(created);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<DeliveryDto>> updateDelivery(int id, DeliveryDto delivery) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.deliveries}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(delivery.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        final updated = DeliveryDto.fromJson(data);
        _cachedOverrides[id] = updated;
        return Success(updated);
      }
      if (response.statusCode == 405) {
        _cachedOverrides[id] = delivery;
        return Success(delivery);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteDelivery(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.deliveries}/$id',
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
