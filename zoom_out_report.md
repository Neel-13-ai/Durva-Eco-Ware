# Stage 5 Review Report: Initial Zoom Out

**Target:** `docs/designs/api_routes_standardization_plan.md` (Lines 1–175)  
**Reviewers:** `egm-zoom-out` (Skeptical Architect), `egm-inventive-catalyst` (Inventive Catalyst)  
**Date:** 2026-11-22  

---

## Consolidated Findings

### 🔴 Blocker: Incomplete Audit of Nested & Polymorphic Sub-Resource Updates
* **Reviewer:** `egm-zoom-out`
* **Affected Scope:** `docs/designs/api_routes_standardization_plan.md` (Lines 137–142, Row 20)
* **Discrepancy:** The plan focuses on primary entity CRUD (`update(id, ...)`), but misses polymorphic inline sub-resource operations:
  * In `lib/features/production/data/repositories/production_repository.dart` (lines 201–209), `updateStageEntry` issues:
    `entry.id > 0 ? 'PUT' : 'POST'` directly to `/api/production-stage-entries`.
  * In Swagger, updates must be routed to `POST /api/production-stage-entries/update/{id}`. Without explicitly standardizing this, stripping regex from `ApiClient` will send raw `PUT` to IIS and throw runtime 405 errors.
* **Proposed Action:** Update the plan to explicitly audit and convert all sub-resource update methods (such as `updateStageEntry`) to `ApiEndpoints.update(ApiEndpoints.productionStageEntries, entry.id)` with `POST`.

---

### 🟡 Major: `ApiEndpoints.list` is an Unneeded and Leaky Abstraction (YAGNI)
* **Reviewers:** `egm-zoom-out`, `egm-inventive-catalyst`
* **Affected Scope:** `docs/designs/api_routes_standardization_plan.md` (Lines 29, 47, 72–73)
* **Discrepancy:** The helper `static String list(endpoint, {bool? includeInactive}) => ...` uses fragile string concatenation (`$endpoint?includeInactive=...`). If a repository later appends filters or passes it into `Uri(path: ...)`, it generates invalid query strings like `?categoryId=1?includeInactive=true`. Furthermore, all repositories in this codebase already use idiomatic Dart `Uri(path: ..., queryParameters: {'includeInactive': ...})`.
* **Proposed Action:** Delete `ApiEndpoints.list` from the plan and `ApiEndpoints.dart`. Retain standard `Uri(queryParameters: ...)` across repositories.

---

### 🟡 Major: Semantic Mismatch & Dead 405 Verb Cascades on Status Updates
* **Reviewers:** `egm-zoom-out`, `egm-inventive-catalyst`
* **Affected Scope:** `docs/designs/api_routes_standardization_plan.md` (Lines 33–36, 137)
* **Discrepancy:**
  * In `production_repository.dart` (`updateStatus`), the codebase currently sends a partial status dictionary (`{'status': ...}`) while attempting a cascade: `PUT /status` -> `PATCH` -> `PUT`.
  * Several repositories maintain defensive local state caches (`_cachedOverrides[id]`) catching 405 status codes from IIS WebDAV.
* **Proposed Action:** Standardize `updateStatus` to directly target `ApiEndpoints.update(ApiEndpoints.productionOrders, id)` via `POST` with the required payload, and prune obsolete 405 verb cascades.

---

### 🟢 Nit: Phantom Scope in `ChangePasswordRequest`
* **Reviewer:** `egm-zoom-out`
* **Affected Scope:** `docs/designs/api_routes_standardization_plan.md` (Lines 30, 100)
* **Discrepancy:** `user_repository.dart` already implements the Swagger `ChangePasswordRequest` payload (`currentPassword`, `newPassword`).
* **Proposed Action:** Mark `ChangePasswordRequest` as already completed in the plan to keep the pending implementation scope precise.
