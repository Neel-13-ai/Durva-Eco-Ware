# Configuration & Compile-Time Environment Strategy

## 1. Architectural Strategy: `--dart-define`

Durvaeco utilizes compile-time `--dart-define` variables instead of `.env` assets or hardcoded strings.

### Key Benefits:
- Zero runtime file I/O for configuration.
- Tree-shaken at compile time.
- Prevents server secrets from ever being bundled into client binaries.

---

## 2. AppConfig Implementation (`lib/core/config/app_config.dart`)

```dart
enum AppEnvironment { local, dev, staging, production }

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
    this.sentryDsn = _defaultSentryDsn,
  });

  final String apiBaseUrl;
  final AppEnvironment environment;
  final String sentryDsn;

  static const String _defaultSentryDsn = 'https://...';

  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3030',
  );

  static const String _environmentDefine = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static const String _sentryDsnDefine = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: _defaultSentryDsn,
  );

  factory AppConfig.fromEnvironment() {
    final uri = Uri.tryParse(_apiBaseUrlDefine);
    if (uri == null || !uri.hasScheme || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw ArgumentError(
        'Invalid API_BASE_URL "$_apiBaseUrlDefine". Provide an absolute http(s) URL '
        'via --dart-define=API_BASE_URL=...',
      );
    }
    return AppConfig(
      apiBaseUrl: _apiBaseUrlDefine,
      environment: _parseEnvironment(_environmentDefine),
      sentryDsn: _sentryDsnDefine,
    );
  }
}
```
