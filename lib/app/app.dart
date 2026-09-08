import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/notifications/local_notification_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class DurvaecoApp extends ConsumerStatefulWidget {
  const DurvaecoApp({super.key});

  @override
  ConsumerState<DurvaecoApp> createState() => _DurvaecoAppState();
}

class _DurvaecoAppState extends ConsumerState<DurvaecoApp> {
  @override
  void initState() {
    super.initState();
    LocalNotificationService.onNotificationNavigation = (route) {
      if (mounted) {
        ref.read(routerProvider).push(route);
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (LocalNotificationService.pendingLaunchRoute != null) {
        final route = LocalNotificationService.pendingLaunchRoute!;
        LocalNotificationService.pendingLaunchRoute = null;
        if (mounted) {
          ref.read(routerProvider).push(route);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Durvaeco',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
