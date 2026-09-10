# [Feature]: Authentication, Session Lifecycle, RBAC & Application Settings

## 1. Feature Overview & Objective
Implement the enterprise-grade Authentication and Session Management system for Durva Eco Ware. Ensure secure JWT token persistence, transparent session restoration, role-based access control (RBAC), and global configuration loading for `AppSettings`, `CompanySettings`, and user roles.

---

## 2. Target Screens & UI Components
- **Login Screen** (`lib/features/auth/presentation/screens/login_screen.dart`): Username & password inputs, password visibility toggle, login button with spinner, environment badge, company branding.
- **Session Expiry / Re-Auth Dialog** (`lib/shared/dialogs/reauth_dialog.dart`): Prompts user on 401 Unauthorized API responses to re-authenticate without losing current form data.
- **Settings Screen** (`lib/features/settings/presentation/screens/app_settings_screen.dart`): Company profile details, tax number, currency settings, theme toggle, and version info.
- **Role Guard Wrappers** (`lib/shared/widgets/require_role.dart`, `require_permission.dart`): UI widgets for conditional rendering based on user role permissions.

### Screen State Requirements
- **Initial**: Form empty, submit button enabled once validation passes.
- **Submitting**: Input fields disabled, submit button displays circular progress indicator, double-submit disabled.
- **Success**: Animate transition via GoRouter to `/home` (or deep-linked redirect).
- **Error**: Inline field errors (empty/invalid format) and toast/banner on bad credentials (401) or network failure.

---

## 3. API Contracts & Endpoints
| Action | Method | Endpoint | Query / Body | Expected Response |
|---|---|---|---|---|
| Login | `POST` | `/api/auth/login` | `{ "UserName": "string", "Password": "string" }` | `{ "token": "jwt_string", "userId": 1, "role": "Admin", "userName": "admin" }` |
| List App Settings | `GET` | `/api/app-settings` | `?includeInactive=false` | `[ { "id": 1, "settingKey": "string", "settingValue": "string" } ]` |
| Get App Setting by ID | `GET` | `/api/app-settings/{id}` | - | `{ "id": 1, "settingKey": "string", "settingValue": "string" }` |
| Create App Setting | `POST` | `/api/app-settings` | `{ "settingKey": "string", "settingValue": "string" }` | `{ "id": 1, ... }` |
| Update App Setting | `PUT` | `/api/app-settings/{id}` | `{ "settingKey": "string", "settingValue": "string" }` | `200 OK / 204 No Content` |
| Delete App Setting | `DELETE` | `/api/app-settings/{id}` | - | `200 OK / 204 No Content` |
| List Company Settings | `GET` | `/api/company-settings` | `?includeInactive=false` | `[ { "id": 1, "companyName": "string", "address": "string", "phone": "string", "email": "string", "website": "string", "taxNumber": "string", "logoUrl": "string", "currencyCode": "string", "isActive": true } ]` |
| Update Company Setting | `PUT` | `/api/company-settings/{id}` | Full company settings JSON | `200 OK` |
| List Roles | `GET` | `/api/roles` | `?includeInactive=false` | `[ { "id": 1, "roleName": "Admin", "description": "string", "isActive": true } ]` |

---

## 4. Architecture & State Management
- **Domain**: `AuthSession`, `UserProfile`, `AppSetting`, `CompanySetting`, `Role` entities.
- **Data**: `AuthRepository`, `SettingsRepository`, `FlutterSecureStore` for persistent JWT storage.
- **Application**:
  - `authControllerProvider` (`AsyncNotifier<AuthState>`): Controls login, logout, and token refresh.
  - `currentUserProvider`: Computes active session details, roles, and permissions.
  - `companySettingsProvider`: FutureProvider caching company-wide metadata (currency, company name, tax ID).

---

## 5. Form Validation & Business Rules
- **Username**: Required, trimmed, minimum 3 characters.
- **Password**: Required, minimum 6 characters.
- **JWT Storage**: Tokens must only be stored in secure storage (`FlutterSecureStorage`), never SharedPreferences.
- **Header Injection**: All outgoing authenticated API requests must attach `Authorization: Bearer <token>`.
- **401 Interception**: When backend returns 401, automatically trigger session logout or re-auth dialog.

---

## 6. Edge Cases & Failure Modes
- **No Internet on Login**: Display descriptive network error banner; do not crash or hang.
- **Expired Token**: Redirect to `/login` with a clear message: "Your session has expired. Please log in again."
- **Invalid Credentials (401)**: Display "Invalid username or password" on form without clearing username.
- **Concurrent API Requests during Token Expiry**: Queue or deduplicate auth refresh to avoid cascading 401 errors.
- **App Restart**: Background session validation without screen flickering.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `AuthRepositoryTest`: Successful login, 401 unauthorized handling, network timeout classification.
  - `AuthControllerTest`: State transition from `AsyncLoading` to `AsyncData` or `AsyncError`.
  - `SessionManagerTest`: Token read/write to `SecureStore`.
- [ ] **Widget Tests**:
  - `LoginScreenTest`: Form validation triggers correctly; button shows loading state on submit.
  - `RequireRoleWidgetTest`: Shows child if role matches, renders placeholder/hidden if unauthorized.
- [ ] **Integration Test**:
  - Complete flow: Launch app -> Enter credentials -> Post `/api/auth/login` -> Save token -> Navigate to Dashboard.

---

## 💬 Antigravity Agent Resolution & Verification Comments
- **Reviewer**: `Antigravity Agent`
- **Label**: `[Status: Verified & Resolved]`, `[Scope: Client-Side Session]`
- **Resolution**:
  - `POST /api/auth/login` verified live with `superadmin` / `123456`.
  - Non-standard endpoints (`/api/auth/me`, `/api/auth/refresh`, `/api/auth/logout`) are **not implemented on backend server** (return HTTP 404). Session persistence is securely managed via `FlutterSecureStorage` and JWT decoding client-side.
  - Test Status: `AuthRepository` & authorization tests passing.
