# Technical Debt & Architecture Risk Audit

Audit of the Reference Project (`MedBuddieApps`) architecture, detailing what was validated as best practice versus areas requiring care during migration.

## 1. Existing Strengths (Best Practices Validated)
- **Robust Token Lifecycle**: Single-flight 401 refresh mechanism in `SessionManager` prevents token race conditions.
- **Clean Result Pattern**: Using sealed `Result<T>` eliminates unhandled UI runtime exceptions.
- **Stateful Shell Routing**: `StatefulShellRoute.indexedStack` provides native-feeling bottom tab navigation with preserved tab histories.
- **Strict Configuration Fast-Fail**: `AppConfig.fromEnvironment()` asserts URL validity at startup.

---

## 2. Architectural Risks & Anti-Patterns to Avoid
1. **Transitive Dependency Conflicts in Test Runners**:  
   *Risk*: On newer Flutter versions (3.24+), `path_provider` platform plugins on desktop test runners can fail if experimental native assets are not pinned.  
   *Remedy*: Use the pinned `dependency_overrides` documented in `dependencies.md`.

2. **Cross-Feature Imports**:  
   *Risk*: Sibling features importing each other's private controllers leads to circular dependencies.  
   *Remedy*: Expose shared models and services through `lib/shared/` or `lib/core/`.

3. **Overly Large Router Files**:  
   *Risk*: In the reference project, `router.dart` grew to 630+ lines containing all route definitions.  
   *Remedy*: In Durvaeco, route configurations for complex features can be split into modular route sub-tables and registered in `router.dart`.
