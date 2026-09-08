import 'dart:convert';
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

  Future<Result<UserDto>> login(String email, String password) async {
    try {
      final res = await _apiClient.invokeAPI(
        '/auth/login',
        'POST',
        {'content-type': 'application/json'},
        jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;
        final tokensData = data['tokens'] as Map<String, dynamic>;

        final user = UserDto(
          id: userData['id'] as String,
          email: userData['email'] as String,
          displayName: (userData['displayName'] as String?) ?? '',
          roles: List<String>.from((userData['roles'] as Iterable<dynamic>?) ?? ['USER']),
        );
        await _session.persist(
          accessToken: tokensData['accessToken'] as String,
          refreshToken: tokensData['refreshToken'] as String,
        );
        return Success(user);
      }
      return Err(ServerFailure(res.statusCode, 'Invalid credentials'));
    } catch (_) {
      return const Err(NetworkFailure());
    }
  }

  Future<UserDto?> currentUser() async {
    if (!await _session.hasPersistedSession()) return null;
    final refreshed = await _session.refreshOnce();
    if (!refreshed) return null;
    try {
      final res = await _apiClient.invokeAPI('/auth/me', 'GET', {}, null);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;
        return UserDto(
          id: userData['id'] as String,
          email: userData['email'] as String,
          displayName: (userData['displayName'] as String?) ?? '',
          roles: List<String>.from((userData['roles'] as Iterable<dynamic>?) ?? ['USER']),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.invokeAPI('/auth/logout', 'POST', {}, null);
    } catch (_) {}
    await _session.clear();
  }
}
