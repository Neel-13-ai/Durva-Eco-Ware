import 'dart:convert';
import '../../../infrastructure/api/api_client.dart';
import '../../../infrastructure/storage/secure_store.dart';
import '../domain/session_models.dart';

class SessionManager {
  SessionManager({
    required SecureStore secureStore,
    ApiClient? refreshClient,
  })  : _secureStore = secureStore,
        _unusedRefreshClient = refreshClient;

  static const String refreshTokenKey = 'durvaeco_refresh_token';
  static const String accessTokenKey = 'durvaeco_access_token';
  static const String userKey = 'durvaeco_user';
  static const String lastRouteKey = 'durvaeco_last_route';

  final SecureStore _secureStore;
  // Kept optional only to preserve constructor compatibility where passed.
  // ignore: unused_field
  final ApiClient? _unusedRefreshClient;

  String? _accessToken;
  String? _lastRoute;
  Future<bool?>? _verifyInFlight;
  Future<bool?> Function()? verifySession;
  void Function()? onInvalidated;

  String? get accessToken => _accessToken;
  String? get lastRoute => _lastRoute;

  Future<String?> _safeRead(String key) async {
    try {
      return await _secureStore.read(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _secureStore.write(key, value);
    } catch (_) {}
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _secureStore.delete(key);
    } catch (_) {}
  }

  Future<String?> restoreAccessToken() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken;
    }
    final stored = await _safeRead(accessTokenKey);
    if (stored != null && stored.isNotEmpty) {
      _accessToken = stored;
      return stored;
    }
    return null;
  }

  Future<UserDto?> readUser() async {
    final raw = await _safeRead(userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserDto.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> restoreLastRoute() async {
    if (_lastRoute != null && _lastRoute!.isNotEmpty) {
      return _lastRoute;
    }
    final stored = await _safeRead(lastRouteKey);
    if (stored != null && stored.startsWith('/')) {
      _lastRoute = stored;
      return stored;
    }
    return null;
  }

  Future<void> saveLastRoute(String route) async {
    if (!route.startsWith('/') || _lastRoute == route) return;
    _lastRoute = route;
    await _safeWrite(lastRouteKey, route);
  }

  Future<void> clearLastRoute() async {
    _lastRoute = null;
    await _safeDelete(lastRouteKey);
  }

  Future<bool> hasPersistedSession() async =>
      (await restoreAccessToken()) != null;

  Future<void> persist({
    required String accessToken,
    String refreshToken = '',
    UserDto? user,
  }) async {
    _accessToken = accessToken;
    await _safeWrite(accessTokenKey, accessToken);
    if (user != null) {
      await _safeWrite(userKey, jsonEncode(user.toJson()));
    }
    if (refreshToken.isNotEmpty && refreshToken != accessToken) {
      await _safeWrite(refreshTokenKey, refreshToken);
    } else {
      await _safeDelete(refreshTokenKey);
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _lastRoute = null;
    await _safeDelete(accessTokenKey);
    await _safeDelete(refreshTokenKey);
    await _safeDelete(userKey);
    await _safeDelete(lastRouteKey);
  }

  /// Confirms with the backend whether the current token is still accepted.
  /// Returns `true` if valid, `false` if explicitly rejected (401), or `null`
  /// on temporary API/network failures.
  Future<bool?> verifySessionOnce() {
    final fn = verifySession;
    if (fn == null) return Future.value(null);
    return _verifyInFlight ??=
        fn().whenComplete(() => _verifyInFlight = null);
  }

  Future<void> invalidate() async {
    await clear();
    onInvalidated?.call();
  }
}
