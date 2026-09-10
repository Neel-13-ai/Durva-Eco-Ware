## Summary

Comprehensive API integration status for all 12 features of Durva Eco Ware, verified against the live server at **https://api-dev.durvaecoware.com** using superadmin credentials (`superadmin` / `123456`).

This issue tracks **app-side integration status only** — what endpoints the app declares, what is wired in repositories, what works live, and what needs wiring. Server-side issues (missing endpoints, POST bugs) are noted for awareness but are infrastructure concerns outside the app's scope.

Full detailed report attached: **API_INTEGRATION_VERIFICATION_REPORT.md**

---

## Quick Stats

| Metric | Count |
|---|---|
| Server operations (Swagger) | 202 across 82 paths |
| App endpoint constants declared | 50 |
| App endpoints wired in repos (actual usage) | 33 |
| GET collections live-verified | 40 / 40 (100% HTTP 200) |
| Login (POST) | Working — returns valid JWT |

---

## Per-Feature Integration Status

### #01 Auth — 9 endpoints declared, 1 wired (login)
- **Works**: POST /api/auth/login → JWT. GET app-settings, company-settings, roles all return data.
- **Not wired**: /api/auth/me (used for session restore — app calls it but it's declared, not wired in a dedicated repo method), /api/auth/refresh, /api/auth/logout, app-settings CRUD, company-settings CRUD, roles CRUD.
- **App issue**: Access token not persisted to SecureStorage (#13).

### #02 Master Data — 10 declared, 8 wired (4 list + 4 detail)
- **Works**: categories (7 items), units (9 items), warehouses (1 item), document-sequences (9 items). Products empty (no seed data).
- **Not wired**: document-sequences CRUD, document-sequences/{id}.
- **Server note**: POST creates return 400 IsActive conflict (server-side, blocks all creates across all entities).

### #03 Partners — 9 declared, 8 wired (4 list + 4 detail)
- **Works**: payment-methods (6 items). Suppliers/customers/transporters/vehicles empty.
- **Not wired**: payment-methods CRUD, payment-methods/{id}.

### #04 Purchasing — 10 declared, 2 wired (purchases list + header CRUD)
- **Works**: All 5 collections return HTTP 200 (empty).
- **Not wired**: purchase-details CRUD, goods-receipts CRUD, goods-receipt-details CRUD, vendor-payments CRUD — 4 complete endpoint groups with NO data layer. Missing repos: purchase_details_repository, goods_receipt_details_repository, vendor_payment_repository.

### #05 Inventory — 6 declared, 3 wired
- **Works**: All 3 collections return HTTP 200 (empty).
- **Not wired**: stock-balances/{id}, stock-transactions/{id}, audit-logs CRUD, audit-logs/{id}.

### #06 BOM — 4 declared, 0 wired
- **Works**: Both collections return HTTP 200 (empty).
- **Not wired**: ENTIRE feature — no repository wires bomHeaders or bomDetails. BOM screens exist in router but have no data layer. Missing: bom_repository.dart, bom_details_repository.dart.

### #07 Production — 10 declared, 2 wired
- **Works**: production-stages (6 items returned). All others empty.
- **Not wired**: production-stages CRUD, production-stage-entries full CRUD (partially wired via updateStageEntry), production-material-issues, production-outputs, quality-checks. Missing: dedicated repos for material-issues and outputs.

### #08 Waste — 4 declared, 0 wired
- **Works**: waste-reasons (7 items returned). waste-entries empty.
- **Not wired**: ENTIRE feature — no repository wires wasteReasons or wasteEntries. Missing: waste_repository.dart, waste_entries_repository.dart.

### #09 Sales — 6 declared, 3 wired
- **Works**: All 3 collections return HTTP 200 (empty).
- **Not wired**: sale-details CRUD, customer-payments CRUD. Missing: sale_details_repository.dart, customer_payment_repository.dart.

### #10 Dispatch — 4 declared, 3 wired — BEST COVERAGE
- **Works**: Both collections return HTTP 200 (empty).
- **Wired**: deliveries full CRUD (create, getById, update, delete).
- **Not wired**: delivery-details CRUD, delivery-details/{id}. Missing: delivery_details_repository.dart.

### #11 Expenses — 4 declared, 3 wired — SECOND BEST
- **Works**: expense-categories (9 items). expenses empty.
- **Wired**: expenses getById, updateExpense, deleteExpense. expense-categories updateCategory.
- **Not wired**: expense-categories/{id} GET/PUT/DELETE, expense-categories create/delete.

### #12 Dashboard — 7 declared, 1 wired
- **Works**: notifications (empty).
- **Server missing (404)**: /api/dashboard/summary, /api/reports/stock-summary, /api/reports/production-summary, /api/reports/sales-summary, /api/reports/waste-summary — these do not exist on the server.
- **Not wired**: notifications list GET, notifications/{id}, notifications POST. Missing: reports_repository.dart.

---

## App-Side Issues Already Created

| # | Title | Label |
|---|---|---|
| #13 | Auth Token Persistence Bug — Access Token Not Stored in SecureStorage | general |
| #14 | Feature #10 Dispatch — Missing Quantity Validation on Delivery Form | general |
| #15 | Test Coverage Gap — Missing Widget & Integration Tests Across All 12 Epics | general |

---

## Out of Scope (Server-Side — Not App Issues)

These are noted for awareness but are infrastructure concerns, not app integration tickets:

1. **POST IsActive column conflict** — All POST creates across all entities return 400. Server-side column mapping bug. Blocks all create forms in the app until fixed on the server.
2. **GET /api/auth/me 404** — Endpoint doesn't exist on server. Session restore path broken at server level.
3. **POST /api/auth/refresh 404** — Endpoint doesn't exist on server. Token refresh not possible.
4. **POST /api/auth/logout 411** — Server requires Content-Length. Minor client behavior issue.
5. **5 report/dashboard endpoints 404** — /api/dashboard/summary and all 4 /api/reports/* endpoints don't exist on server. Reports hub and dashboard KPIs cannot work until server adds them.

---

## Recommended Work Order (App Side)

1. **Fix #13** — Persist access token to SecureStorage (session_manager.dart)
2. **Fix #14** — Add quantity validation to delivery_form_controller.dart
3. **Wire missing repositories** (in priority order):
   - High: purchase_details, goods_receipts, goods_receipt_details, vendor_payments (#04)
   - High: bom_repository + bom_details_repository (#06)
   - High: waste_repository + waste_entries_repository (#08)
   - High: sale_details + customer_payment (#09)
   - High: delivery_details (#10)
   - Medium: document-sequences, payment-methods, stock-balances/{id}, stock-transactions/{id}, audit-logs, production-stages, production-stage-entries, production-material-issues, production-outputs, quality-checks, expense-categories/{id}, notifications CRUD (#02, #03, #05, #07, #11, #12)
4. **Fix #15** — Add widget + integration tests per epic DoD

---

*Report generated by Hermes Agent (Neel's personal AI assistant) — verified via live curl probes + Dart test runners against https://api-dev.durvaecoware.com with superadmin credentials on 2026-09-10.*

