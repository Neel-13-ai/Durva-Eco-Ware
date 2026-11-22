# Stage 6 Review Report: Comprehension Test

**Target:** `docs/designs/api_routes_standardization_plan.md` (Lines 1–175)  
**Reviewer:** `egm-comprehension` (Naive Reader)  
**Date:** 2026-11-22  

---

## Paraphrase

### What this proposes
The document proposes standardizing the Flutter mobile client's HTTP communication to match the backend ASP.NET Core API routes hosted on Windows IIS, which replaces all HTTP `PUT` and `DELETE` operations with `POST /api/{resource}/update/{id}` and `POST /api/{resource}/delete/{id}`. It strips runtime regex URL and verb rewrites out of `ApiClient.invokeAPI` to restore it as a pure HTTP transport client, centralizes route generation using helper methods (`update`, `delete`, `list`) in `ApiEndpoints`, and refactors 27 data repositories to explicitly invoke these `POST` endpoints.

### How the existing system works, per this document
Currently, the Windows IIS backend blocks standard `PUT` and `DELETE` requests via its default WebDAV configuration, returning `405 Method Not Allowed`. To accommodate this, `ApiClient.invokeAPI` contains an automatic regex rewrite mechanism that intercepts outgoing `PUT`, `PATCH`, and `DELETE` requests at runtime and dynamically mutates their URLs to `/update/{id}` or `/delete/{id}` while switching the HTTP verb to `POST`. Repositories currently issue legacy `PUT` and `DELETE` requests under the assumption that the lower-level transport client will silently rewrite them.

---

## Audit Findings

### 1. 🔴 Blocker: Missing Precondition Step & File Count Discrepancy for `ApiEndpoints`
* **Affected Scope:** Line 68–73 (Section 2.1), Line 81 (Section 3), and Lines 83–162 (Phases 1 & 2)
* **Discrepancy:** Line 81 states: *"The implementation modifies exactly 28 files across the workspace."* Phase 1 specifies 1 file (`api_client.dart`) and Phase 2 lists 27 repository files, totaling 28 files. However, `ApiEndpoints` (`lib/core/constants/api_endpoints.dart`) is Component 1. It is neither included in the file count (which should be 29 files) nor listed as an execution phase. A developer executing Phase 1 and moving to Phase 2 cannot compile repository updates without first updating `ApiEndpoints`.
* **Proposed Action:** Formally add Phase 0: Update `ApiEndpoints.dart` as a prerequisite step, and update the file count to 29 files.

### 2. 🔴 Blocker: Undefined Endpoint Specification for `changePassword`
* **Affected Scope:** Lines 98–100 (Phase 2, Row 2: `user_repository.dart`) and Line 30 (Goal 4)
* **Discrepancy:** In Phase 2, Row 2 for `changePassword`, the table column "Endpoint Helper Call" states `Payload: {'currentPassword': ..., 'newPassword': ...}` instead of providing the target route or `ApiEndpoints` constant (`ApiEndpoints.changePassword`).
* **Proposed Action:** Explicitly state the route constant `ApiEndpoints.changePassword` (`POST /api/users/change-password`) and clarify that the payload conforms to the Swagger `ChangePasswordRequest` DTO structure.

### 3. 🟡 Major: Unimplemented Scope for `includeInactive` Listing Parameters
* **Affected Scope:** Line 19, Line 30, Line 72, and Lines 88–162 (Phase 2)
* **Discrepancy:** The document lists `includeInactive` as a key backend change and design goal, but Phase 2 contains exclusively update and delete methods. It does not clarify whether listing methods are in scope or already supported.
* **Proposed Action:** Clarify in the plan that 25 repositories already have `includeInactive` implemented, and list the exact 2 repositories (`goods_receipt_repository.dart` and `vendor_payment_repository.dart`) that require updating.

### 4. 🟡 Major: Ambiguous Verification Procedure for Swagger Endpoints
* **Affected Scope:** Line 165 (Section 3, Phase 3, Step 2)
* **Discrepancy:** Phase 3 Step 2 states: *"Verify all 41 Swagger controller endpoints match the generated repository URLs"* without specifying a test command, script, or checklist.
* **Proposed Action:** Specify the automated test command or script (e.g. `test/verify_all_modules_integration.dart` or an automated route assertion script) that verifies endpoint resolution.

### 5. 🟢 Nit: Undefined System Component `AuthenticatedApiClient`
* **Affected Scope:** Lines 59–65 (Section 2 Architecture Diagram)
* **Discrepancy:** The diagram references `AuthenticatedApiClient` without explaining that it inherits from `ApiClient` to inject Bearer tokens.
* **Proposed Action:** Add a one-line clarification in Section 2 defining `AuthenticatedApiClient` as the authenticated child wrapper of `ApiClient`.
