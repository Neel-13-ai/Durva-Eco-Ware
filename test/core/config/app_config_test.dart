import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/core/config/app_config.dart';

void main() {
  test('AppConfig parses default environment values correctly', () {
    final config = AppConfig.fromEnvironment();
    expect(config.apiBaseUrl, equals('https://api-dev.durvaecoware.com'));
    expect(config.environment, equals(AppEnvironment.dev));
  });
}
