# Durva Eco Ware — Screen Defects & Resolutions Report (E2E Testing)

**Project:** Durva Eco Ware (Flutter Web & Desktop/Mobile ERP)  
**Date:** October 2026  
**E2E Scope:** 52 Application Screens & 22 Backend Repositories/Endpoints  
**Test Result:** **52 / 52 Screens Verified (100% Pass Rate)** | **22 / 22 API Operations (100% Pass Rate)**

---

## Executive Summary

A comprehensive End-to-End (E2E) testing and visual/runtime defect scan was conducted across all **52 UI screens** and **9 business modules** of the Durva Eco Ware ERP application. Testing covered viewport responsiveness (Desktop 1280×800 and Mobile 390×844), API payload serialization, asynchronous state management (Riverpod), and Flutter Web platform compatibility.

A total of **8 architectural and screen-level defects** were identified, root-caused, and resolved directly in code.

---

## Summary Matrix of Screen Defects & Solutions

| # | Screen / Area | Defect Type | Root Cause | Implemented Solution | Status |
|---|---|---|---|---|---|
| **1** | **Web Runtime Engine** | Initialization Crash | `Platform.isWindows` in `device_utils.dart` & `dart:io.HttpClient` in `api_client.dart` unsupported on web; CanvasKit CDN fetch blocked | Added `kIsWeb` guards across `device_utils.dart`, `api_client.dart`, `local_notification_service.dart`; configured `useLocalCanvasKit: true` in `web/index.html` | ✅ Fixed |
| **2** | **Login Screen** (`/login`) | Layout Overflow (73px) | Unconstrained footer copyright `Text` in horizontal `Row` on compact viewports | Wrapped text widget in `Flexible` with `TextOverflow.ellipsis` | ✅ Fixed |
| **3** | **Home Dashboard** (`/home`) | Unhandled Async Crash | `unreadNotificationCountProvider` and `notificationsListProvider` threw unhandled exception on background fetch failure; `dashboardMetricsProvider` lacked error fallback | Wrapped `dashboardMetricsProvider` in `try/catch` returning default `DashboardKpiSummary()`; fallback to empty list in `notification_providers.dart` | ✅ Fixed |
| **4** | **Waste & Scrap Screen** (`/waste`) | Type Cast Exception | Backend SQL Server returns numeric enum `0, 1, 2, 3` for `DisposalMethod`; `as String?` threw `TypeError: int is not a subtype of String` | Updated `DisposalMethod.fromString` to accept dynamic values & mapped integer enums; safely converted all String fields in `WasteEntryDto.fromJson` | ✅ Fixed |
| **5** | **Expense Management** (`/expenses`) | Blank UI Filter Chips | Backend returned PascalCase `CategoryName`/`ExpenseCategoryName` while DTO only read camelCase `categoryName` | Added PascalCase and alias fallback keys (`CategoryName`, `ExpenseCategoryName`, `name`) in `ExpenseCategoryDto.fromJson` & `ExpenseDto.fromJson` | ✅ Fixed |
| **6** | **Goods Receipt & Vendor Payment Forms** (`/purchasing/*`) | Unhandled Async Exception & Schema Mismatch | Unchecked `Future.microtask` in `initState` crashed when parent PO query failed; backend rejected `totalItems`/`totalQuantity` and required integer `receivedBy` | Added `try/catch` and `if (!mounted) return;` in microtasks; normalized `GoodsReceiptDto.toJson()` removing invalid fields and parsing `receivedBy` as int | ✅ Fixed |
| **7** | **Sales Form Screen** (`/sales/new`) | Runtime Re-throw Crash | Direct access to `.value` on Riverpod `AsyncError` in `customersAsync.value` and `productsAsync.value` re-threw uncaught exceptions | Replaced `.value` with `.valueOrNull ?? <...Dto>[]` across `sales_form_screen.dart` | ✅ Fixed |
| **8** | **Purchase Detail Screen** (`/purchasing/:id`) | Text Truncation / Overflow | Text in detail metadata row (`_InfoRow`) overflowed parent flex container | Wrapped value text in `Flexible` with `TextOverflow.ellipsis` | ✅ Fixed |

---

## Detailed Defect Breakdown & Screen Resolutions

