import '../../features/auth/domain/session_models.dart';
import 'permissions.dart';
import 'roles.dart';

class AuthorizationService {
  const AuthorizationService(this._user);
  final UserDto? _user;

  bool get isAuthenticated => _user != null;
  List<String> get roles => _user?.roles ?? [];
  Set<String> get permissions => permissionsForRoles(roles);

  bool get isAdmin => hasRole(AppRole.admin);
  bool hasRole(String role) => roles.contains(role);
  bool hasAnyRole(Iterable<String> checkRoles) => checkRoles.any(roles.contains);
  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasAnyPermission(Iterable<String> checkPermissions) =>
      checkPermissions.any(permissions.contains);
}
