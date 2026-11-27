import 'dart:convert';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/error/failure.dart';
import '../../../core/result/result.dart';
import '../../../infrastructure/api/api_client.dart';
import '../domain/session_models.dart';
import 'session_manager.dart';

enum SessionRestoreStatus { authenticated, unauthenticated, temporaryFailure }

class SessionRestoreResult {
  const SessionRestoreResult._({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const SessionRestoreResult.authenticated(UserDto user)
      : this._(status: SessionRestoreStatus.authenticated, user: user);

  const SessionRestoreResult.unauthenticated()
      : this._(status: SessionRestoreStatus.unauthenticated);

  const SessionRestoreResult.temporaryFailure({
    UserDto? user,
    String? errorMessage,
  }) : this._(
          status: SessionRestoreStatus.temporaryFailure,
          user: user,
          errorMessage: errorMessage,
        );

  final SessionRestoreStatus status;
  final UserDto? user;
  final String? errorMessage;
}

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SessionManager session,
    ApiClient? verificationClient,
  })  : _apiClient = apiClient,
        _session = session,
        _verificationClient = verificationClient ?? apiClient;

  final ApiClient _apiClient;
  final SessionManager _session;
  final ApiClient _verificationClient;

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
          refreshToken = (data['refreshToken'] ?? '').toString();
        }

        // Extract user data
        final Map<String, dynamic> userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;

        final user = _parseUserMap(userMap, fallbackUsername: usernameOrEmail);

        if (accessToken.isNotEmpty) {
          await _session.persist(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: user,
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
      return Err(Failure.fromException(e));
    }
  }

  UserDto _parseUserMap(
    Map<String, dynamic> userMap, {
    UserDto? fallbackUser,
    String fallbackUsername = '',
  }) {
    final rawId = userMap['userId'] ?? userMap['UserId'] ?? userMap['id'] ?? userMap['Id'];
    final userId = (rawId ?? fallbackUser?.id ?? '1').toString();
    final username = (userMap['userName'] ??
            userMap['UserName'] ??
            userMap['username'] ??
            userMap['email'] ??
            userMap['Email'] ??
            fallbackUser?.email ??
            fallbackUsername)
        .toString();
    final fullName = (userMap['fullName'] ??
            userMap['FullName'] ??
            userMap['displayName'] ??
            userMap['name'] ??
            userMap['Name'] ??
            fallbackUser?.displayName ??
            username)
        .toString();

    List<String> roles = fallbackUser?.roles ?? const ['ADMIN'];
    if (userMap['roles'] is Iterable) {
      roles = List<String>.from(userMap['roles'] as Iterable);
    } else if (userMap['roleName'] != null || userMap['RoleName'] != null) {
      roles = [(userMap['roleName'] ?? userMap['RoleName']).toString()];
    } else if (userMap['role'] != null || userMap['Role'] != null) {
      roles = [(userMap['role'] ?? userMap['Role']).toString()];
    } else if (userMap['roleId'] != null || userMap['RoleId'] != null) {
      final roleIdStr = (userMap['roleId'] ?? userMap['RoleId']).toString();
      roles = switch (roleIdStr) {
        '1' => ['ADMIN'],
        '2' => ['MANAGER'],
        _ => ['USER'],
      };
    }

    final isActiveFlag = userMap['isActive'] ?? userMap['IsActive'];
    final statusStr = (userMap['status'] ?? userMap['Status'] ??
            (isActiveFlag == false ? 'INACTIVE' : fallbackUser?.status ?? 'ACTIVE'))
        .toString();

    return UserDto(
      id: userId,
      email: username,
      displayName: fullName,
      roles: roles,
      status: statusStr,
    );
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      };

  Future<SessionRestoreResult> restoreSession() async {
    final token = await _session.restoreAccessToken();
    if (token == null || token.isEmpty) {
      return const SessionRestoreResult.unauthenticated();
    }

    final storedUser = await _session.readUser();
    await _session.restoreLastRoute();

    final numericId = storedUser != null ? int.tryParse(storedUser.id) : null;
    if (numericId != null) {
      try {
        final res = await _verificationClient.invokeAPI(
          '${ApiEndpoints.users}/$numericId',
          'GET',
          _authHeaders(token),
          null,
        );
        if (res.statusCode == 200) {
          final dynamic decoded = jsonDecode(res.body);
          final Map<String, dynamic> userMap = decoded is Map<String, dynamic>
              ? (decoded['data'] is Map<String, dynamic>
                  ? decoded['data'] as Map<String, dynamic>
                  : decoded)
              : <String, dynamic>{};
          final updatedUser = _parseUserMap(userMap, fallbackUser: storedUser);
          if (updatedUser.status.toUpperCase() == 'INACTIVE') {
            await _session.clear();
            return const SessionRestoreResult.unauthenticated();
          }
          await _session.persist(accessToken: token, user: updatedUser);
          return SessionRestoreResult.authenticated(updatedUser);
        }
        if (res.statusCode == 401) {
          await _session.clear();
          return const SessionRestoreResult.unauthenticated();
        }
        if (res.statusCode >= 500) {
          return SessionRestoreResult.temporaryFailure(
            user: storedUser,
            errorMessage: 'Server temporarily unavailable (${res.statusCode}).',
          );
        }
        // For 403/404 on /api/users/{id}, fall through to verify JWT against a general authenticated endpoint.
      } catch (e) {
        return SessionRestoreResult.temporaryFailure(
          user: storedUser,
          errorMessage: Failure.fromException(e).message,
        );
      }
    }

    // Verify JWT against an existing general authenticated endpoint (/api/app-settings).
    try {
      final res = await _verificationClient.invokeAPI(
        ApiEndpoints.appSettings,
        'GET',
        _authHeaders(token),
        null,
      );
      if (res.statusCode == 200 || res.statusCode == 403) {
        if (storedUser != null) {
          return SessionRestoreResult.authenticated(storedUser);
        }
        // Token accepted by server, but no persisted user identity exists from an older build.
        await _session.clear();
        return const SessionRestoreResult.unauthenticated();
      }
      if (res.statusCode == 401) {
        await _session.clear();
        return const SessionRestoreResult.unauthenticated();
      }
      return SessionRestoreResult.temporaryFailure(
        user: storedUser,
        errorMessage: 'Unable to verify session (HTTP ${res.statusCode}).',
      );
    } catch (e) {
      return SessionRestoreResult.temporaryFailure(
        user: storedUser,
        errorMessage: Failure.fromException(e).message,
      );
    }
  }

  /// Verifies the currently active token against existing backend endpoints.
  /// Returns `true` if accepted, `false` if rejected with 401, or `null` on
  /// temporary API/network failures.
  Future<bool?> verifyActiveToken() async {
    final token = _session.accessToken ?? await _session.restoreAccessToken();
    if (token == null || token.isEmpty) return false;

    final storedUser = await _session.readUser();
    final numericId = storedUser != null ? int.tryParse(storedUser.id) : null;
    if (numericId != null) {
      try {
        final res = await _verificationClient.invokeAPI(
          '${ApiEndpoints.users}/$numericId',
          'GET',
          _authHeaders(token),
          null,
        );
        if (res.statusCode == 200) return true;
        if (res.statusCode == 401) return false;
        if (res.statusCode >= 500) return null;
      } catch (_) {
        return null;
      }
    }

    try {
      final res = await _verificationClient.invokeAPI(
        ApiEndpoints.appSettings,
        'GET',
        _authHeaders(token),
        null,
      );
      if (res.statusCode == 200 || res.statusCode == 403) return true;
      if (res.statusCode == 401) return false;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserDto?> currentUser() async {
    final result = await restoreSession();
    return result.status == SessionRestoreStatus.authenticated
        ? result.user
        : null;
  }

  Future<void> logout() async {
    try {
      await _apiClient.invokeAPI(ApiEndpoints.logout, 'POST', {}, '{}');
    } catch (_) {}
    await _session.clear();
  }
}
