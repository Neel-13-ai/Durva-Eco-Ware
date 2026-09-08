# Testing Architecture & Test Strategy

## 1. Testing Pyramid

```text
       ▲
      / \     Integration Tests (`integration_test/app_boot_test.dart`)
     /───\    Real device boot, token persistence & route navigation
    /        /───────\  Widget Tests (`test/features/*/screens/`)
  /         \ Screen rendering, interaction & ProviderScope overrides
 /───────────/             \ Unit Tests (`test/core/`, `test/features/`)
/───────────────\ Repositories, StateNotifiers, Result, Authorization
```

---

## 2. Test Support Utilities (`test/support/fakes.dart`)

```dart
// 1. In-Memory SecureStore Fake
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}

// 2. Scripted FakeApi Mock Transport
class FakeApi {
  final Map<String, RouteHandler> _routes = {};
  void on(String method, String pathSuffix, RouteHandler handler) {
    _routes['$method $pathSuffix'] = handler;
  }
  http.Client client() {
    return MockClient((request) async {
      for (final entry in _routes.entries) {
        final parts = entry.key.split(' ');
        if (request.method == parts[0] && request.url.path.endsWith(parts[1])) {
          return entry.value(request);
        }
      }
      return http.Response('{"error":{"code":"NOT_FOUND"}}', 404);
    });
  }
}
```

---

## 3. Riverpod Testing with Provider Overrides

```dart
testWidgets('HomeScreen renders user profile when authenticated', (tester) async {
  final fakeApi = FakeApi();
  fakeApi.on('GET', '/auth/me', (req) => jsonResponse(200, authResult()));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secureStoreProvider.overrideWithValue(InMemorySecureStore()),
        httpClientProvider.overrideWithValue(fakeApi.client()),
      ],
      child: const DurvaecoApp(),
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('Welcome back'), findsOneWidget);
});
```
