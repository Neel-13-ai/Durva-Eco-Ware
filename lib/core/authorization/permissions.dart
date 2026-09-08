import 'roles.dart';

abstract final class AppPermission {
  static const profileReadSelf = 'PROFILE_READ_SELF';
  static const profileUpdateSelf = 'PROFILE_UPDATE_SELF';
  static const itemRead = 'ITEM_READ';
  static const itemCreate = 'ITEM_CREATE';
  static const itemManage = 'ITEM_MANAGE';
  static const adminAccess = 'ADMIN_ACCESS';
}

const rolePermissions = <String, Set<String>>{
  AppRole.user: {
    AppPermission.profileReadSelf,
    AppPermission.profileUpdateSelf,
    AppPermission.itemRead,
    AppPermission.itemCreate,
  },
  AppRole.manager: {
    AppPermission.profileReadSelf,
    AppPermission.profileUpdateSelf,
    AppPermission.itemRead,
    AppPermission.itemCreate,
    AppPermission.itemManage,
  },
  AppRole.admin: {
    AppPermission.profileReadSelf,
    AppPermission.profileUpdateSelf,
    AppPermission.itemRead,
    AppPermission.itemCreate,
    AppPermission.itemManage,
    AppPermission.adminAccess,
  },
};

Set<String> permissionsForRoles(List<String> roles) {
  final result = <String>{};
  for (final role in roles) {
    final perms = rolePermissions[role];
    if (perms != null) result.addAll(perms);
  }
  return result;
}
