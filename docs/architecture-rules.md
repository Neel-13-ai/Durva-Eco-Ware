# Non-Negotiable Architecture Rules

1. **RULE 1: No Direct HTTP in UI Widgets**  
   Widgets must never instantiate `http.Client`, call API client methods, or process raw JSON. All data access must pass through domain repositories.

2. **RULE 2: Repositories Must Return `Result<T>`**  
   Repositories must catch all transport, parsing, and server exceptions and return `Success<T>` or `Err<T>`. Never let low-level transport exceptions propagate into the UI.

3. **RULE 3: Strict Token Separation**  
   Access tokens must live in memory only. Refresh tokens must be written exclusively to `SecureStore` (Keychain/Keystore). Never persist access tokens or auth secrets to disk or logs.

4. **RULE 4: Single-Flight 401 Refresh**  
   Concurrent 401 unauthorized responses must share a single in-flight token refresh promise to prevent refresh storms and race conditions.

5. **RULE 5: Compile-Time Configuration**  
   All environment-specific configuration must be passed via `--dart-define` and validated at startup in `AppConfig.fromEnvironment()`. Secrets must never be committed to source control.

6. **RULE 6: Feature Encapsulation**  
   Feature-specific widgets, models, controllers, and repositories must remain private inside their feature directory. Features must not import internal files of sibling features.

7. **RULE 7: Declarative Auth Routing**  
   Navigation redirects must react declaratively to `authControllerProvider` in `GoRouter`. Never perform imperative ad-hoc screen pushes upon authentication state changes.

8. **RULE 8: Server-Authoritative Permissions**  
   Client-side role and permission checks (`RequireRole`, `RequirePermission`, `RouteGuard`) are strictly UX affordances. The backend API is always the final authority on access control.
