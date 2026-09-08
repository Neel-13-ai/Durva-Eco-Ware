# Dependency Matrix & Version Audit

The Reference Project (`MedBuddieApps/apps/mobile/pubspec.yaml`) uses a curated set of dependencies. Every dependency has been audited for architectural necessity and standalone compatibility.

## 1. Runtime Dependencies

| Package | Version | Architectural Responsibility | Used In | Copy to Standalone? | Notes & Rationale |
|---|---|---|---|---|---|
| `flutter` | `sdk: flutter` | Core UI Framework (Material 3) | Everywhere | **YES** | Target Dart SDK `>=3.5.0 <4.0.0` |
| `cupertino_icons` | `^1.0.8` | iOS system glyphs | UI | **YES** | Standard Flutter icon pack |
| `flutter_riverpod` | `^2.6.1` | Compile-time safe state management & DI | `lib/core`, `lib/features` | **YES** | Mandatory. Single deliberate state management choice |
| `go_router` | `^14.6.2` | Declarative URL routing & navigation guards | `lib/app/router.dart` | **YES** | Supports `StatefulShellRoute`, deep linking, and reactive auth redirects |
| `http` | `^1.2.2` | HTTP transport client | `lib/features/auth/data` | **YES** | Pluggable client injected into OpenAPI clients and test fakes |
| `flutter_secure_storage` | `^9.2.2` | Hardware-encrypted storage (Keychain / Keystore) | `lib/infrastructure/storage` | **YES** | Crucial for persisting refresh token without disk exposure |
| `flutter_local_notifications` | `^22.0.1` | Local OS push/alarm notifications | `lib/infrastructure/notifications` | **YES** | Used for medication reminders and local device alerts |
| `timezone` | `^0.11.1` | IANA timezone database & zoned scheduling | `lib/infrastructure/notifications` | **YES** | Required by local notifications for exact alarm scheduling |
| `sentry_flutter` | `^9.27.0` | Crash reporting, error capture & breadcrumbs | `lib/main.dart`, `lib/core/logging` | **YES** | Observability and production error diagnostics |
| `device_info_plus` | `^12.4.0` | Hardware device model & OS resolution | `lib/core/utils/device_utils.dart` | **YES** | Injects `X-Device-Name` for active session tracking |
| `permission_handler` | `^11.3.1` | Runtime OS hardware permission requests | `lib/features/telehealth` | **YES** | Camera, Microphone, and Notification permissions |
| `intl` | `^0.19.0` | Date/time and currency formatting | `lib/features/auth/domain` | **YES** | Internationalization & date string manipulation |
| `flutter_svg` | `^2.0.10+1` | Vector asset rendering | Shared widgets | **YES** | Scalable SVG icons |
| `url_launcher` | `^6.3.2` | External browser & deep link dispatcher | Consent, external links | **YES** | Opens terms, guidelines, external portals |
| `agora_rtc_engine` | `^6.5.4` | WebRTC Real-Time Video/Audio communications | `lib/features/telehealth` | **OPTIONAL** | Include only if Telehealth video visits are required |

---

## 2. Dev Dependencies

| Package | Version | Responsibility | Copy to Standalone? | Notes |
|---|---|---|---|---|
| `flutter_test` | `sdk: flutter` | Unit & Widget testing runner | **YES** | Core testing framework |
| `integration_test` | `sdk: flutter` | End-to-end device integration testing | **YES** | Runs tests on real devices/simulators |
| `flutter_lints` | `^5.0.0` | Official Flutter static analysis rule set | **YES** | Enforces clean coding standards |
| `http/testing.dart` | (via `http`) | `MockClient` for mock HTTP responses in tests | **YES** | Used in `test/support/fakes.dart` |

---

## 3. Dependency Overrides & Compatibility Gotchas

In `pubspec.yaml` of the Reference Project, note this critical comment:

```yaml
# flutter_secure_storage's desktop plugins transitively pull path_provider, whose newest
# platform implementations (objective_c/jni) require the still-experimental "native/dart
# assets" feature and break `flutter test`. Pin to the last pre-native-assets versions so
# the mobile (iOS/Android) build and the test runner stay stable without an experiment flag.
dependency_overrides:
  path_provider_foundation: 2.4.1
  path_provider_android: 2.2.15
```

> [!WARNING]
> If building on Flutter 3.24+ / 3.27+, keep these `dependency_overrides` if `flutter test` encounters issues with experimental Dart native assets in desktop test environments.
