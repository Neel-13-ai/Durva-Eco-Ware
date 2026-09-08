import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? _sharedPlugin;

  static final FlutterLocalNotificationsPlugin _sharedPlugin =
      FlutterLocalNotificationsPlugin();
  static final LocalNotificationService instance =
      LocalNotificationService(plugin: _sharedPlugin);

  static void Function(String route)? onNotificationNavigation;
  static String? pendingLaunchRoute;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  Future<void> initialize() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (response) {
          final target = response.payload ?? '/home';
          if (onNotificationNavigation != null) {
            onNotificationNavigation!(target);
          } else {
            pendingLaunchRoute = target;
          }
        },
      );
      _ready = true;
    } catch (e) {
      debugPrint('LocalNotificationService.initialize error: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    return true;
  }

  @override
  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await initialize();
    if (!_ready) return;
    final tzWhen = tz.TZDateTime.from(when.toLocal(), tz.local);
    await _plugin.zonedSchedule(
      id: id.hashCode & 0x7fffffff,
      title: title,
      body: body,
      scheduledDate: tzWhen,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('durvaeco_reminders', 'Reminders'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(String id) async {
    await _plugin.cancel(id: id.hashCode & 0x7fffffff);
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
