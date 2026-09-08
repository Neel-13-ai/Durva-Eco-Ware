# Coding Conventions & Engineering Standards

## 1. Naming Conventions

| Category | Convention | Examples |
|---|---|---|
| Files & Directories | `snake_case.dart` | `auth_controller.dart`, `session_manager.dart`, `route_guard.dart` |
| Classes & Enums | `PascalCase` | `AuthController`, `AppConfig`, `SessionManager`, `AuthStatus` |
| Riverpod Providers | `camelCaseProvider` | `authControllerProvider`, `apiClientProvider`, `appConfigProvider` |
| Notifiers / Controllers | `PascalCaseController` / `PascalCaseNotifier` | `AuthController`, `CommunityBrowseController` |
| Repositories | `PascalCaseRepository` | `AuthRepository`, `CommunityRepository` |
| Domain Models | `PascalCase` / `PascalCaseDto` | `SessionSummaryDto`, `AuthenticatedUserDto` |
| Private Members | `_camelCase` | `_session`, `_accessToken`, `_bootstrap()` |
| Constants | `kCamelCase` or `UPPER_CASE` | `kMemberAppBarTeal`, `BrandColors.primary` |

---

## 2. Layer Import Discipline

- Features must **never** import other features' internal `data/` or `application/` folders directly.
- Shared communication must happen via public interfaces in `lib/shared/` or global domain providers in `lib/core/`.
- UI Screens must never import low-level OpenAPI transport packages directly.

---

## 3. Asynchronous Code Best Practices

- Always check `if (!mounted) return;` after `await` calls inside `ConsumerState` or `StateNotifier` callbacks before mutating state.
- Use `unawaited(...)` from `dart:async` for intentional fire-and-forget background tasks (e.g. silent timezone sync).
- Combine parallel, independent async operations using `Future.wait([op1, op2])`.
