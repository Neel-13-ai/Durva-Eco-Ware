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
      path.contains('/auth/refresh') ||
      path.contains('/auth/logout') ||
      path.contains('/auth/me');

  @override
  Future<Response> invokeAPI(
    String path,
    String method,
    Map<String, String> headers,
    Object? body,
  ) async {
    final isAuthPath = _isAuthEndpoint(path);
    final token = isAuthPath
        ? _session.accessToken
        : (_session.accessToken ?? await _session.restoreAccessToken());
    final sentToken = token;
    final hadToken = sentToken != null && sentToken.isNotEmpty;

    if (hadToken) {
      headers['Authorization'] = 'Bearer $sentToken';
    }

    final response = await super.invokeAPI(path, method, headers, body);

    if (response.statusCode == 401 && !isAuthPath && hadToken) {
      // If a newer login replaced the token while this request was in flight,
      // retry once with the new token instead of invalidating the new session.
      final currentToken = _session.accessToken;
      if (currentToken != null &&
          currentToken.isNotEmpty &&
          currentToken != sentToken) {
        headers['Authorization'] = 'Bearer $currentToken';
        return super.invokeAPI(path, method, headers, body);
      }

      // Only invalidate stored credentials when the server confirms the JWT is
      // rejected; temporary API/network failures return `null` and keep the session.
      final isStillValid = await _session.verifySessionOnce();
      if (isStillValid == false && _session.accessToken == sentToken) {
        await _session.invalidate();
      }
    }

    return response;
  }
}
