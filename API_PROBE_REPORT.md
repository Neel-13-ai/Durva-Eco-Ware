# Durva Eco Ware — Live API Probe Report

**Date:** 2026-09-11
**Target:** `https://api-dev.durvaecoware.com`
**Tested by:** Hermes Agent
**Probe files:**
- `test/live_post_create_probe.dart` (this run — 30 POST endpoints)
- `test/live_82_routes_probe.dart` (existing — 41 GET collection endpoints, 100% pass)
- `test/live_api_probe.dart` (existing — 34 GET endpoints)
- `test/dump_swagger.dart` (existing — dumps full Swagger schema)

---

## Summary

| Metric | Count |
|---|---|
| POST create endpoints tested | 30 |
| Passed (HTTP 200/201/204) | **1** |
| Rejected (HTTP 400) | **25** |
| Not Found (HTTP 404) | **4** |
| GET endpoints previously tested | 41 (all pass) |

**Only `POST /api/production-stages` succeeded.** The other 29 fail for four distinct reasons — see below.

---

## Category A — App Sends Forbidden Fields (9 fixes needed in `toJson()`)

The app's DTO `toJson()` methods emit fields the API rejects on create. These are real code bugs.

| # | Endpoint | HTTP | API Error Message | DTO / File | Line |
|---|---|---|---|---|---|
| 1 | POST /api/categories | 400 | `Field 'name' is not allowed for Categories.` | `CategoryDto` → `masters/data/models/category_dto.dart` | 71 |
| 2 | POST /api/units | 400 | `Field 'name' is not allowed for Units.` | `UnitDto` → `masters/data/models/unit_dto.dart` | 31 |
| 3 | POST /api/warehouses | 400 | `Field 'name' is not allowed for Warehouses.` | `WarehouseDto` → `masters/data/models/warehouse_dto.dart` | 43 |
| 4 | POST /api/document-sequences | 400 | `Field 'moduleName' is not allowed for DocumentSequences.` | `DocumentSequenceDto` → `masters/data/models/document_sequence_dto.dart` | 43 |
| 5 | POST /api/products | 400 | `The column name 'IsActive' is specified more than once in the SET clause or column list of an INSERT.` | `ProductDto` → `masters/data/models/product_dto.dart` | 115 (`toApiJson()`) |
| 6 | POST /api/purchases | 400 | `Field 'items' is not allowed for Purchases.` | `PurchaseDto` → `purchasing/data/models/purchase_dto.dart` | 141 |
| 7 | POST /api/goods-receipts | 400 | `Field 'items' is not allowed for GoodsReceipts.` | `GoodsReceiptDto` → `purchasing/data/models/goods_receipt_dto.dart` | 128 |
| 8 | POST /api/sales | 400 | `Field 'items' is not allowed for Sales.` | `SaleDto` → `sales/data/models/sale_dto.dart` | 160 |
| 9 | POST /api/quality-checks | 400 | `Field 'checkDate' is not allowed for QualityChecks.` | `QualityCheckDto` → `production/data/models/quality_check_dto.dart` | 103 |
| 10 | POST /api/production-stage-entries | 400 | `Field 'sequenceNo' is not allowed for ProductionStageEntries.` | `ProductionStageEntryDto` → `production/data/models/production_stage_entry_dto.dart` | 86 |

### Required fixes (Category A)

For each DTO above, the `toJson()` method must not emit the rejected field when creating a new record. Options:

- **Remove the field entirely** if the server generates it or derives it (e.g. `checkDate`, `sequenceNo`, `name` on master records that are auto-named).
- **Use a separate create-specific serialization** (follow the `ProductDto.toApiJson()` pattern already in the codebase) that omits server-managed fields.
- **Rename the field** if the API expects a different name (e.g. `moduleName` → whatever the API expects for `DocumentSequenceDto`).

---

## Category B — Foreign Key Violations (5 — test data / ordering issue)

These fail because parent records with `id: 1` don't exist in the dev database. Not a code bug, but the app's create flow must create parents before children and use the real returned IDs.

