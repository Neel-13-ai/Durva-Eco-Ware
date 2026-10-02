# Durvaeco E2E Test Report
**Date:** 2026-10-03  
**Device:** sdk gphone64 x86 64 (emulator-5554) - Android 12 (API 32)  
**Test Suite:** integration_test/e2e_test.dart  
**Duration:** ~16 minutes 15 seconds  

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | 15 |
| **Passed** | 11 |
| **Failed** | 4 |
| **Skipped** | 0 |
| **Success Rate** | 73.3% |

---

## Test Results Detail

### ✅ PASSED (11)

| # | Test Name | Duration | Notes |
|---|-----------|----------|-------|
| 1 | Complete app launch and navigation flow | ~46.5s | App launched, splash loaded, MaterialApp verified |
| 2 | Login flow with valid credentials | ~40.3s | Already logged in (no login needed) |
| 3 | Home/Dashboard screen verification | ~65.2s | Scaffold found, dashboard rendered |
| 4 | Navigation through all 5 main tabs | ~75.3s | All 5 tabs (Home, Purchase, Production, Inventory, More) navigated successfully |
| 5 | Master Entry Hub navigation | ~63.3s | Master entry hub accessed |
| 6 | Sales flow - Orders, Detail | ~63.2s | Sales navigation from More tab succeeded |
| 7 | Dispatch flow - Pending, History | ~63.1s | Dispatch navigation from More tab succeeded |
| 8 | Reports and Manufacturing Flow | ~63.2s | Reports hub and manufacturing flow accessed |
| 9 | Notifications and Settings | ~60.1s | Notifications and settings icons found and tapped |
| 10 | Performance and memory baseline | ~65.4s | **22.4 FPS** (60 frames in 2681ms) - rapid nav stress test passed |
| 11 | Deep link / route handling | ~60.1s | Router responsive, final state captured |

---

### ❌ FAILED (4)

| # | Test Name | Failure Point | Error |
|---|-----------|---------------|-------|
| 1 | **Purchasing flow - List, Create, Detail** | Line 117 | `Expected: at least one matching candidate` — `ListView` not found (0 widgets) |
| 2 | **Production flow - Orders, BOM, Execution** | Line 140 | `Expected: at least one matching candidate` — `ListView` not found (0 widgets) |
| 3 | **Inventory/Stock flow - Dashboard, Movements** | Line 159 | `Expected: at least one matching candidate` — `ListView` not found (0 widgets) |
| 4 | **Error states and edge cases** | Line 280 | `Bad state: No element` — `ListView.first` returned empty, drag failed |

---

## Root Cause Analysis

### Common Pattern: Missing ListView Widgets (Tests 1-3)
All three tab-specific flow tests fail at the same assertion:
```dart
expect(find.byType(ListView), findsAtLeastNWidgets(1));
```

**Likely causes:**
- The tab screens (Purchase, Production, Inventory) may use `ListView.builder`, `GridView`, `CustomScrollView`, or other scrollable widgets instead of a direct `ListView`
- Data may be empty/loading, causing the list to not render
- The widget tree structure differs from test assumptions

### Error States Test (Test 4)
```dart
final listView = find.byType(ListView).first;
await tester.drag(listView, const Offset(0, 200));
```
Fails because `ListView.first` throws when no `ListView` exists in the tree — same root cause as above.

---

## Performance Metrics

| Metric | Value |
|--------|-------|
| **Frame Rate** | 22.4 FPS |
| **60 Frames Time** | 2681ms |
| **Target (60 FPS)** | 16.67ms/frame |
| **Assessment** | ⚠️ Below 60 FPS target — may indicate rendering overhead on emulator |

---

## Screenshots Captured

The test logs indicate these screenshot checkpoints were reached:
- `01_initial_launch`
- `02_no_login_needed`
- `03_home_dashboard`
- `04_tab_0_home` through `04_tab_4_more`
- `18_performance_test`
- `21_final_state`

Note: Integration tests on Android emulator cannot easily persist screenshots to host filesystem; these are logged as markers only.

---

## Recommendations

### Immediate Fixes
1. **Update ListView assertions** — Replace `find.byType(ListView)` with broader scrollable finder:
   ```dart
   find.byWidgetPredicate((w) => w is ScrollView || w is ListView || w is GridView)
   ```
   Or use keys on the actual list widgets in the app code.

2. **Add empty-state handling** — Tests should verify data loads before asserting list presence, or handle empty states gracefully.

3. **Fix error states test** — Guard the drag with existence check:
   ```dart
   final listViews = find.byType(ListView);
   if (listViews.evaluate().isNotEmpty) {
     await tester.drag(listViews.first, const Offset(0, 200));
   }
   ```

### Structural Improvements
- Add `Key` attributes to critical list widgets in the app (e.g., `Key('purchase_list')`) for reliable targeting
- Consider splitting into smaller focused test files per feature for faster iteration
- Run on physical device for accurate performance baseline (emulator skews FPS)

---

## Build Info
- **APK Built:** `build/app/outputs/flutter-apk/app-debug.apk` (debug)
- **Flutter Version:** 3.38.5 (channel stable)
- **Dart Version:** 3.10.4

---

*Report generated automatically from flutter test JSON output*