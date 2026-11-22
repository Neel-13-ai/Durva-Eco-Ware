# Technical Design Document: Swagger API Route Synchronization & Explicit HTTP Architecture

* **Author:** Neel-13-ai
* **Date:** 2026-11-22
* **Target System:** Durva Eco Ware Flutter Mobile Client (`c:\workspace\durvaeco`)
* **Reference API Spec:** [Swagger Specification](https://api-dev.durvaecoware.com/swagger/v1/swagger.json)
* **Status:** Approved for Implementation (All EGM Goldfish Review Stages Passed)

---

## 1. Overview & Problem Statement

### 1.1 The Problem
The dev backend for Durva Eco Ware (`api-dev.durvaecoware.com`) is hosted on Windows IIS. Because default IIS configurations intercept HTTP `PUT` and `DELETE` requests via the WebDAV Publishing module and return `405 Method Not Allowed`, the backend developers restructured the ASP.NET Core API routes to avoid `PUT` and `DELETE`.

The backend exposes 162 routes across 41 controllers where:
1. All updates use `POST /api/{resource}/update/{id}` with a JSON body.
2. All deletions use `POST /api/{resource}/delete/{id}` without a body.
3. All resource listings accept an optional query parameter `?includeInactive={true|false}`.

Previously, `ApiClient.invokeAPI` employed runtime regex-based URL and HTTP verb rewrites. This design caused diagnostic and operational issues:
* **Diagnostic Masking:** Transport code mutates URL paths and HTTP verbs at runtime, causing network traces, proxy logs, and debugging breakpoints to diverge from repository call sites.
* **Violation of Separation of Concerns:** A low-level HTTP transport client should manage headers, tokens, timeouts, and transport, rather than business routing conventions.
* **Risk of Unintended Mutation:** Masks repository-level implementation bugs and risks unintended mutations if non-standard endpoints are invoked.

### 1.2 Core Goals
1. **Explicit Repositories:** Refactor all 27 repository implementations to explicitly call `ApiEndpoints.update(...)` and `ApiEndpoints.delete(...)` using HTTP `POST`.
2. **Decoupled `ApiClient`:** Remove regex URL and verb rewriting logic from `ApiClient.invokeAPI` so that it handles standard HTTP transport without path or method mutations.
3. **Single Source of Truth (`ApiEndpoints`):** Centralize route construction with generic helpers (`update`, `delete`) with URI component encoding.
4. **Transport Safety & Security:** Restrict `NativeHttpClient` socket retries strictly to idempotent HTTP methods, and gate `badCertificateCallback` behind `kDebugMode`.
5. **Zero Functional Regressions:** Ensure all unit/integration tests pass and static analysis (`flutter analyze lib`) reports zero issues.

### 1.3 Non-Goals
* Modifying remote server IIS configurations.
* Refactoring unrelated UI state management.

---

## 2. Architecture & Component Design

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. ApiEndpoints (Route Contract & Helper Builders)          │
│    • Base: static const String products = '/api/products'   │
│    • update(endpoint, id) => '$endpoint/update/${encodedId}'│
│    • delete(endpoint, id) => '$endpoint/delete/${encodedId}'│
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Repositories (Explicit & Observable)                     │
│    • _client.invokeAPI(ApiEndpoints.update(...), 'POST', ..)│
│    • _client.invokeAPI(ApiEndpoints.delete(...), 'POST', ..)│
│    • Native Uri(path: ..., queryParameters: ...) for lists  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3a. ApiClient (Base Transport Layer)                        │
│     • Pure HTTP transport, timeouts, cert policy            │
│ 3b. AuthenticatedApiClient (Session Middleware)             │
│     • Injects Authorization: Bearer <token> & device headers│
│     • Synchronized 401 token refresh queue                  │
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Component 1: ApiEndpoints (`lib/core/constants/api_endpoints.dart`)
Provides standard route strings and centralized helper methods with component encoding:
* `static String update(String endpoint, Object id) => '$endpoint/update/${Uri.encodeComponent(id.toString())}';`
* `static String delete(String endpoint, Object id) => '$endpoint/delete/${Uri.encodeComponent(id.toString())}';`

### 2.2 Component 2: Repositories (`lib/features/*/data/repositories/*.dart`)
Repositories explicitly specify the target URL and HTTP verb (`POST`) when updating or deleting entities. Listing queries use Dart's native `Uri(path: ..., queryParameters: ...)`.

### 2.3 Component 3: Transport Layer (`lib/infrastructure/api/api_client.dart` & `authenticated_api_client.dart`)
* **`ApiClient`**: Decoupled transport engine. Omits `Content-Type` on `body == null` requests. In release builds, enforces standard TLS verification (gating certificate bypass behind `kDebugMode`). Socket retries are restricted to idempotent methods (`GET`, `HEAD`, `OPTIONS`).
* **`AuthenticatedApiClient`**: Subclasses `ApiClient` to attach Bearer tokens, device metadata headers, and handle automated 401 token refresh.

---

## 3. Detailed Implementation Plan (29 Files Total)

### Phase 0: Centralized Route Helpers (`lib/core/constants/api_endpoints.dart`)
* Add URI-encoded `update` and `delete` helper methods.
* Remove speculative `list` helper.

### Phase 1: Transport Client Hardening (`lib/infrastructure/api/api_client.dart`)
* Strip regex URL and HTTP verb mutation from `invokeAPI`.
* Inject `Content-Type: application/json` only when `body != null`.
* Gate `badCertificateCallback` behind `kDebugMode`.
* Restrict socket retries to idempotent methods.

### Phase 2: Repository Updates (Exhaustive Table of 27 Repositories)

| # | File Path | Method (Current Code) | Endpoint Helper Call | HTTP Verb |
|---|-----------|-----------------------|----------------------|-----------|
| 1 | `lib/features/auth/data/settings_repository.dart` | `updateAppSetting` | `ApiEndpoints.update(ApiEndpoints.appSettings, id)` | `POST` |
| | | `deleteAppSetting` | `ApiEndpoints.delete(ApiEndpoints.appSettings, id)` | `POST` |
| | | `updateCompanySetting` | `ApiEndpoints.update(ApiEndpoints.companySettings, id)` | `POST` |
| | | `deleteCompanySetting` | `ApiEndpoints.delete(ApiEndpoints.companySettings, id)` | `POST` |
| | | `updateRole` | `ApiEndpoints.update(ApiEndpoints.roles, id)` | `POST` |
| | | `deleteRole` | `ApiEndpoints.delete(ApiEndpoints.roles, id)` | `POST` |
| 2 | `lib/features/auth/data/user_repository.dart` | `updateUser` | `ApiEndpoints.update(ApiEndpoints.users, id)` | `POST` |
| | | `deleteUser` | `ApiEndpoints.delete(ApiEndpoints.users, id)` | `POST` |
| | | `changePassword` | `ApiEndpoints.changePassword` (Already compliant) | `POST` |
| 3 | `lib/features/dispatch/data/repositories/delivery_repository.dart` | `updateDelivery` | `ApiEndpoints.update(ApiEndpoints.deliveries, id)` | `POST` |
| | | `deleteDelivery` | `ApiEndpoints.delete(ApiEndpoints.deliveries, id)` | `POST` |
| 4 | `lib/features/expenses/data/repositories/expense_repository.dart` | `updateCategory` | `ApiEndpoints.update(ApiEndpoints.expenseCategories, id)` | `POST` |
| | | `deleteCategory` | `ApiEndpoints.delete(ApiEndpoints.expenseCategories, id)` | `POST` |
| | | `updateExpense` | `ApiEndpoints.update(ApiEndpoints.expenses, id)` | `POST` |
| | | `deleteExpense` | `ApiEndpoints.delete(ApiEndpoints.expenses, id)` | `POST` |
| 5 | `lib/features/inventory/data/repositories/audit_log_repository.dart` | `updateAuditLog` | `ApiEndpoints.update(ApiEndpoints.auditLogs, id)` | `POST` |
| | | `deleteAuditLog` | `ApiEndpoints.delete(ApiEndpoints.auditLogs, id)` | `POST` |
| 6 | `lib/features/inventory/data/repositories/inventory_repository.dart` | `updateStockBalance` | `ApiEndpoints.update(ApiEndpoints.stockBalances, id)` | `POST` |
| | | `deleteStockBalance` | `ApiEndpoints.delete(ApiEndpoints.stockBalances, id)` | `POST` |
| 7 | `lib/features/inventory/data/repositories/stock_transaction_repository.dart` | `updateStockTransaction` | `ApiEndpoints.update(ApiEndpoints.stockTransactions, id)` | `POST` |
| | | `deleteStockTransaction` | `ApiEndpoints.delete(ApiEndpoints.stockTransactions, id)` | `POST` |
| 8 | `lib/features/masters/data/repositories/category_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.categories, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.categories, id)` | `POST` |
| 9 | `lib/features/masters/data/repositories/product_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.products, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.products, id)` | `POST` |
| 10 | `lib/features/masters/data/repositories/sequence_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.documentSequences, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.documentSequences, id)` | `POST` |
| 11 | `lib/features/masters/data/repositories/unit_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.units, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.units, id)` | `POST` |
| 12 | `lib/features/masters/data/repositories/warehouse_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.warehouses, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.warehouses, id)` | `POST` |
| 13 | `lib/features/notifications/data/repositories/notification_repository.dart` | `markAsRead` | `ApiEndpoints.update(ApiEndpoints.notifications, id)` | `POST` |
| | | `deleteNotification` | `ApiEndpoints.delete(ApiEndpoints.notifications, id)` | `POST` |
| 14 | `lib/features/partners/data/repositories/customer_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.customers, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.customers, id)` | `POST` |
| 15 | `lib/features/partners/data/repositories/payment_method_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.paymentMethods, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.paymentMethods, id)` | `POST` |
| 16 | `lib/features/partners/data/repositories/supplier_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.suppliers, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.suppliers, id)` | `POST` |
| 17 | `lib/features/partners/data/repositories/transporter_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.transporters, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.transporters, id)` | `POST` |
| 18 | `lib/features/partners/data/repositories/vehicle_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.vehicles, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.vehicles, id)` | `POST` |
| 19 | `lib/features/production/bom/data/repositories/bom_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.bomHeaders, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.bomHeaders, id)` | `POST` |
| 20 | `lib/features/production/data/repositories/production_repository.dart` | `updateStatus` | `ApiEndpoints.update(ApiEndpoints.productionOrders, id)` | `POST` |
| | | `updateStageEntry` | `ApiEndpoints.update(ApiEndpoints.productionStageEntries, entry.id)` | `POST` |
| | | `deleteProductionOrder` | `ApiEndpoints.delete(ApiEndpoints.productionOrders, id)` | `POST` |
| | | `deleteProductionStage` | `ApiEndpoints.delete(ApiEndpoints.productionStages, id)` | `POST` |
| | | `deleteProductionStageEntry` | `ApiEndpoints.delete(ApiEndpoints.productionStageEntries, id)` | `POST` |
| | | `deleteProductionMaterialIssue` | `ApiEndpoints.delete(ApiEndpoints.productionMaterialIssues, id)` | `POST` |
| | | `deleteProductionOutput` | `ApiEndpoints.delete(ApiEndpoints.productionOutputs, id)` | `POST` |
| 21 | `lib/features/production/data/repositories/quality_check_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.qualityChecks, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.qualityChecks, id)` | `POST` |
| 22 | `lib/features/purchasing/data/repositories/goods_receipt_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.goodsReceipts, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.goodsReceipts, id)` | `POST` |
| | | `updateDetail` | `ApiEndpoints.update(ApiEndpoints.goodsReceiptDetails, detailId)` | `POST` |
| | | `deleteDetail` | `ApiEndpoints.delete(ApiEndpoints.goodsReceiptDetails, detailId)` | `POST` |
| 23 | `lib/features/purchasing/data/repositories/purchase_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.purchases, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.purchases, id)` | `POST` |
| | | `deletePurchaseDetail` | `ApiEndpoints.delete(ApiEndpoints.purchaseDetails, detailId)` | `POST` |
| 24 | `lib/features/purchasing/data/repositories/vendor_payment_repository.dart` | `update` | `ApiEndpoints.update(ApiEndpoints.vendorPayments, id)` | `POST` |
| | | `delete` | `ApiEndpoints.delete(ApiEndpoints.vendorPayments, id)` | `POST` |
| 25 | `lib/features/sales/data/repositories/customer_payment_repository.dart` | `updateCustomerPayment` | `ApiEndpoints.update(ApiEndpoints.customerPayments, id)` | `POST` |
| | | `deleteCustomerPayment` | `ApiEndpoints.delete(ApiEndpoints.customerPayments, id)` | `POST` |
| 26 | `lib/features/sales/data/repositories/sales_repository.dart` | `updateSale` | `ApiEndpoints.update(ApiEndpoints.sales, id)` | `POST` |
| | | `deleteSale` | `ApiEndpoints.delete(ApiEndpoints.sales, id)` | `POST` |
| 27 | `lib/features/waste/data/repositories/waste_repository.dart` | `updateReason` | `ApiEndpoints.update(ApiEndpoints.wasteReasons, id)` | `POST` |
| | | `deleteReason` | `ApiEndpoints.delete(ApiEndpoints.wasteReasons, id)` | `POST` |
| | | `updateEntry` | `ApiEndpoints.update(ApiEndpoints.wasteEntries, id)` | `POST` |
| | | `deleteEntry` | `ApiEndpoints.delete(ApiEndpoints.wasteEntries, id)` | `POST` |

### Phase 3: Verification & Validation
1. Execute `flutter analyze lib` to verify 0 compile-time errors and type safety.
2. Verify all endpoint routes resolve cleanly with no lingering `PUT` or `DELETE` invocations.
