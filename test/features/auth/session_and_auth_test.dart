import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:durvaeco/app/router.dart';
import 'package:durvaeco/core/config/app_config.dart';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/providers.dart';
import 'package:durvaeco/features/auth/application/auth_controller.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/auth_repository.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/auth/data/session_manager.dart';
import 'package:durvaeco/features/auth/domain/session_models.dart';
import 'package:durvaeco/infrastructure/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fakes.dart';

void main() {
  const baseUrl = 'https://api-dev.durvaecoware.com';

  group('SessionManager & AuthRepository restoration', () {
    test('login persists access token and user without storing fake refresh token', () async {
      final store = InMemorySecureStore();
      final client = MockClient((request) async {
        expect(request.url.path, ApiEndpoints.login);
        return jsonResponse(200, {
          'token': 'jwt-token-123',
          'userId': 3,
          'userName': 'superadmin',
          'fullName': 'System Administrator',
          'roleId': 1,
        });
      });

      final session = SessionManager(secureStore: store);
      final api = AuthenticatedApiClient(basePath: baseUrl, session: session)
        ..client = client;
      final repo = AuthRepository(
        apiClient: api,
        session: session,
        verificationClient: ApiClient(basePath: baseUrl, client: client),
      );

      final res = await repo.login('superadmin', '123456');
      expect(res.isSuccess, isTrue);
      expect(await store.read(SessionManager.accessTokenKey), 'jwt-token-123');
      expect(await store.read(SessionManager.refreshTokenKey), isNull);

      final restoredUser = await session.readUser();
      expect(restoredUser, isNotNull);
      expect(restoredUser!.id, '3');
      expect(restoredUser.email, 'superadmin');
      expect(restoredUser.roles, ['ADMIN']);
    });

    test('restoreSession verifies against /api/users/{id} without calling /auth/refresh or /auth/me', () async {
      final store = InMemorySecureStore();
      const user = UserDto(
        id: '3',
        email: 'superadmin',
        displayName: 'System Administrator',
        roles: ['ADMIN'],
      );
      await store.write(SessionManager.accessTokenKey, 'valid-jwt');
      await store.write(SessionManager.userKey, jsonEncode(user.toJson()));
      await store.write(SessionManager.lastRouteKey, '/purchases');

      final requestedPaths = <String>[];
      final client = MockClient((request) async {
        requestedPaths.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer valid-jwt');
        if (request.url.path == '${ApiEndpoints.users}/3') {
          return jsonResponse(200, {
            'userId': 3,
            'userName': 'superadmin',
            'fullName': 'System Administrator',
            'roleId': 1,
            'isActive': true,
          });
        }
        return jsonResponse(404, {'error': 'NOT_FOUND'});
      });

      final session = SessionManager(secureStore: store);
      final api = AuthenticatedApiClient(basePath: baseUrl, session: session)
        ..client = client;
      final repo = AuthRepository(
        apiClient: api,
        session: session,
        verificationClient: ApiClient(basePath: baseUrl, client: client),
      );

      final outcome = await repo.restoreSession();
      expect(outcome.status, SessionRestoreStatus.authenticated);
      expect(outcome.user?.displayName, 'System Administrator');
      expect(session.accessToken, 'valid-jwt');
      expect(session.lastRoute, '/purchases');
      expect(requestedPaths, ['${ApiEndpoints.users}/3']);
      expect(requestedPaths.contains(ApiEndpoints.refresh), isFalse);
      expect(requestedPaths.contains(ApiEndpoints.me), isFalse);
    });

    test('restoreSession falls back to /api/app-settings when /api/users/{id} returns 403', () async {
      final store = InMemorySecureStore();
      const user = UserDto(
        id: '7',
        email: 'staff',
        displayName: 'Staff User',
        roles: ['USER'],
      );
      await store.write(SessionManager.accessTokenKey, 'staff-jwt');
      await store.write(SessionManager.userKey, jsonEncode(user.toJson()));

      final client = MockClient((request) async {
        if (request.url.path == '${ApiEndpoints.users}/7') {
          return jsonResponse(403, {'message': 'Forbidden'});
        }
        if (request.url.path == ApiEndpoints.appSettings) {
          return http.Response('[]', 200);
        }
        return jsonResponse(404, {'error': 'NOT_FOUND'});
      });

      final session = SessionManager(secureStore: store);
      final api = AuthenticatedApiClient(basePath: baseUrl, session: session)
        ..client = client;
      final repo = AuthRepository(
        apiClient: api,
        session: session,
        verificationClient: ApiClient(basePath: baseUrl, client: client),
      );

      final outcome = await repo.restoreSession();
      expect(outcome.status, SessionRestoreStatus.authenticated);
      expect(outcome.user?.id, '7');
      expect(await store.read(SessionManager.accessTokenKey), 'staff-jwt');
    });

    test('restoreSession clears credentials only on explicit 401 rejection', () async {
      final store = InMemorySecureStore();
      const user = UserDto(
        id: '3',
        email: 'superadmin',
        displayName: 'System Administrator',
        roles: ['ADMIN'],
      );
      await store.write(SessionManager.accessTokenKey, 'expired-jwt');
      await store.write(SessionManager.userKey, jsonEncode(user.toJson()));

      final client = MockClient((request) async {
        return jsonResponse(401, {'message': 'Unauthorized'});
      });

      final session = SessionManager(secureStore: store);
      final api = AuthenticatedApiClient(basePath: baseUrl, session: session)
        ..client = client;
      final repo = AuthRepository(
        apiClient: api,
        session: session,
        verificationClient: ApiClient(basePath: baseUrl, client: client),
      );

      final outcome = await repo.restoreSession();
      expect(outcome.status, SessionRestoreStatus.unauthenticated);
      expect(await store.read(SessionManager.accessTokenKey), isNull);
      expect(await store.read(SessionManager.userKey), isNull);
    });

    test('restoreSession preserves credentials on temporary 5xx or SocketException', () async {
      final store = InMemorySecureStore();
      const user = UserDto(
        id: '3',
        email: 'superadmin',
        displayName: 'System Administrator',
        roles: ['ADMIN'],
      );
      await store.write(SessionManager.accessTokenKey, 'valid-jwt');
      await store.write(SessionManager.userKey, jsonEncode(user.toJson()));
      await store.write(SessionManager.lastRouteKey, '/inventory');

      var throwSocket = false;
      final client = MockClient((request) async {
        if (throwSocket) {
          throw const SocketException('Network unreachable');
        }
        return jsonResponse(503, {'message': 'Service Unavailable'});
      });

      final session = SessionManager(secureStore: store);
      final api = AuthenticatedApiClient(basePath: baseUrl, session: session)
        ..client = client;
      final repo = AuthRepository(
        apiClient: api,
        session: session,
        verificationClient: ApiClient(basePath: baseUrl, client: client),
      );

      final outcome503 = await repo.restoreSession();
      expect(outcome503.status, SessionRestoreStatus.temporaryFailure);
      expect(await store.read(SessionManager.accessTokenKey), 'valid-jwt');
      expect(await store.read(SessionManager.lastRouteKey), '/inventory');

      throwSocket = true;
      final outcomeNet = await repo.restoreSession();
      expect(outcomeNet.status, SessionRestoreStatus.temporaryFailure);
      expect(await store.read(SessionManager.accessTokenKey), 'valid-jwt');
    });
  });

  group('AuthenticatedApiClient 401 handling', () {
    test('does not invalidate session when verification hits temporary error or passes', () async {
      final store = InMemorySecureStore();
      const user = UserDto(
        id: '3',
        email: 'superadmin',
        displayName: 'Admin',
        roles: ['ADMIN'],
      );
      await store.write(SessionManager.accessTokenKey, 'jwt-1');
      await store.write(SessionManager.userKey, jsonEncode(user.toJson()));

      var verifyStatus = 500;
      var invalidatedCalled = false;
      final client = MockClient((request) async {
        if (request.url.path == ApiEndpoints.categories) {
          return jsonResponse(401, {'message': 'Transient 401'});
        }
        if (request.url.path == '${ApiEndpoints.users}/3') {
          return jsonResponse(verifyStatus, {'userId': 3, 'isActive': true});
        }
        return jsonResponse(404, {});
      });

      final session = SessionManager(secureStore: store)
        ..onInvalidated = () => invalidatedCalled = true;
      final api = AuthenticatedApiClient(basePath: baseUrl, session: session)
        ..client = client;
      final repo = AuthRepository(
        apiClient: api,
        session: session,
        verificationClient: ApiClient(basePath: baseUrl, client: client),
      );
      session.verifySession = repo.verifyActiveToken;

      // Temporary 500 during verification -> keep session
      final res1 = await api.invokeAPI(ApiEndpoints.categories, 'GET', {}, null);
      expect(res1.statusCode, 401);
      expect(invalidatedCalled, isFalse);
      expect(await store.read(SessionManager.accessTokenKey), 'jwt-1');

      // Verification succeeds (200) -> keep session
      verifyStatus = 200;
      final res2 = await api.invokeAPI(ApiEndpoints.categories, 'GET', {}, null);
      expect(res2.statusCode, 401);
      expect(invalidatedCalled, isFalse);
      expect(await store.read(SessionManager.accessTokenKey), 'jwt-1');

      // Verification explicitly returns 401 -> invalidate session
      verifyStatus = 401;
      final res3 = await api.invokeAPI(ApiEndpoints.categories, 'GET', {}, null);
      expect(res3.statusCode, 401);
      expect(invalidatedCalled, isTrue);
      expect(await store.read(SessionManager.accessTokenKey), isNull);
    });
  });

  group('SplashScreen & Router restoration', () {
    testWidgets('SplashScreen waits for slow bootstrap without racing to /login and restores last route', (tester) async {
      final store = InMemorySecureStore();
      const user = UserDto(
        id: '3',
        email: 'superadmin',
        displayName: 'System Administrator',
        roles: ['ADMIN'],
      );
      await store.write(SessionManager.accessTokenKey, 'valid-jwt');
      await store.write(SessionManager.userKey, jsonEncode(user.toJson()));
      await store.write(SessionManager.lastRouteKey, '/purchases');

      final completer = Completer<http.Response>();
      final client = MockClient((request) async {
        if (request.url.path == '${ApiEndpoints.users}/3') {
          return completer.future;
        }
        return http.Response('[]', 200);
      });

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: baseUrl,
              environment: AppEnvironment.dev,
            ),
          ),
          httpClientProvider.overrideWithValue(client),
          secureStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // Advance past the 1500ms splash minimum delay while verification is still pending.
      await tester.pump(const Duration(milliseconds: 1800));
      expect(container.read(authControllerProvider).status, AuthStatus.unknown);
      expect(
        container.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
        '/',
      );

      // Complete server verification -> must restore /purchases instead of /login or /home.
      completer.complete(
        jsonResponse(200, {
          'userId': 3,
          'userName': 'superadmin',
          'fullName': 'System Administrator',
          'roleId': 1,
          'isActive': true,
        }),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(authControllerProvider).status, AuthStatus.authenticated);
      expect(
        container.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
        '/purchases',
      );
    });

    testWidgets('SplashScreen shows Retry on temporary failure and preserves stored credentials', (tester) async {
      final store = InMemorySecureStore();
      const user = UserDto(
        id: '3',
        email: 'superadmin',
        displayName: 'System Administrator',
        roles: ['ADMIN'],
      );
      await store.write(SessionManager.accessTokenKey, 'valid-jwt');
      await store.write(SessionManager.userKey, jsonEncode(user.toJson()));
      await store.write(SessionManager.lastRouteKey, '/inventory');

      var failServer = true;
      final client = MockClient((request) async {
        if (request.url.path == '${ApiEndpoints.users}/3') {
          if (failServer) {
            return jsonResponse(503, {'message': 'Temporarily unavailable'});
          }
          return jsonResponse(200, {
            'userId': 3,
            'userName': 'superadmin',
            'fullName': 'System Administrator',
            'roleId': 1,
            'isActive': true,
          });
        }
        return http.Response('[]', 200);
      });

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: baseUrl,
              environment: AppEnvironment.dev,
            ),
          ),
          httpClientProvider.overrideWithValue(client),
          secureStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1600));
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.verificationFailed,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(await store.read(SessionManager.accessTokenKey), 'valid-jwt');

      // Recover server and tap Retry -> restores /inventory.
      failServer = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(authControllerProvider).status, AuthStatus.authenticated);
      expect(
        container.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
        '/inventory',
      );
    });
  });
}
