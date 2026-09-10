import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/notifications/data/models/notification_dto.dart';
import 'package:durvaeco/features/notifications/data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return NotificationRepository(client);
});

final notificationsListProvider = FutureProvider.autoDispose<List<NotificationDto>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (notifications) => notifications,
    failure: (failure) => throw Exception(failure.message),
  );
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsListProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
