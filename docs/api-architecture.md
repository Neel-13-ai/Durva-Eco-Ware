# API & Networking Architecture

## 1. Architectural Strategy: OpenAPI Contract & Generated Client

The Durvaeco application adopts a **Contract-First API Architecture**. The backend OpenAPI 3.0 specification (`specs/openapi/*.json`) defines the single source of truth for endpoints, DTO models, query parameters, and enums.

```text
Backend OpenAPI 3.0 Spec (JSON / YAML)
                 │
                 ▼ (openapi-generator / scripts/generate_api_client.sh)
Generated Dart API Package / Classes
(lib/infrastructure/api/generated or packages/api_client)
                 │
                 ▼ (Wrapped with Auth & Custom Transport)
AuthenticatedApiClient (lib/features/auth/data/authenticated_api_client.dart)
                 │
                 ▼ (Injected into domain Repositories)
Domain Repositories (Result<T> error encapsulation)
                 │
                 ▼
Riverpod Providers & Controllers
```

---

## 2. Base URL Configuration via `--dart-define`

The API base URL is **never hardcoded** in widgets, repositories, or services. It is supplied at build or run time via `--dart-define=API_BASE_URL=...` and validated at startup via `AppConfig.fromEnvironment()`:

```bash
# iOS Simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3030

# Android Emulator (localhost maps to 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3030

# Physical Device on Local Area Network
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3030

# Production Build
flutter build apk --dart-define=API_BASE_URL=https://api.durvaeco.com --dart-define=APP_ENV=production
```

---

## 3. Custom Request Headers & Context Injection

The `AuthenticatedApiClient` automatically attaches enterprise context headers on every outbound HTTP request:

```dart
class AuthenticatedApiClient extends ApiClient {
  AuthenticatedApiClient({
    required super.basePath,
    required SessionManager session,
  }) : _session = session {
    // 1. Client Identifier (Hint for transport & logging)
    addDefaultHeader('X-MedBuddie-Client', 'mobile');
    
    // 2. IANA Timezone (e.g. 'America/New_York' for localized server dates)
    addDefaultHeader('X-Timezone', detectDeviceIanaTimezone());
    
    // 3. Hardware Device Model (e.g. 'Pixel 8 Pro' for session tracking)
    addDefaultHeader('X-Device-Name', detectDeviceName());
  }
}
```

---

## 4. Repository Abstraction Pattern

Domain repositories wrap OpenAPI API classes and translate transport responses/exceptions into domain-safe `Result<T>`:

```dart
class CommunityRepository {
  CommunityRepository(ApiClient apiClient) : _api = CommunityApi(apiClient);

  final CommunityApi _api;

  Future<Result<List<CommunityDto>>> getCommunities() async {
    try {
      final response = await _api.communityList();
      if (response == null) {
        return const Err(UnknownFailure('Empty response'));
      }
      return Success(response.communities);
    } on ApiException catch (e) {
      return Err(ServerFailure(e.code, _cleanErrorMessage(e.message)));
    } on Object catch (_) {
      return const Err(NetworkFailure());
    }
  }
}
```
