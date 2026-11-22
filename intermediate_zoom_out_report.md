# Stage 8 Review Report: Intermediate Zoom Out

**Target:** `docs/designs/api_routes_standardization_plan.md` (Full Document)  
**Reviewer:** `egm-zoom-out` (Skeptical Architect)  
**Date:** 2026-11-22  
**Overall Verdict:** **Solid & Pragmatic with Minor Scope Cleanups (0 Blockers)**

---

## Findings Summary

### 🟡 Major: Drop Speculative `ApiEndpoints.list(...)` Helper (YAGNI & Dissonance)
* **Affected Scope:** Lines 19, 29–30, 47, 55, 72
* **Discrepancy:** The document elevates `ApiEndpoints.list(endpoint, {includeInactive})` into the core Architecture Diagram and Goals. However:
  1. The core problem being resolved is exclusively IIS intercepting `PUT` and `DELETE` requests with 405 Method Not Allowed; `GET` requests never suffered from this.
  2. String concatenation (`$endpoint?includeInactive=...`) breaks when repositories compose multi-parameter queries (`search`, `status`, `page`).
  3. In Phase 2, zero repositories adopt `ApiEndpoints.list` because all repositories already construct query URIs cleanly using Dart's native `Uri(path: ..., queryParameters: ...)`.
* **Proposed Action:** Drop `ApiEndpoints.list` completely. Keep `ApiEndpoints` focused on `update` and `delete` route builders.

---

### 🟢 Nit: Remove Ghost Scope (`ChangePasswordRequest`)
* **Affected Scope:** Line 30, Line 100
* **Discrepancy:** `user_repository.dart` already implements the Swagger `ChangePasswordRequest` payload (`currentPassword`, `newPassword`).
* **Proposed Action:** Mark this item as already complete to prevent confusion during implementation.

---

### 🟢 Nit: Use Exact Method Signatures in `ProductionRepository`
* **Affected Scope:** Lines 137–142
* **Discrepancy:** `ProductionRepository` methods should match exact codebase identifiers (`updateStatus`, `deleteProductionOrder`, `deleteProductionStage`, `deleteProductionStageEntry`, `deleteProductionMaterialIssue`, `deleteProductionOutput`).
* **Proposed Action:** Update the table rows with exact method names.

---

### 🟢 Nit: Purge Dead 405 Fallback Caches
* **Affected Scope:** Section 3, Phase 2
* **Discrepancy:** Repositories like `BomRepository` and `PurchaseRepository` contain legacy `if (response.statusCode == 405)` fallback blocks designed to mask IIS WebDAV errors.
* **Proposed Action:** Instruct implementers to prune these obsolete fallback branches when refactoring to `POST /update/{id}` and `POST /delete/{id}`.
