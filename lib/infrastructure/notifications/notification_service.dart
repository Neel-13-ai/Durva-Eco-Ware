abstract interface class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String body,
    required DateTime when,
  });
  Future<void> cancel(String id);
  Future<void> cancelAll();
}
