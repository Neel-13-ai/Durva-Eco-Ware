import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/core/config/app_config.dart';

void main() {
  test('AppConfig parses default environment values correctly', () {
    final config = AppConfig.fromEnvironment();
    expect(config.apiBaseUrl, isNotEmpty);
    expect(config.environment, AppEnvironment.local);
  });
}
