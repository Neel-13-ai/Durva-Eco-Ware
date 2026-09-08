import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_providers.dart';
import 'authorization_service.dart';

final authorizationServiceProvider = Provider<AuthorizationService>((ref) {
  final auth = ref.watch(authControllerProvider);
  return AuthorizationService(auth.user);
});
