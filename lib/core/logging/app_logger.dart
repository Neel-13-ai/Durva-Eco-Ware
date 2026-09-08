import 'dart:developer' as developer;
import 'package:sentry_flutter/sentry_flutter.dart';

class AppLogger {
  const AppLogger(this.name);
  final String name;

  void info(String message) {
    developer.log(message, name: name, level: 800);
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: name, level: SentryLevel.info),
    );
  }

  void warn(String message) {
    developer.log(message, name: name, level: 900);
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: name, level: SentryLevel.warning),
    );
  }

  void error(String message, [Object? err, StackTrace? stack]) {
    developer.log(message, name: name, level: 1000, error: err, stackTrace: stack);
    if (err != null) {
      Sentry.captureException(
        err,
        stackTrace: stack,
        withScope: (scope) {
          scope.setTag('logger', name);
          scope.setTag('message', message);
        },
      );
    } else {
      Sentry.captureMessage('[$name] $message', level: SentryLevel.error);
    }
  }
}
