import '../../../infrastructure/api/api_client.dart';
import '../../../infrastructure/storage/secure_store.dart';

class SessionManager {
  SessionManager({
    required SecureStore secureStore,
    required ApiClient refreshClient,
  })  : _secureStore = secureStore,
        _refreshClient = refreshClient;

  static const String refreshTokenKey = 'durvaeco_refresh_token';

  final SecureStore _secureStore;
  final ApiClient _refreshClient;

  String? _accessToken;
  Future<bool>? _refreshInFlight;
  void Function()? onInvalidated;

  String? get accessToken => _accessToken;

  Future<bool> hasPersistedSession() async =>
      (await _secureStore.read(refreshTokenKey)) != null;

  Future<void> persist({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    await _secureStore.write(refreshTokenKey, refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    await _secureStore.delete(refreshTokenKey);
  }

  Future<bool> refreshOnce() {
    return _refreshInFlight ??= _refresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _refresh() async {
    final refreshToken = await _secureStore.read(refreshTokenKey);
    if (refreshToken == null) return false;
    try {
      final res = await _refreshClient.invokeAPI(
        '/auth/refresh',
        'POST',
        {'content-type': 'application/json'},
        '{"refreshToken":"$refreshToken"}',
      );
      if (res.statusCode == 200) {
        // Parse and persist new tokens
        return true;
      }
      await _invalidate();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _invalidate() async {
    await clear();
    onInvalidated?.call();
  }
}
