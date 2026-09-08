# Durvaeco Architecture & Migration Blueprint

> **Standalone Flutter Enterprise Architecture Blueprint**  
> Extracted, audited, and adapted from the mature Reference Project (`MedBuddieApps`).

---

## Executive Summary

This documentation suite serves as the complete, authoritative engineering blueprint for building the **Durvaeco** Flutter application as a **clean, modular, standalone Flutter application**.

The Reference Project (`MedBuddieApps`) implements a production-grade 4-layer architecture combining:
1. **Riverpod** (`flutter_riverpod: ^2.6.1`) for reactive, compile-time safe state management and dependency injection.
2. **GoRouter** (`go_router: ^14.6.2`) with stateful shell branching (persistent bottom tabs) and role/permission-based navigation guards.
3. **OpenAPI-derived client architecture** with transparent JWT rotation, custom platform header injection, and functional `Result<T>` error handling.
4. **Clean boundary abstractions** for device storage, local scheduling/notifications, hardware permissions, and observability.

This blueprint decouples these proven patterns from the Reference monorepo (removing `pnpm`, `turbo`, TypeScript workspace packages, and monorepo scripts) and reproduces them within standard Flutter conventions.

---

## Blueprint Navigation Index

| Document | Responsibility & Content |
|---|---|
| [1. Architecture Overview](file:///C:/workspace/durvaeco/docs/architecture.md) | 4-layer clean architecture, layer responsibilities, data flow direction, and layer separation rules. |
| [2. Folder Structure](file:///C:/workspace/durvaeco/docs/folder-structure.md) | File-by-file directory taxonomy, placement rules, and anti-patterns. |
| [3. Dependency Matrix](file:///C:/workspace/durvaeco/docs/dependencies.md) | Complete runtime & dev dependency breakdown, version pins, and rationale. |
| [4. Authentication & Session Architecture](file:///C:/workspace/durvaeco/docs/authentication.md) | Token lifecycles (memory access + secure storage refresh), single-flight 401 refresh, and auth guards. |
| [5. API & Network Architecture](file:///C:/workspace/durvaeco/docs/api-architecture.md) | OpenAPI contract workflow, `AuthenticatedApiClient`, header injection, and repository encapsulation. |
| [6. State Management](file:///C:/workspace/durvaeco/docs/state-management.md) | Riverpod pattern: `StateNotifier`, `FutureProvider`, `Provider`, and lifecycle management. |
| [7. Routing & Navigation](file:///C:/workspace/durvaeco/docs/routing.md) | `GoRouter` configuration, `StatefulShellRoute.indexedStack`, deep links, and guard architecture. |
| [8. RBAC & Permissions](file:///C:/workspace/durvaeco/docs/permissions.md) | Client-side role/permission mapping, `AuthorizationService`, and conditional UI rendering. |
| [9. Widget Architecture](file:///C:/workspace/durvaeco/docs/widgets.md) | Screen vs feature-widget vs shared-widget separation, design tokens, and theme contract. |
| [10. Feature Architecture & Template](file:///C:/workspace/durvaeco/docs/feature-architecture.md) | Anatomy of a feature module and the copy-pasteable canonical feature template. |
| [11. End-to-End Data Flow](file:///C:/workspace/durvaeco/docs/data-flow.md) | Sequence diagrams for Authentication, GET queries, POST mutations, and Local Storage. |
| [12. Error Handling & Failure Modeling](file:///C:/workspace/durvaeco/docs/error-handling.md) | Sealed `Result<T>` pattern, `Failure` hierarchy, and user-facing error translation. |
| [13. Configuration & Environments](file:///C:/workspace/durvaeco/docs/configuration.md) | `--dart-define` compile-time configuration, environment parsing, and secret isolation. |
| [14. Testing Strategy](file:///C:/workspace/durvaeco/docs/testing.md) | Unit, widget, and repository testing using `FakeApi`, `InMemorySecureStore`, and Riverpod overrides. |
| [15. Coding Conventions](file:///C:/workspace/durvaeco/docs/coding-conventions.md) | File naming, symbol conventions, immutability rules, and style standards. |
| [16. Monorepo → Standalone Migration Guide](file:///C:/workspace/durvaeco/docs/monorepo-to-standalone.md) | KEEP / REMOVE / ADAPT mapping from the Reference monorepo to standalone Flutter. |
| [17. Implementation Order & Setup Guide](file:///C:/workspace/durvaeco/docs/implementation-guide.md) | Step-by-step foundation setup sequence for new developers before writing features. |
| [18. Architecture Rules](file:///C:/workspace/durvaeco/docs/architecture-rules.md) | Non-negotiable architectural commandments and linting rules. |
| [19. Technical Debt & Risks Audit](file:///C:/workspace/durvaeco/docs/technical-debt-and-risks.md) | Audit findings from the Reference Project: strengths, gotchas, and patterns to avoid. |

---

## Architectural Principles at a Glance

```text
┌───────────────────────────────────────────────────────────────┐
│                      Presentation Layer                       │
│     Screens (GoRoute targets) & Feature / Shared Widgets      │
└──────────────────────────────┬────────────────────────────────┘
                               │ Watches / Reads
                               ▼
┌───────────────────────────────────────────────────────────────┐
│                   Application / State Layer                   │
│   Riverpod Providers, StateNotifiers & AuthorizationService   │
└──────────────────────────────┬────────────────────────────────┘
                               │ Invokes
                               ▼
┌───────────────────────────────────────────────────────────────┐
│                   Domain & Repository Layer                   │
│   Domain Models, Value Objects & Data Repositories (Result<T>)│
└──────────────────────────────┬────────────────────────────────┘
                               │ Calls
                               ▼
┌───────────────────────────────────────────────────────────────┐
│                     Infrastructure Layer                      │
│   AuthenticatedApiClient, SecureStore, LocalNotificationService│
└───────────────────────────────────────────────────────────────┘
```

1. **Zero Raw HTTP in Presentation**: UI components must never instantiate `http.Client`, call API endpoints, or process raw JSON. All data access flows through repositories.
2. **Never Throw Across Boundaries**: Repositories catch low-level transport errors and return `Result<T>` (`Success<T>` or `Err<T>`), allowing the UI to handle loading/error/success states declaratively.
3. **Strict Secret & Token Isolation**: Access tokens remain in memory only. Refresh tokens are persisted exclusively via platform Keychain/Keystore (`FlutterSecureStorage`). No secrets are ever hardcoded or logged.
4. **Compile-Time Environment Binding**: All configuration is injected via `--dart-define` and validated at startup via `AppConfig.fromEnvironment()`.
