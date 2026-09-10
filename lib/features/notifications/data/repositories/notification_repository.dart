import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/notifications/data/models/notification_dto.dart';

class NotificationRepository {
  final AuthenticatedApiClient _client;

  NotificationRepository(this._client);

  Future<Result<List<NotificationDto>>> getAll({bool includeInactive = false}) async {
    try {
      final uri = Uri(
        path: ApiEndpoints.notifications,
        queryParameters: {'includeInactive': includeInactive.toString()},
      );

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
        final items = list.map((e) => NotificationDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<NotificationDto>> markAsRead(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.notifications}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode({'id': id, 'isRead': true, 'readAt': DateTime.now().toIso8601String()}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        return Success(NotificationDto.fromJson(data));
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteNotification(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.notifications}/$id',
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
