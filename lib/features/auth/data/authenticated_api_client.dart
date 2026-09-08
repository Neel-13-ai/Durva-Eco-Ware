import 'package:http/http.dart';
import '../../../core/utils/device_utils.dart';
import '../../../core/utils/timezone_utils.dart';
import '../../../infrastructure/api/api_client.dart';
import 'session_manager.dart';

class AuthenticatedApiClient extends ApiClient {
  AuthenticatedApiClient({
    required super.basePath,
    required SessionManager session,
  }) : _session = session {
    addDefaultHeader('X-Durvaeco-Client', 'mobile');
    addDefaultHeader('X-Timezone', detectDeviceIanaTimezone());
    addDefaultHeader('X-Device-Name', detectDeviceName());
  }

  final SessionManager _session;

  bool _isAuthEndpoint(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh');

  @override
  Future<Response> invokeAPI(
    String path,
    String method,
    Map<String, String> headers,
    Object? body,
  ) async {
    final token = _session.accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    var response = await super.invokeAPI(path, method, headers, body);

    if (response.statusCode == 401 && !_isAuthEndpoint(path)) {
      final refreshed = await _session.refreshOnce();
      if (refreshed) {
        final newToken = _session.accessToken;
        if (newToken != null) {
          headers['Authorization'] = 'Bearer $newToken';
        }
        response = await super.invokeAPI(path, method, headers, body);
      }
    }

    return response;
  }
}
