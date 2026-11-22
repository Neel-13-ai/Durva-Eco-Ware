# Stage 9 Review Report: Implementation Readiness & Codebase Details

**Target:** `docs/designs/api_routes_standardization_plan.md` (DetailedRange: Lines 79–175)  
**Reviewers:** `egm-implementation-readiness` (Implementation Lead), `egm-codebase-details` (Codebase Auditor)  
**Date:** 2026-11-22  

---

## Prioritized Findings

### 🔴 Blocker: Omission of Sub-Resource Update `updateStageEntry` in `ProductionRepository`
* **Reviewers:** `egm-codebase-details`, `egm-implementation-readiness`
* **Affected Scope:** Lines 137–142 (`production_repository.dart`)
* **Discrepancy:** In `production_repository.dart` (lines 201–218), `updateStageEntry` issues:
  `entry.id > 0 ? 'PUT' : 'POST'` directly targeting `ApiEndpoints.productionStageEntries`.
  This was omitted from the plan table. Once `ApiClient` regex mutation is removed, calling `updateStageEntry` on existing entries will execute a raw HTTP `PUT`, triggering runtime 405 errors on IIS.
* **Proposed Edit:** Add `updateStageEntry` to Item 20, mapping to `ApiEndpoints.update(ApiEndpoints.productionStageEntries, entry.id)` with HTTP verb `POST`.

---

### 🔴 Blocker: Inaccurate Method Names in `NotificationRepository` (`markAsRead`)
* **Reviewers:** `egm-codebase-details`, `egm-implementation-readiness`
* **Affected Scope:** Lines 123–124 (`notification_repository.dart`)
* **Discrepancy:** The plan specifies `update` and `delete`. In reality, `NotificationRepository` contains **no generic `update` method**; the mutation is `markAsRead(int id)` (which issues `PUT`), and the delete method is `deleteNotification(int id)`.
* **Proposed Edit:** Correct table Item 13 to explicitly target `markAsRead` and `deleteNotification`.

---

### 🟡 Major: Widespread Method Name Drift in Repository Table (Singular vs Plural & Prefixes)
* **Reviewers:** `egm-codebase-details`, `egm-implementation-readiness`
* **Affected Scope:** Lines 90–162 (Phase 2 Table)
* **Discrepancy:** Several method names in the plan table do not match Dart identifiers in code:
  1. `settings_repository.dart`: `updateAppSetting` / `deleteAppSetting`, `updateCompanySetting` / `deleteCompanySetting` (singular, not plural).
  2. `user_repository.dart`: `updateUser` & `deleteUser` (not bare `update`/`delete`).
  3. `delivery_repository.dart`: `updateDelivery` & `deleteDelivery`.
  4. `audit_log_repository.dart`: `updateAuditLog` & `deleteAuditLog`.
  5. `stock_transaction_repository.dart`: `updateStockTransaction` & `deleteStockTransaction`.
  6. `production_repository.dart`: `updateStatus` (no generic `update`), `deleteProductionOrder`, `deleteProductionStage`, `deleteProductionStageEntry`, `deleteProductionMaterialIssue`, `deleteProductionOutput`.
  7. `customer_payment_repository.dart`: `updateCustomerPayment` & `deleteCustomerPayment`.
  8. `sales_repository.dart`: `updateSale` & `deleteSale`.
* **Proposed Edit:** Align table column entries with exact Dart identifiers to enable mechanical find-and-replace.

---

### 🟡 Major: Unspecified Handling of Fallback Retries and IIS 405 Mock Caches
* **Reviewers:** `egm-implementation-readiness`, `egm-codebase-details`
* **Affected Scope:** Line 137 (`production_repository.dart: updateStatus`) and repository fallback blocks
* **Discrepancy:** `updateStatus` currently contains a 3-step verb cascade fallback (`PUT /status` -> `PATCH` -> `PUT`). Additionally, 14 repositories have `if (response.statusCode == 405 || response.statusCode == 404)` cache-override fallbacks.
* **Proposed Edit:** Explicitly instruct collapsing `updateStatus` into a single `POST ApiEndpoints.update(...)` call, and specify that legacy 405 fallback branches should be cleaned up.

---

### 🟡 Major: Non-Actionable Verification Step
* **Reviewer:** `egm-implementation-readiness`
* **Affected Scope:** Line 165 (Phase 3 Step 2)
* **Discrepancy:** States *"Verify all 41 Swagger controller endpoints match the generated repository URLs"* without specifying an executable command or script.
* **Proposed Edit:** Specify a concrete test verification command (e.g. `flutter test test/all_screens_e2e_defect_scan_test.dart` or an automated route assertion script).
