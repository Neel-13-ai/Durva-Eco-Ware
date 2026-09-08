# Role-Based Access Control (RBAC) & Permission Architecture

## 1. Architectural Principle: Client UX Gates vs Server Enforcement

Client-side roles and permissions exist **strictly for UX affordances** (showing/hiding action buttons, rendering tab options, or displaying Access Denied views). The backend API independently enforces authorization on every request.

---

## 2. Roles & Permissions Taxonomy

Located in `lib/core/authorization/`:

1. **`roles.dart`**:
   - `AppRole.patient = 'PATIENT'`
   - `AppRole.caregiver = 'CAREGIVER'`
   - `AppRole.physician = 'PHYSICIAN'`
   - `AppRole.moderator = 'MODERATOR'`
   - `AppRole.admin = 'ADMIN'`
   - Role sets: `memberRoles`, `sharedMemberRoles`.

2. **`permissions.dart`**:
   - Granular string constants (e.g. `AppPermission.communityPostCreate`, `AppPermission.medpostCreate`).
   - Role-to-permission mapping dictionary (`rolePermissions`).
   - Self-scoped permission detector (`isSelfPermission(permission)`).

---

## 3. AuthorizationService

```dart
class AuthorizationService {
  const AuthorizationService(this._user);
  final AuthenticatedUserDto? _user;

  bool get isAuthenticated => _user != null;
  List<String> get roles => _user?.roles ?? [];
  Set<String> get permissions => permissionsForRoles(roles);

  bool hasRole(String role) => roles.contains(role);
  bool hasAnyRole(Iterable<String> checkRoles) => checkRoles.any(roles.contains);
  bool hasPermission(String permission) => permissions.contains(permission);
}
```

---

## 4. Declarative UI Authorization Widgets

```dart
// 1. Role-based Conditional Rendering
RequireRole(
  roles: {AppRole.physician, AppRole.admin},
  fallback: const Text('Physicians only'),
  child: const VerifiedBadge(),
)

// 2. Permission-based Button Gate
RequirePermission(
  permission: AppPermission.communityPostCreate,
  child: FloatingActionButton(
    onPressed: () => _openPostComposer(context),
    child: const Icon(Icons.add),
  ),
)

// 3. Route Guard
GoRoute(
  path: '/admin',
  builder: (context, state) => const RouteGuard(
    roles: {AppRole.admin},
    showAccessDenied: true,
    child: AdminDashboardScreen(),
  ),
)
```
