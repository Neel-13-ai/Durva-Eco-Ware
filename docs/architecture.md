# Architectural Overview & Layer Responsibilities

## 1. Architectural Style: Clean Layered Architecture

The Durvaeco architecture is organized into four distinct horizontal layers, with strict unidirectional dependency flow from the outermost layer (Presentation) to the innermost layers (Core / Infrastructure).

```text
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│  - Screens (GoRouter destination widgets)              │
│  - Feature-specific Widgets (Cards, Dialogs, Sheets)   │
│  - Shared UI Components (Guards, Base Widgets)         │
└───────────────────────────┬────────────────────────────┘
                            │ ref.watch() / ref.read()
                            ▼
┌────────────────────────────────────────────────────────┐
│                   APPLICATION LAYER                    │
│  - Riverpod StateNotifiers (Async UI controllers)      │
│  - Global Providers (appConfig, authController)        │
│  - AuthorizationService (Role & Permission evaluation) │
└───────────────────────────┬────────────────────────────┘
                            │ Calls repository methods
                            ▼
┌────────────────────────────────────────────────────────┐
│                 DOMAIN & DATA LAYER                    │
│  - Repositories (AuthRepository, SocialRepository)     │
│  - Domain Models & Value Objects                       │
│  - DTO Extension Methods & Parsers                     │
│  - Return types: Result<T> (Success<T> | Err<T>)       │
└───────────────────────────┬────────────────────────────┘
                            │ Invokes low-level APIs
                            ▼
┌────────────────────────────────────────────────────────┐
│                 INFRASTRUCTURE LAYER                   │
│  - AuthenticatedApiClient & OpenAPI Clients            │
│  - SecureStore (Keychain / EncryptedSharedPreferences) │
│  - LocalNotificationService & Timezone engine          │
│  - Native Hardware Boundaries (Camera, Audio, Sensors) │
└────────────────────────────────────────────────────────┘
```

---

## 2. Layer Deep-Dive

### Layer 1: Presentation Layer
* **Purpose**: Render UI, handle user interactions, and observe state changes.
* **Location**: `lib/features/<feature>/presentation/` and `lib/shared/widgets/`.
* **Files Located Here**:
  - Screen widgets (e.g. `LoginScreen`, `ProfileScreen`, `ExploreScreen`).
  - Feature widgets (e.g. `CommunityCard`, `DoseCorrectionDialog`).
  - Shared UI widgets (e.g. `RouteGuard`, `RequireRole`, `HealthCard`).
* **Who Calls It**: `GoRouter` invokes screens; screens invoke feature and shared widgets.
* **What It Calls**: Reads/watches Riverpod providers (`ref.watch()`, `ref.read()`), triggers controller methods, and navigates via `context.go()` / `context.push()`.
* **Data Flow**: Consumes view models / domain models from StateNotifiers and FutureProviders. Emits user interaction events.
* **Dependencies**: `flutter`, `flutter_riverpod`, `go_router`, `lib/app/theme`, `lib/core/authorization`.
* **Forbidden**:
  - Never call `http.Client` or OpenAPI client directly.
  - Never perform raw JSON serialization/deserialization.
  - Never store business logic in widget state.
* **Reference Example**: `apps/mobile/lib/features/community/screens/browse_screen.dart` and `apps/mobile/lib/shared/widgets/route_guard.dart`.

---

### Layer 2: Application / State Layer
* **Purpose**: Orchestrate business use cases, manage reactive UI state machines, coordinate asynchronous workflows, and evaluate security policies.
* **Location**: `lib/features/<feature>/application/` and `lib/core/authorization/`.
* **Files Located Here**:
  - StateNotifiers (e.g. `AuthController`, `CommunityBrowseController`).
  - State classes (e.g. `AuthState`, `CommunityBrowseState`).
  - Provider declarations (e.g. `authControllerProvider`, `authorizationServiceProvider`).
* **Who Calls It**: Presentation Layer widgets via Riverpod `ConsumerWidget` or `ConsumerStatefulWidget`.
* **What It Calls**: Repositories, Domain models, `AuthorizationService`, `NotificationService`.
* **Data Flow**: Receives commands from UI; calls repository methods; receives `Result<T>`; updates `state` to trigger UI re-renders.
* **Dependencies**: `flutter_riverpod`, `lib/core/result`, `lib/core/error`, `lib/features/<feature>/data`, `lib/features/<feature>/domain`.
* **Forbidden**:
  - Never import `BuildContext` inside notifiers or application services.
  - Never interact with Flutter widget rendering trees.
  - Never perform raw HTTP calls without repositories.
* **Reference Example**: `apps/mobile/lib/features/auth/application/auth_controller.dart`.

---

### Layer 3: Domain & Data Layer
* **Purpose**: Encapsulate domain entities, business validation, data fetching, data persistence, and translation between transport DTOs and domain models. Return functional `Result<T>` instead of throwing exceptions.
* **Location**: `lib/features/<feature>/domain/` and `lib/features/<feature>/data/`.
* **Files Located Here**:
  - Repositories (e.g. `AuthRepository`, `CommunityRepository`, `TelehealthRepository`).
  - Domain models (e.g. `SessionSummaryDtoX`, `MedicationDashboard`, `SocialMember`).
  - Session manager (`SessionManager`).
* **Who Calls It**: Application Layer controllers and providers.
* **What It Calls**: Infrastructure Layer (`AuthenticatedApiClient`, `ApiClient`, `SecureStore`, `LocalStore`).
* **Data Flow**: Receives domain requests; calls API client; handles exceptions; maps DTOs into domain models; wraps output in `Success(data)` or `Err(failure)`.
* **Dependencies**: `lib/core/result`, `lib/core/error`, `lib/infrastructure/api`, `lib/infrastructure/storage`.
* **Forbidden**:
  - Never import `flutter/material.dart` (except for UI extension helpers in domain if strictly necessary).
  - Never depend on Riverpod `ref` or UI states.
  - Never let low-level transport exceptions (`ApiException`, `SocketException`, `HttpException`) leak past repository methods.
* **Reference Example**: `apps/mobile/lib/features/auth/data/auth_repository.dart` and `apps/mobile/lib/features/auth/data/session_manager.dart`.

---

### Layer 4: Infrastructure & Core Layer
* **Purpose**: Low-level platform adapters, network clients, token persistence, hardware device plugins, operating system notifications, and compile-time configuration.
* **Location**: `lib/core/` and `lib/infrastructure/`.
* **Files Located Here**:
  - `AuthenticatedApiClient`: Bearer token attachment, platform headers, transparent 401 refresh-and-retry.
  - `AppConfig`: Compile-time `--dart-define` environment configuration and validation.
  - `SecureStore` & `FlutterSecureStore`: Hardware-encrypted storage boundary (Keychain/Keystore).
  - `LocalNotificationService`: OS alarm and notification scheduling (`flutter_local_notifications`).
  - `AppLogger`: Sentry telemetry and breadcrumb logging.
  - `Result<T>` and `Failure`: Sealed functional error primitives.
* **Who Calls It**: Repositories and Application bootstrap services.
* **What It Calls**: Third-party packages (`flutter_secure_storage`, `http`, `sentry_flutter`, `device_info_plus`, `agora_rtc_engine`).
* **Data Flow**: Direct transport / OS communication.
* **Dependencies**: Low-level SDKs and native platform bridges.
* **Forbidden**:
  - Must never contain high-level business logic or feature workflows.
* **Reference Example**: `apps/mobile/lib/features/auth/data/authenticated_api_client.dart` and `apps/mobile/lib/infrastructure/storage/flutter_secure_store.dart`.
