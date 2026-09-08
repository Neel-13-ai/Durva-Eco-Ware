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

  static const String _defaultSentryDsn = '';

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
    if (uri == null ||
        !uri.hasScheme ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
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

  static AppEnvironment _parseEnvironment(String value) {
    switch (value.toLowerCase()) {
      case 'dev':
        return AppEnvironment.dev;
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'local':
      default:
        return AppEnvironment.local;
    }
  }
}
