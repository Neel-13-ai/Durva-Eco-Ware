import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/utils/device_utils.dart';
import 'infrastructure/notifications/local_notification_service.dart';

Future<void> main() async {
  final config = AppConfig.fromEnvironment();

  Future<void> appRunner() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Initialize hardware device name and local notifications
    await Future.wait([
      LocalNotificationService.instance.initialize(),
      initDeviceName(),
    ]);
    runApp(const ProviderScope(child: DurvaecoApp()));
  }

  if (config.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = config.sentryDsn;
        options.environment = config.environment.name;
        options.tracesSampleRate = 1.0;
      },
      appRunner: appRunner,
    );
  } else {
    await appRunner();
  }
}