| # | Endpoint | HTTP | API Error | Parent Required |
|---|---|---|---|---|
| 11 | POST /api/purchase-details | 400 | `FK constraint FK__PurchaseD__Produ__1F63A897` — Product not found | Product (id=1) |
| 12 | POST /api/production-material-issues | 400 | `FK constraint FK__Productio__Produ__12FDD1B2` — ProductionOrder not found | ProductionOrder |
| 13 | POST /api/production-outputs | 400 | `FK constraint FK__Productio__Produ__18B6AB08` — ProductionOrder not found | ProductionOrder |
| 14 | POST /api/sale-details | 400 | `FK constraint FK__SaleDetai__Produ__2704CA5F` — Product not found | Product (id=1) |
| 15 | POST /api/delivery-details | 400 | `Cannot insert NULL into column 'SaleDetailId'` — no SaleDetail exists | Sale + SaleDetail |

### Required action (Category B)

- The probe sent hardcoded `id: 1` for parent references. In production flows the app must create the parent record first, read the returned `id`, then create children.
- Test runs should seed required parent records (products, sales, production orders) before testing child creation.

---

## Category C — Missing Required Audit Fields (5 — app or API gap)

The API requires `CreatedBy` or `UserId` on these endpoints, but the app's DTOs don't send them. Neither the app nor the API currently handles this.

| # | Endpoint | HTTP | API Error | Missing Field |
|---|---|---|---|---|
| 16 | POST /api/vendor-payments | 400 | `Cannot insert NULL into column 'CreatedBy', table dbo.VendorPayments` | `createdBy` |
| 17 | POST /api/stock-transactions | 400 | `Cannot insert NULL into column 'UserId', table dbo.StockTransactions` | `userId` |
| 18 | POST /api/waste-entries | 400 | `Cannot insert NULL into column 'CreatedBy', table dbo.WasteEntries` | `createdBy` |
| 19 | POST /api/expenses | 400 | `Cannot insert NULL into column 'CreatedBy', table dbo.Expenses` | `createdBy` |
| 20 | POST /api/deliveries | 400 | `Cannot insert NULL into column 'CreatedBy', table dbo.Deliveries` | `createdBy` |

### Required action (Category C)

Decide who supplies the value:

- **Option 1 (preferred):** API reads the user identity from the JWT bearer token and populates these columns server-side. This requires an API change.
- **Option 2:** App sends the current user's ID in the payload. This requires the `AuthenticatedApiClient` / `SessionManager` to expose the user id, and each repository to include it.

---

## Category D — Wrong Path / 404 (4 — verify against Swagger)

These returned 404. Some are probe path typos; others may be genuinely missing endpoints.

| # | Endpoint Probed | HTTP | Note | Likely Correct Path / Status |
|---|---|---|---|---|
| 21 | POST /api/stock-adjustments | 404 | App's `InventoryRepository.adjustStock()` POSTs to `/api/stock-transactions` with `transactionType: ADJUSTMENT` — no separate `/api/stock-adjustments` endpoint exists in the app code | Remove from probe; app already uses correct path |
| 22 | POST /api/bom-headers | 404 | `ApiEndpoints.bomHeaders` is `/api/b-o-m-headers` (with hyphens). Probe used `/api/bom-headers` (no hyphens) — path typo in probe | Re-test with `/api/b-o-m-headers` |
| 23 | POST /api/bom-details | 404 | Same — `ApiEndpoints.bomDetails` is `/api/b-o-m-details` | Re-test with `/api/b-o-m-details` |
| 24 | POST /api/auth/refresh | 404 | Refresh token endpoint path may differ (e.g. `/api/auth/refresh-token`). `AuthenticatedApiClient` handles refresh internally — no app repository calls this directly | Verify actual refresh path in Swagger or `SessionManager` |

---

## Category E — Latent `id` Leak on Create (did not trigger in probe, but present in code)

The probe sent payloads without `id`. But the app's own `toJson()` methods **will** emit `id` when controllers construct new records. This is the exact bug pattern that caused the original `"Field 'id' is not allowed for ProductionOrders"` error.

### Unconditional `id` emission — will fail on create (8 DTOs)

These `toJson()` methods always emit `'id': id`, even when `id` is 0 (new record):

| DTO | File |
|---|---|
| `ProductionOrderDto` | `production/data/models/production_order_dto.dart` |
| `PurchaseDto` | `purchasing/data/models/purchase_dto.dart` |
| `GoodsReceiptDto` | `purchasing/data/models/goods_receipt_dto.dart` |
| `WasteEntryDto` | `waste/data/models/waste_entry_dto.dart` |
| `StockTransactionDto` | `inventory/data/models/stock_transaction_dto.dart` |
| `ProductionMaterialIssueDto` | `production/data/models/production_material_issue_dto.dart` |
| `ProductionOutputDto` | `production/data/models/production_output_dto.dart` |
| `QualityCheckDto` | `production/data/models/quality_check_dto.dart` |

