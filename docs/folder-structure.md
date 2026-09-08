# Folder Structure & Placement Rules

## 1. Directory Tree (Standalone Flutter)

```text
durvaeco/
├── .gitignore
├── README.md
├── analysis_options.yaml
├── pubspec.yaml
├── assets/
│   ├── icons/
│   └── images/
├── docs/                        # Complete Architecture Blueprint
│   ├── README.md
│   ├── architecture.md
│   └── ...
├── scripts/                     # Standalone CLI tools & generators
│   ├── generate_api_client.sh
│   └── generate_api_client.bat
├── lib/
│   ├── main.dart                # App entrypoint, Sentry & bootstrap init
│   ├── app/                     # App-level orchestration
│   │   ├── app.dart             # Root ConsumerStatefulWidget & MaterialApp.router
│   │   ├── router.dart          # GoRouter table, StatefulShellRoute, Auth guards
│   │   └── theme/
│   │       ├── app_theme.dart   # Material 3 ThemeData builder
│   │       └── tokens.dart      # Design tokens (Colors, Spacing, Radii, Typography)
│   ├── core/                    # Cross-cutting foundational modules
│   │   ├── authorization/       # RBAC roles, permissions, and AuthorizationService
│   │   │   ├── authorization_providers.dart
│   │   │   ├── authorization_service.dart
│   │   │   ├── community_authorization.dart
│   │   │   ├── permissions.dart
│   │   │   └── roles.dart
│   │   ├── config/              # Compile-time configuration & validation
│   │   │   └── app_config.dart
│   │   ├── error/               # Failure taxonomy & error classifiers
│   │   │   ├── delegated_error_classifier.dart
│   │   │   └── failure.dart
│   │   ├── logging/             # Telemetry & Sentry logger
│   │   │   └── app_logger.dart
│   │   ├── providers.dart       # Core root providers (appConfig, apiClient)
│   │   ├── result/              # Functional Result<T> (Success | Err)
│   │   │   └── result.dart
│   │   └── utils/               # Device & timezone hardware utilities
│   │       ├── device_utils.dart
│   │       └── timezone_utils.dart
│   ├── infrastructure/          # Platform adapters & external boundaries
│   │   ├── api/                 # Low-level API clients & health repo
│   │   │   └── health_repository.dart
│   │   ├── notifications/       # OS notification & reminder scheduling
│   │   │   ├── local_notification_service.dart
│   │   │   └── notification_service.dart
│   │   └── storage/             # Hardware secure storage & local persistence
│   │       ├── flutter_secure_store.dart
│   │       ├── local_store.dart
│   │       └── secure_store.dart
│   ├── features/                # Domain-driven feature modules
│   │   ├── auth/                # Authentication, sessions & token rotation
│   │   │   ├── application/
│   │   │   │   ├── auth_controller.dart
│   │   │   │   └── auth_providers.dart
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   ├── authenticated_api_client.dart
│   │   │   │   └── session_manager.dart
│   │   │   ├── domain/
│   │   │   │   └── session_models.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   ├── register_screen.dart
│   │   │       │   └── welcome_screen.dart
│   │   │       └── widgets/
│   │   └── _feature_template/   # Canonical boilerplate for new features
│   │       ├── application/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │           ├── screens/
│   │           └── widgets/
│   └── shared/                  # Reusable domain-agnostic UI components
│       └── widgets/
│           ├── require_permission.dart
│           ├── require_role.dart
│           └── route_guard.dart
└── test/                        # Comprehensive test suite
    ├── support/                 # In-memory test fakes & mock clients
    │   └── fakes.dart
    ├── core/
    ├── features/
    └── infrastructure/
```

---

## 2. Directory Taxonomy & Responsibility Matrix

| Directory | Purpose | Included Files | Prohibited Files |
|---|---|---|---|
| `lib/app/` | App shell, navigation routing, global theme | `app.dart`, `router.dart`, `theme/*` | Feature widgets, API repositories, business controllers |
| `lib/core/` | Enterprise cross-cutting concerns (config, result, authz, logging) | `app_config.dart`, `result.dart`, `roles.dart`, `permissions.dart` | Feature UI, Screen widgets, specific feature business logic |
| `lib/infrastructure/` | Native platform boundary adapters (storage, alarms, hardware) | `flutter_secure_store.dart`, `local_notification_service.dart` | UI widgets, domain entities, routing logic |
| `lib/features/<name>/` | Self-contained vertical feature slice | `application/`, `data/`, `domain/`, `presentation/` | Code belonging to another feature slice |
| `lib/shared/` | Reusable global UI widgets (guards, buttons, cards) | `route_guard.dart`, `require_role.dart` | Feature-specific business screens, API clients |

---

## 3. Placement Decision Rules

When adding a new file, follow this decision tree:

1. **Is it a screen reachable by URL/Route?**
   -> `lib/features/<feature>/presentation/screens/<name>_screen.dart`
2. **Is it a widget used only in one feature?**
   -> `lib/features/<feature>/presentation/widgets/<name>.dart`
3. **Is it a reusable UI widget used across 3+ features with no domain logic?**
   -> `lib/shared/widgets/<name>.dart`
4. **Is it a Riverpod controller managing screen/feature state?**
   -> `lib/features/<feature>/application/<name>_controller.dart`
5. **Is it a repository making API calls or managing domain caching?**
   -> `lib/features/<feature>/data/<name>_repository.dart`
6. **Is it an adapter calling platform native APIs (Keychain, GPS, Notifications)?**
   -> `lib/infrastructure/<subsystem>/<name>.dart`
