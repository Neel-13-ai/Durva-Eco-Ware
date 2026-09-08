import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/authorization/authorization_providers.dart';

class RequireRole extends ConsumerWidget {
  const RequireRole({
    super.key,
    required this.roles,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final Set<String> roles;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authz = ref.watch(authorizationServiceProvider);
    if (authz.hasAnyRole(roles)) {
      return child;
    }
    return fallback;
  }
}
