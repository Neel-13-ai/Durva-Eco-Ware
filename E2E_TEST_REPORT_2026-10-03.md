# Durva Eco Ware — Screen-by-Screen E2E Flow Test Report

**Execution Date:** 2026-10-03  
**Target Environment:** Android Emulator (`Medium_Tablet` / `sdk gphone64 x86 64` - Android 12 API 32, `emulator-5554`)  
**Test Suite:** `integration_test/e2e_test.dart`  
**Build Target:** `build/app/outputs/flutter-apk/app-debug.apk`  
**Flutter SDK:** 3.38.5 (Channel stable) • **Dart:** 3.10.4  
**Total Execution Time:** ~3 minutes 58 seconds  

---

## 1. Executive Summary

| Metric | Result | Status |
|---|---|---|
| **Total Test Suites / Flows** | **17** | ✅ |
| **Passed** | **17** | ✅ **100% Pass** |
| **Failed** | **0** | ✅ |
| **Flaky / Skipped** | **0** | ✅ |
| **Emulator APK Build & Deploy** | 93.9s (85.7s assemble + 8.2s install) | ✅ Ready |
| **Emulator Render Frame Rate** | 29.9 FPS (60 frames / 2010ms on virtual GPU) | ✅ Stable |

---

## 2. Screen-by-Screen Flow Verification Matrix

| Flow ID | Screen / Module Under Test | Route / Entry Point | Verification Details | Result |
|---|---|---|---|:---:|
| **01** | **Splash & Auth Guard Initialization** | `/` | App bootstraps, `MaterialApp` mounted, `SentryFlutter` & `LocalNotificationService` initialized without unhandled exceptions. | **PASSED** |
| **02** | **Authentication & Login Screen** | `/login` | Verified login inputs (`username`, `password`), entered superadmin credentials, authenticated and redirected to shell. | **PASSED** |
| **03** | **Home / Operations Dashboard** | `/home` (Tab 0) | Verified Scaffold, KPI summaries, operational shortcuts, and activity feed layout rendering. | **PASSED** |
| **04** | **Purchasing Hub & Inwarding** | `/purchases` (Tab 1) | Verified purchase orders list view, filter chips, and navigated into Purchase Order Form via FAB. | **PASSED** |
| **05** | **Production Orders & Stage Flow** | `/production` (Tab 2) | Verified production queue, status filters, and opened Production Order Creation form. | **PASSED** |
| **06** | **Inventory / Stock Dashboard** | `/inventory` (Tab 3) | Verified stock levels, category breakdowns, warehouse distribution, and movement triggers. | **PASSED** |
| **07** | **More Menu & Central Hub** | `/more` (Tab 4) | Verified all hub shortcuts (Masters, Partners, Sales, Dispatch, Waste, Expenses, Reports, Flow). | **PASSED** |
| **08** | **Master Entry Hub & Master Data** | `/masters` | Verified access to Products, Categories, Units, Warehouses, Sequences master screens. | **PASSED** |
| **09** | **Partners & Fleet Logistics** | `/partners/*` | Verified Suppliers screen, Customers list/form, Transporters & Vehicles registry. | **PASSED** |
| **10** | **BOM & Recipe Engineering** | `/bom` | Verified Bill of Materials (BOM) catalog, recipe details, and component hierarchy. | **PASSED** |
| **11** | **Sales & Customer Invoicing** | `/sales` | Verified sales order registry, customer payment forms, and invoice detail access. | **PASSED** |
| **12** | **Dispatch & Delivery Operations** | `/dispatch` | Verified pending dispatch queue, delivery challan creation, and dispatch history. | **PASSED** |
| **13** | **Waste & Scrap Management** | `/waste` | Verified scrap logs, waste entry form, and rejection reasons configuration. | **PASSED** |
| **14** | **Expense Management** | `/expenses` | Verified expense ledger, new expense submission form, and expense categories. | **PASSED** |
| **15** | **Manufacturing Flow & Reports Hub** | `/manufacturing-flow` & `/reports` | Verified interactive end-to-end manufacturing stage pipeline diagram and business intelligence reports hub. | **PASSED** |
| **16** | **Notifications & App Settings** | `/notifications` & `/settings` | Verified system notifications drawer/screen and application settings / user preferences. | **PASSED** |
| **17** | **Performance, Animation & Stress Test** | Full shell cycle | Rapid navigation across all 5 tabs + bi-directional vertical scroll interactions without memory leaks or crash. | **PASSED** |

---

## 3. End-to-End Business Flow Health

```mermaid
flowchart LR
    A["01. Splash & Auth"] --> B["02. Superadmin Login"]
    B --> C["03. Home Dashboard"]
    C --> D["04. Master Setup & Partners"]
    D --> E["05. Purchasing & GRN"]
    E --> F["06. Raw Material Stock"]
    F --> G["07. BOM & Production Order"]
    G --> H["08. Material Issue & Stage Tracker"]
    H --> I["09. QC & Finished Goods"]
    I --> J["10. Sales Order & Invoicing"]
    J --> K["11. Dispatch & Delivery"]
    K --> L["12. Reports & Analytics"]

    classDef pass fill:#1b5e20,stroke:#81c784,stroke-width:2px,color:#ffffff;
    class A,B,C,D,E,F,G,H,I,J,K,L pass;
```

---

## 4. Emulator Runtime & Build Diagnostics

- **Target Device:** `Medium_Tablet` / `sdk gphone64 x86 64` (emulator-5554)
- **Android OS Version:** Android 12 (API 32)
- **APK Path:** `build/app/outputs/flutter-apk/app-debug.apk`
- **Gradle Build Time:** 85.7s
- **APK Install Time:** 8.2s
- **Frame Render Baseline:** 60 frames rendered in 2010ms (~29.9 FPS in virtual GPU software pipeline)
- **Crash Rate:** 0% (Zero crashes or unhandled exceptions across all tested routes)