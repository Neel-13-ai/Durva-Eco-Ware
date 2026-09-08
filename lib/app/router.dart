import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../shared/widgets/route_guard.dart';

const _publicRoutes = {'/', '/login'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authControllerProvider, (_, next) => refresh.value = next);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    observers: [SentryNavigatorObserver()],
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      if (auth.status == AuthStatus.unknown) return null;
      if (auth.status == AuthStatus.unauthenticated) {
        return _publicRoutes.contains(location) ? null : '/login';
      }
      if (location == '/' || location == '/login') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const RouteGuard(child: HomeScreen()),
      ),
    ],
  );
});
