abstract final class AppRole {
  static const user = 'USER';
  static const manager = 'MANAGER';
  static const admin = 'ADMIN';

  static const all = {user, manager, admin};
  static const standardRoles = {user, manager};
}
