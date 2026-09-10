import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/providers.dart';
import '../../../infrastructure/api/api_client.dart';
import '../../../infrastructure/storage/flutter_secure_store.dart';
import '../../../infrastructure/storage/secure_store.dart';
import '../data/authenticated_api_client.dart';
import '../data/auth_repository.dart';
import '../data/session_manager.dart';
import '../data/settings_repository.dart';
import 'auth_controller.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final secureStoreProvider = Provider<SecureStore>((ref) => FlutterSecureStore());

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final config = ref.watch(appConfigProvider);
  final refreshClient = ApiClient(basePath: config.apiBaseUrl, client: ref.watch(httpClientProvider));
  return SessionManager(
    secureStore: ref.watch(secureStoreProvider),
    refreshClient: refreshClient,
  );
});

final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return AuthenticatedApiClient(
    basePath: config.apiBaseUrl,
    session: ref.watch(sessionManagerProvider),
  )..client = ref.watch(httpClientProvider);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(authenticatedApiClientProvider),
    session: ref.watch(sessionManagerProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return SettingsRepository(client);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    session: ref.watch(sessionManagerProvider),
  );
});
