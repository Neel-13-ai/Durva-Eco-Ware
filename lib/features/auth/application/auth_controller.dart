import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/result/result.dart';
import '../data/auth_repository.dart';
import '../data/session_manager.dart';
import '../domain/session_models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user});
  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final UserDto? user;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required SessionManager session,
  })  : _repository = repository,
        _session = session,
        super(const AuthState.unknown()) {
    _session.onInvalidated = _handleInvalidated;
    _bootstrap();
  }

  final AuthRepository _repository;
  final SessionManager _session;

  Future<void> _bootstrap() async {
    final user = await _repository.currentUser();
    if (!mounted) return;
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<Result<UserDto>> login(String email, String password) async {
    final result = await _repository.login(email, password);
    result.when(
      success: (user) {
        if (mounted) state = AuthState(status: AuthStatus.authenticated, user: user);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<void> logout() async {
    await _repository.logout();
    if (mounted) state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _handleInvalidated() {
    if (mounted) state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