### Conditional `id` emission — safer but still risky (7 DTOs)

These guard with `if (id != 0)`, so they won't leak `id` for brand-new records constructed with `id: 0`. Risk remains if a DTO is reused from a previous API response (which has a real `id`) and sent back on a create:

| DTO | File |
|---|---|
| `SaleDto` | `sales/data/models/sale_dto.dart` |
| `DeliveryDto` | `dispatch/data/models/delivery_dto.dart` |
| `ExpenseDto` | `expenses/data/models/expense_dto.dart` |
| `CustomerPaymentDto` | `sales/data/models/customer_payment_dto.dart` |
| `SaleDetailDto` | `sales/data/models/sale_dto.dart` |
| `DeliveryDetailDto` | `dispatch/data/models/delivery_dto.dart` |
| `ExpenseCategoryDto` | `expenses/data/models/expense_category_dto.dart` |

### Recommended fix

For every create-capable DTO, either:

1. **Guard unconditionally:** change `'id': id` → `if (id != 0) 'id': id` (quick fix, handles the common case).
2. **Split serializations:** add a `toCreateJson()` (or rename the existing one like `ProductDto.toApiJson()`) that omits server-generated fields (`id`, `createdAt`, `createdBy`, etc.). Repositories' `create()` methods call `toCreateJson()` instead of `toJson()`.

---

## Test Artifacts

### Files written

- `test/live_post_create_probe.dart` — the probe that produced these results. Re-run after fixes to verify.

### Existing probe files (read-only references)

- `test/live_82_routes_probe.dart` — GET-only, all 41 pass
- `test/live_api_probe.dart` — GET-only, 34 endpoints
- `test/dump_swagger.dart` — dumps full Swagger JSON path list

---

## Re-Testing Procedure

After applying Category A and Category E fixes:

1. Run `dart run test/live_post_create_probe.dart` from the `durvaeco/` directory.
2. Expected: more endpoints move from ⚠️/❌ to ✅.
3. For Category B (FK) endpoints, the probe needs to be reordered — create parent first, capture the returned id, then create the child. This requires a stateful probe or an integration test that chains calls.
4. For Category C (audit fields), either fix the API to populate from JWT, or update the app to send the current user id.
5. For Category D, re-run the 404 items with corrected paths.

---

## API Endpoints Reference (from `lib/core/constants/api_endpoints.dart`)

```
GET  /api/auth/login, /api/auth/refresh, /api/auth/logout, /api/auth/me
GET  /api/app-settings, /api/company-settings, /api/roles
GET  /api/categories, /api/units, /api/products, /api/warehouses, /api/document-sequences
GET  /api/suppliers, /api/customers, /api/transporters, /api/vehicles, /api/payment-methods
GET  /api/purchases, /api/purchase-details, /api/goods-receipts, /api/goods-receipt-details, /api/vendor-payments
GET  /api/stock-balances, /api/stock-transactions, /api/stock-adjustments, /api/audit-logs
GET  /api/b-o-m-headers, /api/b-o-m-details
GET  /api/production-orders, /api/production-stages, /api/production-stage-entries, /api/production-material-issues, /api/production-outputs, /api/quality-checks
GET  /api/waste-reasons, /api/waste-entries
GET  /api/sales, /api/sale-details, /api/customer-payments
GET  /api/deliveries, /api/delivery-details
GET  /api/expense-categories, /api/expenses
GET  /api/notifications, /api/dashboard/summary
GET  /api/reports/stock-summary, /api/reports/production-summary, /api/reports/sales-summary, /api/reports/waste-summary

POST (create) — tested in this probe:
  /api/categories, /api/units, /api/warehouses, /api/document-sequences, /api/products
  /api/purchases, /api/purchase-details, /api/goods-receipts, /api/goods-receipt-details, /api/vendor-payments
  /api/stock-transactions, /api/stock-adjustments (404 — verify)
  /api/b-o-m-headers, /api/b-o-m-details (404 in probe — path typo suspected)
  /api/production-orders, /api/production-stages, /api/production-stage-entries, /api/production-material-issues, /api/production-outputs, /api/quality-checks
  /api/waste-reasons, /api/waste-entries
  /api/sales, /api/sale-details, /api/customer-payments
  /api/deliveries, /api/delivery-details
  /api/expense-categories, /api/expenses
  /api/auth/refresh (404 — verify path)
```
