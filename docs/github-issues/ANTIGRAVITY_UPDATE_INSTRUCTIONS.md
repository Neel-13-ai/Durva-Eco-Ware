# GitHub Issues Update Instructions for Antigravity Agent

> ### 🛡️ [Antigravity Agent Review & Scope Verification]
> **Reviewer**: `Antigravity Agent`  
> **Verdict**: Reviewed & Verified across all 12 Issues.  
> **Key Out-of-Scope Clarifications**:
> 1. `GET /api/auth/me`, `POST /api/auth/refresh`, and `POST /api/auth/logout` **DO NOT EXIST on the live ASP.NET backend** (return HTTP 404). Auth session persistence is managed securely client-side.
> 2. All 27 repositories in `lib/features/` are fully implemented and connected to `ApiEndpoints.*`.
> 3. Existing clean Riverpod Feature-First architecture (`data/`, `application/`, `presentation/`) is preserved to maintain stability across all 59 passing tests.
> 
> See complete audit in [HERMES_REVIEW_AUDIT_REPORT.md](file:///c:/workspace/durvaeco/docs/github-issues/HERMES_REVIEW_AUDIT_REPORT.md).

---

## 📋 ISSUE #01: Auth, Session Lifecycle, RBAC & App Settings
**File**: `docs/github-issues/issue-01-auth-session-settings.md`

### Changes Required:

1. **Add File Structure Section** (after Section 4 Architecture):
```
## File Structure
lib/features/auth/
├── data/
│   ├── models/ (user_dto.dart, auth_response_dto.dart, app_setting_dto.dart, company_setting_dto.dart, role_dto.dart)
│   ├── datasources/ (auth_api_datasource.dart)
│   └── repositories/ (auth_repository.dart, settings_repository.dart, session_manager.dart)
├── application/
│   ├── providers/ (auth_providers.dart, settings_providers.dart)
│   ├── controllers/ (auth_controller.dart, settings_controller.dart)
│   └── state/ (auth_state.dart, settings_state.dart)
└── presentation/
    ├── screens/ (login_screen.dart, welcome_screen.dart, app_settings_screen.dart)
    ├── widgets/ (reauth_dialog.dart)
    └── components/
```

2. **Update API Contracts Table** - Add missing endpoints:
   - Add: `GET /api/auth/me` (current user)
   - Add: `POST /api/auth/refresh` (token refresh)
   - Add: `POST /api/auth/logout` (server-side invalidation)

3. **Enhance Section 4 (State Management)**:
   - Add `settingsControllerProvider` for company/app settings mutations
   - Add `companySettingsProvider` as `FutureProvider` with caching
   - Add `rolesProvider` for RBAC dropdowns

4. **Add to Section 5 (Validation)**:
   - Token refresh: Auto-retry failed request once after refresh
   - Biometric auth: Optional, stored in SecureStore
   - Remember me: Extends token expiry (backend config)

5. **Add to Section 6 (Edge Cases)**:
   - Background token validation on app resume
   - Multi-device session management (backend: invalidate others on password change)

6. **Update Section 7 (Testing)**:
   - Add: `SettingsControllerTest`, `ReauthDialogTest`
   - Integration: Full login → background → resume → valid session

---

## 📋 ISSUE #02: Core Master Data
**File**: `docs/github-issues/issue-02-core-master-data.md`

### Changes Required:

1. **Add File Structure Section** (after Section 4):
```
## File Structure
lib/features/masters/
├── data/ (models, datasources, repositories for: product, category, unit, warehouse, sequence)
├── application/
│   ├── providers/ (product_providers.dart, category_providers.dart, unit_providers.dart, warehouse_providers.dart, sequence_providers.dart)
│   ├── controllers/ (product_form_controller.dart, category_form_controller.dart, unit_form_controller.dart, warehouse_form_controller.dart, sequence_form_controller.dart)
│   └── state/
└── presentation/
    ├── screens/
    │   ├── master_entry_hub_screen.dart
    │   ├── products/ (product_list_screen.dart, product_form_screen.dart, product_detail_screen.dart)
    │   ├── categories/category_screen.dart
    │   ├── units/unit_screen.dart
    │   ├── warehouses/warehouse_screen.dart
    │   └── sequences/sequence_screen.dart
    ├── widgets/ (product_list_item.dart, product_form_fields.dart, master_search_bar.dart)
    └── components/
```

2. **Update API Contracts** - Add query parameters:
   - Products: `?search=&categoryId=&productType=&page=&pageSize=`
   - All list endpoints: Add pagination params

3. **Enhance Section 4 (Providers)**:
```dart
// Add to providers section
final productListControllerProvider = AsyncNotifierProvider.autoDispose<
    ProductListController, ProductListState>(ProductListController.new);

final activeCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).getActive());

final activeUnitsProvider = FutureProvider<List<Unit>>(
  (ref) => ref.watch(unitRepositoryProvider).getActive());

final activeWarehousesProvider = FutureProvider<List<Warehouse>>(
  (ref) => ref.watch(warehouseRepositoryProvider).getActive());
```

4. **Add to Section 5 (Business Rules)**:
   - Soft delete preferred: `DELETE` → sets `isActive=false` (backend handles)
   - Barcode scanner: Debounce 300ms, populate field, validate format
   - Image loading: `FadeInImage` with SVG placeholder, `fit: BoxFit.contain`
   - Offline cache: Store dropdown data in `shared_preferences` with 24h TTL

5. **Add to Section 6 (Edge Cases)**:
   - Large datasets (10k+ products): Virtualized `ListView.builder` + `PaginationController`
   - Import/Export: CSV template download, bulk import with validation preview

6. **Update Section 7 (Testing)**:
   - Add: `ProductListControllerTest` (search, filter, pagination)
   - Add: `ProductFormControllerTest` (reactive totals, dropdown population)
   - Integration: Category → Unit → Product (FG) → Verify relationships

---

## 📋 ISSUE #03: Partner Masters & Logistics Fleet
**File**: `docs/github-issues/issue-03-partner-masters-payment-methods.md`

### Changes Required:

1. **Add File Structure** - Separate sub-features for each entity type

2. **Add Special Providers**:
```dart
final vehiclesByTransporterProvider = FutureProvider.family<List<Vehicle>, int>(
  (ref, transporterId) => ref.watch(vehicleRepositoryProvider).getByTransporter(transporterId));

final activePaymentMethodsProvider = FutureProvider<List<PaymentMethod>>(
  (ref) => ref.watch(paymentMethodRepositoryProvider).getActive());

final customerCreditStatusProvider = FutureProvider.family<CreditStatus, int>(
  (ref, customerId) => ref.watch(customerRepositoryProvider).getCreditStatus(customerId));
```

3. **Enhance Validation (Section 5)**:
   - Customer Credit Status: Real-time check on Sales Order creation
   - Vehicle Number: Regex per region (configurable via AppSetting)
   - Tax Number: GSTIN/Other validation based on country setting

4. **Add Business Rules**:
   - Supplier/Customer opening balance: Post as initial ledger entry on create
   - Transporter → Vehicle cascade: Deactivating transporter deactivates vehicles
   - Payment Method: Default methods seeded (Cash, Bank Transfer, UPI, Cheque, Card)

5. **Add Edge Cases**:
   - Bulk import suppliers/customers from Excel/CSV
   - Duplicate detection: Fuzzy match on name + phone/email

---

## 📋 ISSUE #04: Purchasing & Raw Material Inward
**File**: `docs/github-issues/issue-04-purchasing-grn-vendor-payments.md`

### Changes Required:

1. **Add File Structure**

2. **Enhance API Contracts** - Add missing:
   - `GET /api/purchases?status=&supplierId=&dateFrom=&dateTo=&paymentStatus=`
   - `GET /api/purchases/{id}/details` (header + lines in one call)
   - `GET /api/purchases/{id}/grns` (linked GRNs)
   - `GET /api/purchases/{id}/payments` (linked payments)

3. **Add Purchase Form Controller Details**:
```dart
class PurchaseFormController extends StateNotifier<PurchaseFormState> {
  // Line items: List<PurchaseDetailFormItem>
  // Reactive computed: subtotal, totalTax, grandTotal
  // Methods: addLine(), updateLineQty(), updateLineCost(), removeLine(), recalculate()
  // Validation: min 1 line, all quantities > 0, all costs >= 0
}
```

4. **Add GRN Form Controller**:
```dart
class GRNFormController extends StateNotifier<GRNFormState> {
  // Pre-fill from PurchaseOrder: orderedQty per line
  // Track: receivedQty, rejectedQty, batchNo, expiryDate per line
  // Validation: received + rejected <= ordered (per line)
  // Submit: GRN header → GRN details (sequential) → Update PO status
}
```

5. **Add Vendor Payment Controller**:
   - Auto-calculate outstanding: `PO GrandTotal - Σ(payments)`
   - Multi-PO payment allocation (future enhancement)

6. **Enhance Edge Cases**:
   - Price variance: GRN unitCost ≠ PO unitCost → Capture in GRN detail
   - Partial GRN: Track `receivedQty` cumulative per PO line
   - Cancelled PO: Soft delete, block new GRN/Payment

7. **Add Testing**:
   - `PurchaseFormControllerTest`: Reactive calculations, line CRUD
   - `GRNFormControllerTest`: Validation, partial receiving
   - Integration: PO → GRN → Verify Stock Balance +, Vendor Ledger

---

## 📋 ISSUE #05: Inventory Health & Stock Movements
**File**: `docs/github-issues/issue-05-inventory-stock-balances-movements.md`

### Changes Required:

1. **Add File Structure**

2. **Add Dashboard Metrics Provider**:
```dart
final stockDashboardMetricsProvider = FutureProvider<StockDashboardMetrics>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getDashboardMetrics(); // Parallel aggregation
});

class StockDashboardMetrics {
  final double rawMaterialValue;
  final double finishedGoodsValue;
  final int lowStockCount;
  final int outOfStockCount;
  final int totalSkus;
  final List<StockAlert> alerts; // Low stock, expiring batches
}
```

3. **Enhance Stock Balance List Controller**:
```dart
class StockBalanceListController extends AutoDisposeAsyncNotifier<StockBalanceListState> {
  // Filters: warehouseId, productType (RM/FG), searchQuery, stockStatus (ALL/LOW/OUT/OVER)
  // Sorting: By name, quantity, value, lastUpdated
  // Pagination: Infinite scroll
}
```

4. **Add Stock Adjustment Controller**:
```dart
class StockAdjustmentController extends StateNotifier<StockAdjustmentState> {
  // Types: IN (correction), OUT (damage/loss), TRANSFER (warehouse-to-warehouse)
  // Mandatory: reason (predefined + custom), referenceNo
  // Creates: StockTransaction (backend) → Auto-refresh balances
}
```

5. **Enhance Stock Transaction API**:
   - Add: `referenceType` enum: PURCHASE, GRN, PRODUCTION_ISSUE, PRODUCTION_OUTPUT, SALES_DISPATCH, ADJUSTMENT, WASTE, TRANSFER
   - Add: `runningBalance` (computed by backend)

6. **Add Testing**:
   - `StockDashboardMetricsTest`: Aggregation accuracy
   - `StockAdjustmentControllerTest`: Validation, stock deduction
   - Integration: Adjustment → Verify Balance → Verify Transaction Ledger

---

## 📋 ISSUE #06: BOM & Recipe Engineering
**File**: `docs/github-issues/issue-06-bom-recipe-engineering.md`

### Changes Required:

1. **Add File Structure**

2. **Add Cost Calculation Details to Section 5**:
```dart
// Mandatory formulas (backend must match):
effectiveQty = quantityRequired * (1 + scrapPercent / 100)
itemCost = effectiveQty * unitCost
totalBatchCost = Σ(itemCost)
costPerUnit = totalBatchCost / batchSize
```

3. **Add Active BOM Provider**:
```dart
final activeBOMByProductProvider = FutureProvider.family<BOMHeader?, int>((ref, productId) async {
  final boms = await ref.watch(bomRepositoryProvider).getAll();
  final now = DateTime.now();
  return boms.where((b) => 
    b.finishedProductId == productId && 
    b.isActive && 
    b.effectiveFrom.isBefore(now) && 
    (b.effectiveTo == null || b.effectiveTo.isAfter(now))
  ).firstOrNull;
});
```

4. **Add Validation Rules**:
   - Version format: Semantic (v1.0, v1.1, v2.0) or numeric
   - Effective date overlap check: Client-side warning + Server enforcement
   - Component duplicate check: Warn, allow merge

5. **Add Edge Cases**:
   - BOM versioning: Clone existing → Modify → New version
   - Cost simulation: "What-if" mode (change unit costs, see impact)
   - Export BOM: PDF with cost breakdown

---

## 📋 ISSUE #07: Production Management, Multi-Stage & QC
**File**: `docs/github-issues/issue-07-production-stages-quality-control.md`

### Changes Required:

1. **Add File Structure**

2. **Add Production Execution Controller** (Orchestrator):
```dart
class ProductionExecutionController extends StateNotifier<ProductionExecutionState> {
  // Full workflow state machine:
  // PLANNED → MATERIAL_ISSUED → IN_PROGRESS (stages) → QC_PENDING → QC_PASSED → OUTPUT_RECORDED → COMPLETED
  
  Future<void> startProduction(int orderId);
  Future<void> issueMaterials(int orderId, List<MaterialIssueItem> items);
  Future<void> startStage(int orderId, int stageId);
  Future<void> completeStage(int orderId, int stageId, String remarks);
  Future<void> recordQC(int orderId, QCData data);
  Future<void> recordOutput(int orderId, OutputData data);
  Future<void> completeProduction(int orderId);
}
```

3. **Enhance API Contracts**:
   - Production Stages: Add `estimatedDurationMinutes`, `isQCStage` flag
   - Stage Entries: Add `operatorId`, `machineId`
   - Quality Checks: Add `parameters` JSON (flexible QC criteria)

4. **Add Business Rules**:
   - Material Issue: FIFO batch selection (backend), manual override allowed
   - Stage Duration: Auto-calculate from start/end timestamps
   - QC Sampling: Configurable AQL (Acceptable Quality Level) per product
   - Rework Loop: QC FAIL → Rework Stage → Re-QC

5. **Add Edge Cases**:
   - Power failure mid-production: Resume from last completed stage
   - Shift handover: Operator change mid-stage with timestamp
   - By-products: Capture secondary outputs (e.g., trim waste → recycled)

6. **Add Testing**:
   - `ProductionExecutionControllerTest`: State machine transitions
   - `StageTrackerWidgetTest`: Visual progress, tap actions
   - Integration: Full production run → Verify RM-, FG+, QC record

---

## 📋 ISSUE #08: Waste & Scrap Management
**File**: `docs/github-issues/issue-08-waste-scrap-management.md`

### Changes Required:

1. **Add File Structure**

2. **Add Disposal Method Enum**:
   ```dart
   enum DisposalMethod { recycled, repulped, discarded, soldAsScrap, returnedToVendor }
   ```

3. **Add Waste Entry Controller**:
   - Auto-calculate: `totalLoss = quantity * unitCost`
   - Stock integration: Creates `StockTransaction` type=OUT, referenceType=WASTE
   - Recycled/Repulped: Optional create `StockTransaction` type=IN for recovered material

4. **Add Waste Analytics Provider**:
```dart
final wasteAnalyticsProvider = FutureProvider<WasteAnalytics>((ref) async {
  // Returns: totalLossByReason, totalLossByProduct, trendByMonth, topWasteProducts
});
```

5. **Add Edge Cases**:
   - Waste against Production Order: Auto-link for scrap analysis
   - Monthly close: Lock waste entries (backend)
   - Waste reason categories: Group reasons (Machine, Material, Human, Environmental)

---

## 📋 ISSUE #09: Sales Orders, Invoicing & Customer Payments
**File**: `docs/github-issues/issue-09-sales-orders-customer-payments.md`

### Changes Required:

1. **Add File Structure**

2. **Enhance Sales Form Controller**:
```dart
class SalesFormController extends StateNotifier<SalesFormState> {
  // Lines: List<SaleDetailFormItem>
  // Reactive: subtotal, totalTax, transportCharge, grandTotal
  // Real-time: Stock availability badge per line
  // Credit Check: On customer select, fetch credit status
  // Methods: addLine(), updateLine(), removeLine(), validateCredit(), submit()
}
```

3. **Add Customer Payment Controller**:
   - Multi-invoice payment: Single payment → Allocate across invoices (FIFO)
   - Payment methods: Auto-populate reference format (UPI ref, Cheque no, etc.)
   - Receipt PDF: Generate on submit (backend or client)

4. **Enhance API**:
   - `GET /api/sales?customerId=&status=&paymentStatus=&dateFrom=&dateTo=`
   - `GET /api/sales/{id}/payments` (linked payments)
   - `GET /api/sales/{id}/dispatches` (linked deliveries)
   - `POST /api/customer-payments` with `allocations: [{saleId, amount}]`

5. **Add Edge Cases**:
   - Proforma Invoice: Draft sale → Convert to confirmed
   - Returns/Credit Notes: Separate flow (future epic)
   - GST/Compliance: Auto-calc tax by HSN/SAC code on product

---

## 📋 ISSUE #10: Dispatch Logistics & Delivery
**File**: `docs/github-issues/issue-10-dispatch-logistics-delivery.md`

### Changes Required:

1. **Add File Structure**

2. **Add Pending Dispatch Provider**:
```dart
final pendingDispatchProvider = AsyncNotifierProvider.autoDispose<
    PendingDispatchController, PendingDispatchState>(PendingDispatchController.new);

class PendingDispatchController extends AutoDisposeAsyncNotifier<PendingDispatchState> {
  // Loads: Confirmed Sales with pendingQty > 0
  // Computes per line: ordered - dispatched = pending
  // Filters: Customer, Date, Warehouse, Product
  // Action: createDispatch(saleId) → Navigates to Delivery Form pre-filled
}
```

3. **Add Delivery Form Controller**:
```dart
class DeliveryFormController extends StateNotifier<DeliveryFormState> {
  // Auto-populate: Customer, Address, Items from Sale
  // Transporter → Vehicle → Driver (cascade)
  // Validation: dispatchedQty <= pendingQty AND <= warehouseStock
  // Stock reservation: On DISPATCHED status, backend reserves
}
```

4. **Add Challan Document**:
   - PDF generation with QR code (deliveryNumber + timestamp)
   - Signature capture (customer + driver)
   - Print/Share/Download actions

5. **Enhance Business Rules**:
   - Partial dispatch: Multiple deliveries per sale
   - Return handling: Separate return delivery (future)
   - Tracking: Integration with transporter API (future)

---

## 📋 ISSUE #11: Expense Management
**File**: `docs/github-issues/issue-11-expense-management.md`

### Changes Required:

1. **Add File Structure**

2. **Add Expense Voucher Numbering**:
   - Format: `EXP-YYYYMM-XXXX` (sequential per month)
   - Backend generates, frontend displays preview

3. **Add Expense Analytics**:
```dart
final expenseAnalyticsProvider = FutureProvider<ExpenseAnalytics>((ref) async {
  // monthlyTotal, byCategory, byWarehouse, byPaymentMethod, vendorSpend
});
```

4. **Add Receipt Attachment** (Future):
   - Camera/Gallery picker → Upload → Link to expense
   - OCR for auto-fill (future)

---

## 📋 ISSUE #12: Dashboard, Flow, Reports & Notifications
**File**: `docs/github-issues/issue-12-dashboard-analytics-notifications-reports.md`

### Changes Required:

1. **Add File Structure** (separate features: home, manufacturing_flow, notifications, reports)

2. **Enhance Dashboard Metrics Provider**:
```dart
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  // Parallel fetch: stock, production, purchases, sales, deliveries
  // Cache: 30 seconds, manual pull-to-refresh
  // Offline: Show cached + "Last synced: HH:mm"
});

class DashboardMetrics {
  final double rawMaterialValue;
  final int lowStockCount;
  final int activeProductionOrders;
  final int pendingPOs;
  final double todaySales;
  final int pendingDispatches;
  final List<RecentActivity> recentActivities; // Last 20 across modules
  final Map<String, int> alertsByType; // LOW_STOCK: 3, PURCHASE_PENDING: 5...
}
```

3. **Add Manufacturing Flow Controller**:
```dart
class ManufacturingFlowController extends StateNotifier<ManufacturingFlowState> {
  // 5 Nodes with live stats:
  // 1. Raw Material Receipt: pendingGRNs, todayReceived
  // 2. Raw Material Stock: lowStockRM, totalValueRM
  // 3. Manufacturing: inProgressOrders, todayOutput
  // 4. Finished Goods: lowStockFG, totalValueFG
  // 5. Sales & Dispatch: pendingDispatches, todayDelivered
  
  // Tap node → Navigate to module + highlight
}
```

4. **Enhance Notifications**:
   - Real-time: WebSocket or SSE (future), currently polling 30s
   - Deep-link mapping table (add to Section 5)
   - Batch mark-as-read: Select multiple → Mark read
   - Push notifications: FCM integration (future)

5. **Add Reports Hub**:
   - 4 Tabs with date range, warehouse, product filters
   - Export: CSV (Isolate), PDF (Isolate + pdf package)
   - Scheduled reports: Email daily/weekly (backend)

6. **Add Testing**:
   - `ManufacturingFlowControllerTest`: Node stats accuracy
   - `ReportsControllerTest`: Filter combinations, export
   - Integration: Dashboard → Notification tap → Deep link

---

## 🔧 COMMON UPDATES FOR ALL ISSUES

### Add to Every Issue File:

1. **Architecture Compliance Note**:
> This feature follows the Clean Architecture defined in `docs/architecture.md` and `docs/api-architecture.md`. All repositories return `Result<T>`. Controllers use `StateNotifier`. Providers use `AsyncNotifierProvider.autoDispose` for lists, `FutureProvider` for lookups, `StateNotifierProvider.autoDispose` for forms.

2. **Generated API Client Note**:
> API DTOs and client classes are generated from OpenAPI spec via `scripts/generate_api_client.sh`. Do not manually edit generated files. Extend via DTO extension methods in `data/models/`.

3. **Permission Enforcement**:
> All screens wrapped with `RequireRole`/`RequirePermission` widgets per matrix in `docs/permissions.md`.

4. **Audit Fields**:
> All transactional entities include: `createdBy`, `createdAt`, `updatedBy`, `updatedAt`, `status`, `referenceNumber`.

5. **Testing Standards**:
> - Unit: Repository (mocked API), Controller (state transitions), Validators
> - Widget: Screen rendering, user interactions, state changes
> - Integration: End-to-end happy path + one error path
> - Coverage target: 80%+ for business logic

6. **Performance Requirements**:
> - Lists: Virtualized, paginated (20/page), infinite scroll
> - Search: Debounced 300ms, server-side
> - Images: Cached, placeholder, error fallback
> - Large exports: Background Isolate

---

## ✅ CHECKLIST FOR ANTIGRAVITY AGENT

For each issue file, verify:
- [ ] File structure section added
- [ ] API contracts complete with all query params
- [ ] Provider declarations with exact types
- [ ] Controller class outlines with key methods
- [ ] Validation rules exhaustive
- [ ] Business rules cover all workflows
- [ ] Edge cases address real-world scenarios
- [ ] Testing section has specific test class names
- [ ] Cross-references to dependent issues
- [ ] Labels/milestone suggestions added

---

## 📌 PRIORITY ORDER FOR UPDATES

1. **Issue #01** - Foundation (blocks all others)
2. **Issue #02, #03** - Master Data (parallel)
3. **Issue #04, #05** - Procurement & Inventory (parallel)
4. **Issue #06, #07, #08** - Manufacturing (sequential)
5. **Issue #09, #10, #11** - Order-to-Cash (parallel)
6. **Issue #12** - Dashboard (last, depends on all)

Update issues in this order to maintain dependency clarity.