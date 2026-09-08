import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/core/authorization/authorization_service.dart';
import 'package:durvaeco/core/authorization/permissions.dart';
import 'package:durvaeco/core/authorization/roles.dart';
import 'package:durvaeco/features/auth/domain/session_models.dart';

void main() {
  test('AuthorizationService grants correct permissions for Admin role', () {
    const user = UserDto(
      id: 'admin-1',
      email: 'admin@durvaeco.com',
      displayName: 'Admin',
      roles: [AppRole.admin],
    );
    const service = AuthorizationService(user);
    expect(service.isAdmin, isTrue);
    expect(service.hasPermission(AppPermission.adminAccess), isTrue);
  });
}
