import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/authorization/authorization_providers.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_providers.dart';

class RouteGuard extends ConsumerWidget {
  const RouteGuard({
    super.key,
    this.roles,
    this.permissions,
    this.fallbackRoute = '/home',
    this.showAccessDenied = false,
    required this.child,
  });

  final Widget child;
  final Set<String>? roles;
  final Set<String>? permissions;
  final String fallbackRoute;
  final bool showAccessDenied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authz = ref.watch(authorizationServiceProvider);

    if (authState.status == AuthStatus.unknown) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final hasRoleAccess = roles == null || roles!.isEmpty || authz.hasAnyRole(roles!);
    final hasPermAccess = permissions == null || permissions!.isEmpty || authz.hasAnyPermission(permissions!);

    if (!hasRoleAccess || !hasPermAccess) {
      if (showAccessDenied) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Access Denied', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(fallbackRoute);
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}