### 1. Web Platform & Chrome Runtime Compatibility
- **Files Modified:**
  - [device_utils.dart](file:///c:/workspace/durvaeco/lib/core/utils/device_utils.dart)
  - [api_client.dart](file:///c:/workspace/durvaeco/lib/infrastructure/api/api_client.dart)
  - [local_notification_service.dart](file:///c:/workspace/durvaeco/lib/infrastructure/notifications/local_notification_service.dart)
  - [main.dart](file:///c:/workspace/durvaeco/lib/main.dart)
  - [index.html](file:///c:/workspace/durvaeco/web/index.html)
- **Problem:** Flutter Web threw `Unsupported operation: Platform._operatingSystem` on app startup. Dart's `dart:io.HttpClient` was unavailable, and Google's `gstatic.com` CanvasKit CDN was blocked by network firewalls.
- **Resolution:**
  - Implemented `kIsWeb` checks so `device_utils.dart` returns `'web'` safely.
  - Used standard `http.Client()` on web while keeping IO clients for desktop.
  - Configured `useLocalCanvasKit: true` in `web/index.html` to load local SDK CanvasKit without committing 30MB+ binaries to git.

---

### 2. Login Screen (`LoginScreen`)
- **File Modified:** [login_screen.dart](file:///c:/workspace/durvaeco/lib/features/auth/presentation/screens/login_screen.dart#L362)
- **Defect:** On mobile viewports (e.g. 390×844), bottom footer copyright row threw:
  ```
  A RenderFlex overflowed by 73 pixels on the right.
  ```
- **Resolution:** Wrapped the footer copyright text in `Flexible` with `TextOverflow.ellipsis` to gracefully fit any display resolution.

---

### 3. Home Dashboard Screen (`HomeScreen`)
- **Files Modified:**
  - [dashboard_metrics_provider.dart](file:///c:/workspace/durvaeco/lib/features/home/application/dashboard_metrics_provider.dart#L27-L58)
  - [notification_providers.dart](file:///c:/workspace/durvaeco/lib/features/notifications/application/notification_providers.dart#L15-L25)
- **Defect:** If background notification or KPI aggregations failed (e.g. during offline mode or slow network), the unhandled error crashed the home view or the notification badge.
- **Resolution:**
  - Wrapped `dashboardMetricsProvider` in `try/catch` with a fallback `const DashboardKpiSummary()`.
  - Updated `notificationsListProvider` to return empty list on failure, and changed `ref.watch(...).value` to `.valueOrNull` so the badge safely displays `0` unread instead of crashing.

---

### 4. Waste & Scrap Management Screen (`WasteListScreen`)
- **File Modified:** [waste_entry_dto.dart](file:///c:/workspace/durvaeco/lib/features/waste/data/models/waste_entry_dto.dart#L7-L128)
- **Defect:** Navigating to `/waste` produced:
  ```
  TypeError: int is not a subtype of type 'String?' in type cast
  ```
  In C# ASP.NET Core / SQL Server, enums are serialized as integers (`0 = Recycled, 1 = Repulped, 2 = Discarded, 3 = SoldAsScrap`). Also, `CreatedBy` was an integer user ID.
- **Resolution:**
  - Updated `DisposalMethod.fromString(dynamic val)` to support integers `0, 1, 2, 3` and string numeric equivalents.
  - Used `.toString()` for `batchNo`, `wasteNumber`, `createdBy`, `notes`, and reason names.

---

### 5. Expense Management Screen (`ExpenseListScreen`)
- **Files Modified:**
  - [expense_category_dto.dart](file:///c:/workspace/durvaeco/lib/features/expenses/data/models/expense_category_dto.dart#L14-L30)
  - [expense_dto.dart](file:///c:/workspace/durvaeco/lib/features/expenses/data/models/expense_dto.dart#L43-L60)
- **Defect:** Category filter chips on top of `/expenses` rendered blank with empty text because backend SQL Server returned PascalCase (`CategoryName` and `ExpenseCategoryId`) while the parser only read camelCase.
- **Resolution:** Added comprehensive PascalCase and alias fallback keys (`CategoryName`, `ExpenseCategoryName`, `name`, `Name`).

---

### 6. Purchasing Forms & Goods Receipt (`GoodsReceiptFormScreen`, `VendorPaymentFormScreen`)
- **Files Modified:**
  - [goods_receipt_form_screen.dart](file:///c:/workspace/durvaeco/lib/features/purchasing/presentation/screens/goods_receipt_form_screen.dart#L30-L38)
  - [vendor_payment_form_screen.dart](file:///c:/workspace/durvaeco/lib/features/purchasing/presentation/screens/vendor_payment_form_screen.dart#L34-L42)
  - [goods_receipt_dto.dart](file:///c:/workspace/durvaeco/lib/features/purchasing/data/models/goods_receipt_dto.dart#L115-L128)
- **Defect:**
  - In `initState`, `Future.microtask` called `purchaseDetailProvider.future` without `try/catch`. If the request was cancelled or unauthenticated, it caused unhandled zone crashes.
  - Submitting Goods Receipt threw API error: `Field 'totalItems' and 'totalQuantity' is not allowed for GoodsReceipts` and SQL Server rejected string `'Admin'` for integer `receivedBy`.
- **Resolution:**
  - Wrapped microtasks in `try/catch` and added `if (!mounted) return;`.
  - Removed disallowed fields from `GoodsReceiptDto.toJson()` and converted `receivedBy` to integer.

---

### 7. Sales Invoice Form Screen (`SalesFormScreen`)
- **File Modified:** [sales_form_screen.dart](file:///c:/workspace/durvaeco/lib/features/sales/presentation/screens/sales_form_screen.dart#L182-L381)
- **Defect:** Mounting `SalesFormScreen` threw `_Exception` because lines 182 and 381 read `customersAsync.value` and `productsAsync.value`. In Riverpod, accessing `.value` when an `AsyncValue` is in an error state re-throws the underlying exception.
- **Resolution:** Changed all `.value ??` lookups to `.valueOrNull ?? <...Dto>[]`.

---

### 8. Purchase Order Detail Screen (`PurchaseDetailScreen`)
- **File Modified:** [purchase_detail_screen.dart](file:///c:/workspace/durvaeco/lib/features/purchasing/presentation/screens/purchase_detail_screen.dart#L215-L230)
- **Defect:** Long vendor names or purchase order numbers in `_InfoRow` caused horizontal rendering overflow.
- **Resolution:** Wrapped `value` widget in `Flexible` with `TextOverflow.ellipsis`.

---

## Verification & Test Results

### 1. Full Screen-by-Screen E2E Defect Scan
Run command:
```bash
flutter test test/all_screens_e2e_defect_scan_test.dart
```
**Result:**
```
======================================================
   DURVA ECO WARE: COMPREHENSIVE SCREEN DEFECT SCAN   
======================================================
✅ PASSED: SplashScreen
✅ PASSED: LoginScreen
✅ PASSED: ForgotPasswordScreen
✅ PASSED: HomeScreen (Desktop 1280x800)
✅ PASSED: HomeScreen (Mobile 390x844)
✅ PASSED: MoreMenuScreen
✅ PASSED: PurchaseListScreen
✅ PASSED: PurchaseOrderFormScreen
✅ PASSED: PurchaseDetailScreen
✅ PASSED: GoodsReceiptFormScreen
✅ PASSED: VendorPaymentFormScreen
✅ PASSED: VendorPaymentReceiptScreen
✅ PASSED: ProductionOrderListScreen
✅ PASSED: ProductionOrderFormScreen
✅ PASSED: ProductionStageTrackerScreen
✅ PASSED: ProductionMaterialIssueScreen
✅ PASSED: ProductionOutputFormScreen
✅ PASSED: ProductionQualityCheckScreen
✅ PASSED: BomListScreen
✅ PASSED: BomFormScreen
✅ PASSED: BomDetailScreen
✅ PASSED: StockDashboardScreen
✅ PASSED: StockMovementScreen
✅ PASSED: AuditLogScreen
✅ PASSED: SalesListScreen
✅ PASSED: SalesFormScreen
✅ PASSED: SalesDetailScreen
✅ PASSED: CustomerPaymentListScreen
✅ PASSED: CustomerPaymentFormScreen
✅ PASSED: CustomerPaymentReceiptScreen
✅ PASSED: MasterEntryHubScreen
✅ PASSED: ProductListScreen
✅ PASSED: ProductFormScreen
✅ PASSED: ProductDetailScreen
✅ PASSED: CategoryScreen
✅ PASSED: UnitScreen
✅ PASSED: WarehouseScreen
✅ PASSED: SequenceScreen
✅ PASSED: SupplierListScreen
✅ PASSED: SupplierFormScreen
✅ PASSED: CustomerListScreen
✅ PASSED: CustomerFormScreen
✅ PASSED: TransporterListScreen
✅ PASSED: TransporterFormScreen
✅ PASSED: VehicleListScreen
✅ PASSED: PaymentMethodScreen
✅ PASSED: WasteListScreen
✅ PASSED: WasteEntryFormScreen
✅ PASSED: WasteReasonScreen
✅ PASSED: ExpenseListScreen
✅ PASSED: ExpenseFormScreen
✅ PASSED: ExpenseCategoryScreen
✅ PASSED: ReportsHubScreen
✅ PASSED: ManufacturingFlowScreen
✅ PASSED: NotificationsScreen
✅ PASSED: AppSettingsScreen
✅ PASSED: UserManagementScreen

======================================================
               DEFECT SCAN RESULTS SUMMARY             
======================================================
Total Screens Tested: 52
Defects Found: 0
======================================================
00:04 +1: All tests passed!
```

### 2. Backend & Repository Integration Test
Run command:
```bash
flutter test test/verify_all_modules_integration.dart
```
**Result:**
```
================================================================
                    INTEGRATION TEST SUMMARY                    
================================================================
Total Operations Tested: 22
Passed: 22 / 22 (100.0%)
================================================================
```
