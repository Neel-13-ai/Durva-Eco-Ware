import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/result/result.dart';
import '../data/auth_repository.dart';
import '../data/session_manager.dart';
import '../domain/session_models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, verificationFailed }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });
  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final UserDto? user;
  final String? errorMessage;
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
    try {
      final outcome = await _repository.restoreSession();
      if (!mounted) return;
      switch (outcome.status) {
        case SessionRestoreStatus.authenticated:
          state = AuthState(status: AuthStatus.authenticated, user: outcome.user);
        case SessionRestoreStatus.unauthenticated:
          state = const AuthState(status: AuthStatus.unauthenticated);
        case SessionRestoreStatus.temporaryFailure:
          state = AuthState(
            status: AuthStatus.verificationFailed,
            user: outcome.user,
            errorMessage: outcome.errorMessage ??
                'Unable to verify your session. Check your connection and retry.',
          );
      }
    } catch (_) {
      if (!mounted) return;
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> retryBootstrap() async {
    if (state.status == AuthStatus.authenticated) return;
    state = AuthState(status: AuthStatus.unknown, user: state.user);
    await _bootstrap();
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
