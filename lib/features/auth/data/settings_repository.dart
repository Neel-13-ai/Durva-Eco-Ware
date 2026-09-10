import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';

class SettingsRepository {
  SettingsRepository(this._client);

  final AuthenticatedApiClient _client;

  // ── App Settings ──────────────────────────────────────────────

  Future<Result<List<Map<String, dynamic>>>> getAppSettings({
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
      };
      final uri = Uri(path: ApiEndpoints.appSettings, queryParameters: queryParams);
      final response = await _client.invokeAPI(
        uri.toString(), 'GET',
        {'Content-Type': 'application/json'}, null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : [];
        return Success(list.cast<Map<String, dynamic>>());
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> getAppSettingById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.appSettings}/$id', 'GET',
        {'Content-Type': 'application/json'}, null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(data);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> createAppSetting(Map<String, dynamic> setting) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.appSettings, 'POST',
        {'Content-Type': 'application/json'}, jsonEncode(setting),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(data);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> updateAppSetting(int id, Map<String, dynamic> setting) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.appSettings}/$id', 'PUT',
        {'Content-Type': 'application/json'}, jsonEncode(setting),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(true);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteAppSetting(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.appSettings}/$id', 'DELETE',
        {'Content-Type': 'application/json'}, null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(true);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  // ── Company Settings ──────────────────────────────────────────

  Future<Result<List<Map<String, dynamic>>>> getCompanySettings({
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
      };
      final uri = Uri(path: ApiEndpoints.companySettings, queryParameters: queryParams);
      final response = await _client.invokeAPI(
        uri.toString(), 'GET',
        {'Content-Type': 'application/json'}, null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : [];
        return Success(list.cast<Map<String, dynamic>>());
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> getCompanySettingById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.companySettings}/$id', 'GET',
        {'Content-Type': 'application/json'}, null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(data);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> updateCompanySetting(int id, Map<String, dynamic> setting) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.companySettings}/$id', 'PUT',
        {'Content-Type': 'application/json'}, jsonEncode(setting),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(data);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  // ── Roles ──────────────────────────────────────────────────────

  Future<Result<List<Map<String, dynamic>>>> getRoles({
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
      };
      final uri = Uri(path: ApiEndpoints.roles, queryParameters: queryParams);
      final response = await _client.invokeAPI(
        uri.toString(), 'GET',
        {'Content-Type': 'application/json'}, null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : [];
        return Success(list.cast<Map<String, dynamic>>());
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> getRoleById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.roles}/$id', 'GET',
        {'Content-Type': 'application/json'}, null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return Success(data);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
