import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/authorization/authorization_providers.dart';

class RequirePermission extends ConsumerWidget {
  const RequirePermission({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final String permission;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authz = ref.watch(authorizationServiceProvider);
    if (authz.hasPermission(permission)) {
      return child;
    }
    return fallback;
  }
}
