import 'dart:convert';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/error/failure.dart';
import '../../../core/result/result.dart';
import '../../../infrastructure/api/api_client.dart';
import '../domain/session_models.dart';
import 'session_manager.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SessionManager session,
  })  : _apiClient = apiClient,
        _session = session;

  final ApiClient _apiClient;
  final SessionManager _session;

  Future<Result<UserDto>> login(String usernameOrEmail, String password) async {
    try {
      final payload = jsonEncode({
        'userName': usernameOrEmail,
        'UserName': usernameOrEmail,
        'email': usernameOrEmail,
        'password': password,
        'Password': password,
      });

      final res = await _apiClient.invokeAPI(
        ApiEndpoints.login,
        'POST',
        {'content-type': 'application/json', 'accept': 'application/json'},
        payload,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final dynamic raw = jsonDecode(res.body);
        final Map<String, dynamic> data = raw is Map<String, dynamic>
            ? (raw['data'] is Map<String, dynamic> ? raw['data'] as Map<String, dynamic> : raw)
            : <String, dynamic>{};

        // Extract token
        String accessToken = '';
        String refreshToken = '';

        if (data['tokens'] is Map<String, dynamic>) {
          final tokens = data['tokens'] as Map<String, dynamic>;
          accessToken = (tokens['accessToken'] ?? tokens['token'] ?? '').toString();
          refreshToken = (tokens['refreshToken'] ?? '').toString();
        } else {
          accessToken = (data['token'] ?? data['accessToken'] ?? data['jwt'] ?? '').toString();
          refreshToken = (data['refreshToken'] ?? accessToken).toString();
        }

        // Extract user data
        final Map<String, dynamic> userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;

        final userId = (userMap['userId'] ?? userMap['id'] ?? '1').toString();
        final username = (userMap['userName'] ?? userMap['username'] ?? userMap['email'] ?? usernameOrEmail).toString();
        final fullName = (userMap['fullName'] ?? userMap['displayName'] ?? userMap['name'] ?? username).toString();

        List<String> roles = ['ADMIN'];
        if (userMap['roles'] is Iterable) {
          roles = List<String>.from(userMap['roles'] as Iterable);
        } else if (userMap['role'] != null) {
          roles = [userMap['role'].toString()];
        } else if (userMap['roleId'] != null) {
          roles = userMap['roleId'].toString() == '1' ? ['ADMIN'] : ['USER'];
        }

        final user = UserDto(
          id: userId,
          email: username,
          displayName: fullName,
          roles: roles,
        );

        if (accessToken.isNotEmpty) {
          await _session.persist(
            accessToken: accessToken,
            refreshToken: refreshToken.isNotEmpty ? refreshToken : accessToken,
          );
        }

        return Success(user);
      }

      String errorMsg = 'Invalid username or password.';
      try {
        final errJson = jsonDecode(res.body);
        if (errJson is Map && (errJson['message'] != null || errJson['error'] != null)) {
          errorMsg = (errJson['message'] ?? errJson['error']).toString();
        }
      } catch (_) {}

      return Err(ServerFailure(res.statusCode, errorMsg));
    } catch (e) {
      return Err(ServerFailure(0, 'Network error: $e'));
    }
  }

  Future<UserDto?> currentUser() async {
    if (!await _session.hasPersistedSession()) return null;
    final refreshed = await _session.refreshOnce();
    if (!refreshed) return null;
    try {
      final res = await _apiClient.invokeAPI(ApiEndpoints.me, 'GET', {}, null);
      if (res.statusCode == 200) {
        final dynamic raw = jsonDecode(res.body);
        final Map<String, dynamic> data = raw is Map<String, dynamic>
            ? (raw['data'] is Map<String, dynamic> ? raw['data'] as Map<String, dynamic> : raw)
            : <String, dynamic>{};
        final userData = (data['user'] is Map<String, dynamic>)
            ? data['user'] as Map<String, dynamic>
            : data;
        return UserDto(
          id: (userData['id'] ?? userData['userId'] ?? '1').toString(),
          email: (userData['email'] ?? userData['userName'] ?? '').toString(),
          displayName: (userData['fullName'] ?? userData['displayName'] ?? userData['name'] ?? '').toString(),
          roles: userData['roles'] is Iterable
              ? List<String>.from(userData['roles'] as Iterable)
              : [userData['role']?.toString() ?? 'ADMIN'],
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.invokeAPI(ApiEndpoints.logout, 'POST', {}, null);
    } catch (_) {}
    await _session.clear();
  }
}
