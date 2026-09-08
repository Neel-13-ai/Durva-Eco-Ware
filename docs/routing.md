# Routing & Navigation Architecture (GoRouter)

## 1. Core Architecture

Routing is centralized in `lib/app/router.dart` using **GoRouter** (`go_router: ^14.6.2`). The router is exposed as a Riverpod `Provider<GoRouter>` and listens reactively to `authControllerProvider` changes via a `ValueNotifier<AuthState>`.

---

## 2. Stateful Shell Navigation (Persistent Bottom Tabs)

The application uses `StatefulShellRoute.indexedStack` to maintain the state, scroll positions, and navigation histories of persistent bottom navigation tabs:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return MemberShell(navigationShell: navigationShell);
  },
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(path: '/explore', builder: (context, state) => const ExploreScreen()),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/communities',
          builder: (context, state) => const MemberRouteGuard(child: CommunityBrowseScreen()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MemberRouteGuard(child: ProfileScreen()),
        ),
      ],
    ),
  ],
)
```

---

## 3. Global Auth Redirect Rules

```dart
redirect: (context, state) {
  final auth = ref.read(authControllerProvider);
  final location = state.matchedLocation;

  // 1. Startup: Keep splash/loader while resolving persisted session
  if (auth.status == AuthStatus.unknown) return null;

  // 2. Unauthenticated: Redirect protected route access to /login
  if (auth.status == AuthStatus.unauthenticated) {
    return _publicRoutes.contains(location) ? null : '/login';
  }

  // 3. Suspended / Inactive Account: Force /login
  if (auth.user?.status.value != 'ACTIVE') {
    return '/login';
  }

  // 4. Authenticated: Redirect landing/login/register pages to /home
  if (location == '/' || location == '/login' || location == '/register') {
    return '/home';
  }

  return null;
}
```

---

## 4. Deep Link Dispatcher

Custom URL schemes (e.g. `durvaeco://reset-password?token=...` or `durvaeco://verify-email?token=...`) are parsed inside `redirect`:

```dart
if (uri.host == 'reset-password' && state.matchedLocation != '/reset-password') {
  final token = uri.queryParameters['token'] ?? '';
  return '/reset-password?token=$token';
}
```
