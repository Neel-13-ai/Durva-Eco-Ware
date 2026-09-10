# Durva Eco Ware — Revised Complete Implementation Specification (12 Epics)

This document provides **production-grade, implementation-ready** specifications for all 12 feature epics. Each epic contains complete technical architecture, API contracts, state management patterns, validation rules, edge cases, testing requirements, and file structure mapping aligned with the Clean Architecture defined in `docs/architecture.md` and `docs/api-architecture.md`.

---

## 📋 QUICK REFERENCE: EPIC INDEX

| Epic | Title | Phase | Key APIs | Primary Screens |
|------|-------|-------|----------|-----------------|
| #01 | Auth, Session Lifecycle, RBAC & App Settings | 1 | `/api/auth/*`, `/api/app-settings`, `/api/company-settings`, `/api/roles` | Login, Re-Auth Dialog, Settings, Route Guards |
| #02 | Core Master Data (Products, Materials, Categories, Units, Warehouses, Sequences) | 2 | `/api/products`, `/api/categories`, `/api/units`, `/api/warehouses`, `/api/document-sequences` | Master Hub, Product/Material CRUD, Category/Unit/Warehouse Modals, Sequences |
| #03 | Partner Masters & Logistics Fleet (Suppliers, Customers, Transporters, Vehicles, Payment Methods) | 2 | `/api/suppliers`, `/api/customers`, `/api/transporters`, `/api/vehicles`, `/api/payment-methods` | Supplier/Customer/Transporter/Vehicle CRUD, Payment Methods |
| #04 | Purchasing & Raw Material Inward (PO, GRN, Vendor Payments) | 3 | `/api/purchases`, `/api/purchase-details`, `/api/goods-receipts`, `/api/goods-receipt-details`, `/api/vendor-payments` | PO Builder, PO List/Detail, GRN Form, Vendor Payment |
| #05 | Inventory Health Dashboard, Stock Balances & Movements | 3 | `/api/stock-balances`, `/api/stock-transactions`, `/api/audit-logs` | Stock Dashboard, Balance List, Adjustment Dialog, Movement Ledger |
| #06 | Bill of Materials (BOM) & Recipe Engineering | 4 | `/api/b-o-m-headers`, `/api/b-o-m-details` | BOM List, Recipe Builder, BOM Detail |
| #07 | Production Management, Multi-Stage Tracking & Quality Control | 4 | `/api/production-orders`, `/api/production-stages`, `/api/production-stage-entries`, `/api/production-material-issues`, `/api/production-outputs`, `/api/quality-checks` | Production Planner, Material Issue, Stage Tracker, Output Form, QC Inspection |
| #08 | Waste & Scrap Tracking Management | 4 | `/api/waste-reasons`, `/api/waste-entries` | Waste Reason Master, Waste Entry Form, Waste Ledger |
| #09 | Sales Orders, Invoicing & Customer Payments | 5 | `/api/sales`, `/api/sale-details`, `/api/customer-payments` | Sales/Invoice Form, Sales List, Sales Detail, Customer Payment |
| #10 | Dispatch Logistics, Fleet Delivery & Stock Outward | 5 | `/api/deliveries`, `/api/delivery-details`, `/api/transporters`, `/api/vehicles` | Pending Dispatch Queue, Delivery Form, Challan Preview, Dispatch History |
| #11 | Expense Management & Operational Cost Accounting | 5 | `/api/expense-categories`, `/api/expenses` | Expense Category, Expense Voucher, Expense Register |
| #12 | Executive Dashboard, Interactive Flow, Reports & Notifications | 6 | `/api/notifications`, Aggregated KPI APIs | Home Dashboard, Manufacturing Flow, Notifications, Reports Hub |

---

## 🏗️ COMMON TECHNICAL FOUNDATION (APPLIES TO ALL EPICS)

### Architecture Layers Per Feature

```
lib/features/<feature>/
├── data/
│   ├── models/           # Domain entities + DTO extensions (.g.dart for JSON)
│   ├── datasources/      # API client wrappers (uses generated OpenAPI client)
│   └── repositories/     # Repository impl returning Result<T>
├── application/
│   ├── providers/        # Riverpod providers (FutureProvider, AsyncNotifierProvider)
│   ├── controllers/      # StateNotifiers for mutation workflows
│   └── state/            # State classes (freezed or manual)
└── presentation/
    ├── screens/          # GoRouter destination widgets (ConsumerWidget)
    ├── widgets/          # Feature-specific reusable widgets
    └── components/       # Small UI components (cards, chips, dialogs)
```

### Standard Provider Patterns

```dart
// List Provider (filterable, paginated)
final productListControllerProvider = AsyncNotifierProvider.autoDispose<
    ProductListController, ProductListState>(ProductListController.new);

// Detail Provider (family)
final productDetailProvider = FutureProvider.family<Product, int>(
  (ref, id) => ref.watch(productRepositoryProvider).getById(id),
);

// Lookup Provider (cached dropdown data)
final activeCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).getActive(),
);

// Form Controller (mutation)
final productFormControllerProvider = StateNotifierProvider.autoDispose<
    ProductFormController, ProductFormState>(ProductFormController.new);
```

### Repository Pattern (Mandatory)

```dart
class ProductRepository {
  ProductRepository(this._api);
  final ProductApi _api;

  Future<Result<List<Product>>> getAll({bool includeInactive = false}) async {
    try {
      final resp = await _api.productList(includeInactive: includeInactive);
      return Success(resp?.products ?? []);
    } on ApiException catch (e) {
      return Err(ServerFailure(e.code, _clean(e.message)));
    } on Object catch (_) {
      return const Err(NetworkFailure());
    }
  }

  Future<Result<Product>> create(ProductRequest req) async { ... }
  Future<Result<void>> update(int id, ProductRequest req) async { ... }
  Future<Result<void>> delete(int id) async { ... }
}
```

### StateNotifiers for Mutations

```dart
class ProductFormController extends StateNotifier<ProductFormState> {
  ProductFormController(this._repo) : super(ProductFormState.initial());

  final ProductRepository _repo;

  Future<void> submit() async {
    state = state.copyWith(status: FormStatus.submitting);
    final result = state.isEditing
        ? await _repo.update(state.id!, state.toRequest())
        : await _repo.create(state.toRequest());
    result.when(
      success: (_) => state = state.copyWith(status: FormStatus.success),
      failure: (f) => state = state.copyWith(status: FormStatus.error, failure: f),
    );
  }
}
```

### Error Handling (Never Leak Exceptions)

- Repositories **always** return `Result<T>` (`Success<T>` | `Err<Failure>`)
- `Failure` types: `ServerFailure`, `NetworkFailure`, `ValidationFailure`, `UnauthorizedFailure`, `NotFoundFailure`, `ConflictFailure`, `UnknownFailure`
- Controllers translate `Failure` to user-facing messages via `FailureMapper.toMessage(failure)`

### API Client Generation

```bash
# Run once when OpenAPI spec changes
./scripts/generate_api_client.sh  # or .bat on Windows
# Outputs to lib/infrastructure/api/generated/
```

---

## 🔐 EPIC #01: AUTHENTICATION, SESSION LIFECYCLE, RBAC & APP SETTINGS

### File Structure
```
lib/features/auth/
├── data/
│   ├── models/
│   │   ├── user_dto.dart
│   │   ├── auth_response_dto.dart
│   │   ├── app_setting_dto.dart
│   │   ├── company_setting_dto.dart
│   │   └── role_dto.dart
│   ├── datasources/
│   │   └── auth_api_datasource.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── settings_repository.dart
│   │   └── session_manager.dart
│   └── authenticated_api_client.dart (already exists)
├── application/
│   ├── providers/
│   │   ├── auth_providers.dart (authControllerProvider, currentUserProvider)
│   │   ├── settings_providers.dart (appSettingsProvider, companySettingsProvider, rolesProvider)
│   │   └── authorization_providers.dart
│   ├── controllers/
│   │   ├── auth_controller.dart
│   │   └── settings_controller.dart
│   └── state/
│       ├── auth_state.dart
│       └── settings_state.dart
└── presentation/
    ├── screens/
    │   ├── login_screen.dart
    │   ├── welcome_screen.dart (existing)
    │   └── app_settings_screen.dart
    ├── widgets/
    │   └── reauth_dialog.dart
    └── components/
```

### API Contracts (Exact from Backend)

| Action | Method | Endpoint | Request | Response |
|--------|--------|----------|---------|----------|
| Login | POST | `/api/auth/login` | `{UserName, Password}` | `{token, userId, role, userName}` |
| List App Settings | GET | `/api/app-settings` | `?includeInactive=false` | `AppSettingDto[]` |
| Get App Setting | GET | `/api/app-settings/{id}` | - | `AppSettingDto` |
| Create App Setting | POST | `/api/app-settings` | `AppSettingRequest` | `AppSettingDto` |
| Update App Setting | PUT | `/api/app-settings/{id}` | `AppSettingRequest` | `200/204` |
| Delete App Setting | DELETE | `/api/app-settings/{id}` | - | `200/204` |
| List Company Settings | GET | `/api/company-settings` | `?includeInactive=false` | `CompanySettingDto[]` |
| Update Company Setting | PUT | `/api/company-settings/{id}` | `CompanySettingRequest` | `200` |
| List Roles | GET | `/api/roles` | `?includeInactive=false` | `RoleDto[]` |

### State Management Details

```dart
// auth_controller.dart - Already exists, enhance with:
class AuthController extends StateNotifier<AuthState> {
  // Add: token refresh, biometric auth option, remember me
  Future<Result<UserDto>> login(String username, String password);
  Future<void> refreshToken();
  Future<void> logout({bool clearBiometric = false});
}

// settings_controller.dart - NEW
class SettingsController extends StateNotifier<SettingsState> {
  Future<void> loadCompanySettings();
  Future<Result<void>> updateCompanySetting(CompanySettingRequest req);
  Future<Result<void>> updateAppSetting(AppSettingRequest req);
  Future<void> refreshAll();
}
```

### Route Guards (Already Exist - Verify)

```dart
// lib/shared/widgets/route_guard.dart - Apply to all protected routes
// lib/shared/widgets/require_role.dart - Role-based conditional rendering
// lib/shared/widgets/require_permission.dart - Permission-based conditional rendering
```

### Validation Rules
- Username: Required, min 3 chars, trimmed
- Password: Required, min 6 chars
- JWT: Stored ONLY in `FlutterSecureStorage` (never SharedPreferences)
- All authenticated requests: `Authorization: Bearer <token>` header
- 401 Response: Auto-trigger re-auth dialog or redirect to `/login`

### Edge Cases
- No internet on login → Network error banner (not crash)
- Expired token → Redirect to `/login` with message
- Invalid credentials (401) → Inline error, preserve username
- Concurrent 401s during token expiry → Queue/deduplicate refresh
- App restart → Background validation, no flicker

### Testing Requirements
- Unit: `AuthRepositoryTest` (login, 401, timeout), `SessionManagerTest` (secure store R/W)
- Unit: `SettingsRepositoryTest` (CRUD for app/company settings)
- Widget: `LoginScreenTest` (validation, loading state, error display)
- Widget: `RequireRoleWidgetTest` (show/hide based on role)
- Integration: Full login → token save → navigate to dashboard flow

---

## 📦 EPIC #02: CORE MASTER DATA MANAGEMENT

### File Structure
```
lib/features/masters/
├── data/
│   ├── models/
│   │   ├── product_dto.dart (ProductType enum: FINISHED_GOOD, RAW_MATERIAL)
│   │   ├── category_dto.dart (CategoryType enum)
│   │   ├── unit_dto.dart
│   │   ├── warehouse_dto.dart
│   │   └── document_sequence_dto.dart
│   ├── datasources/
│   │   ├── product_api_datasource.dart
│   │   ├── category_api_datasource.dart
│   │   ├── unit_api_datasource.dart
│   │   ├── warehouse_api_datasource.dart
│   │   └── sequence_api_datasource.dart
│   └── repositories/
│       ├── product_repository.dart
│       ├── category_repository.dart
│       ├── unit_repository.dart
│       ├── warehouse_repository.dart
│       └── sequence_repository.dart
├── application/
│   ├── providers/
│   │   ├── product_providers.dart (list, detail, form, active lookups)
│   │   ├── category_providers.dart
│   │   ├── unit_providers.dart
│   │   ├── warehouse_providers.dart
│   │   └── sequence_providers.dart
│   ├── controllers/
│   │   ├── product_form_controller.dart
│   │   ├── category_form_controller.dart
│   │   ├── unit_form_controller.dart
│   │   ├── warehouse_form_controller.dart
│   │   └── sequence_form_controller.dart
│   └── state/
│       ├── product_state.dart
│       ├── category_state.dart
│       └── ...
└── presentation/
    ├── screens/
    │   ├── master_entry_hub_screen.dart
    │   ├── products/
    │   │   ├── product_list_screen.dart
    │   │   ├── product_form_screen.dart
    │   │   └── product_detail_screen.dart
    │   ├── categories/category_screen.dart
    │   ├── units/unit_screen.dart
    │   ├── warehouses/warehouse_screen.dart
    │   └── sequences/sequence_screen.dart
    ├── widgets/
    │   ├── product_list_item.dart
    │   ├── product_form_fields.dart
    │   └── master_search_bar.dart
    └── components/
```

### API Contracts

| Resource | Method | Endpoint | Query/Body | Response |
|----------|--------|----------|------------|----------|
| Products | GET | `/api/products` | `?includeInactive=false&search=&categoryId=&productType=` | `ProductDto[]` |
| Product | GET | `/api/products/{id}` | - | `ProductDto` |
| Product | POST | `/api/products` | `ProductRequest` | `201 + ProductDto` |
| Product | PUT | `/api/products/{id}` | `ProductRequest` | `200` |
| Product | DELETE | `/api/products/{id}` | - | `200/204` |
| Categories | GET | `/api/categories` | `?includeInactive=false` | `CategoryDto[]` |
| Category | POST | `/api/categories` | `CategoryRequest` | `201` |
| Category | PUT | `/api/categories/{id}` | `CategoryRequest` | `200` |
| Category | DELETE | `/api/categories/{id}` | - | `200` |
| Units | GET | `/api/units` | `?includeInactive=false` | `UnitDto[]` |
| Unit | POST | `/api/units` | `UnitRequest` | `201` |
| Unit | PUT | `/api/units/{id}` | `UnitRequest` | `200` |
| Unit | DELETE | `/api/units/{id}` | - | `200` |
| Warehouses | GET | `/api/warehouses` | `?includeInactive=false` | `WarehouseDto[]` |
| Warehouse | POST | `/api/warehouses` | `WarehouseRequest` | `201` |
| Warehouse | PUT | `/api/warehouses/{id}` | `WarehouseRequest` | `200` |
| Warehouse | DELETE | `/api/warehouses/{id}` | - | `200` |
| Sequences | GET | `/api/document-sequences` | `?includeInactive=false` | `DocumentSequenceDto[]` |
| Sequence | POST | `/api/document-sequences` | `SequenceRequest` | `201` |
| Sequence | PUT | `/api/document-sequences/{id}` | `SequenceRequest` | `200` |

### Validation Rules
- **Product SKU**: Required, alphanumeric, unique (backend 409 on duplicate)
- **Product Name**: Required, max 200 chars
- **Prices**: `PurchasePrice >= 0`, `SellingPrice >= 0`, warn if SellingPrice < PurchasePrice
- **Stock Thresholds**: `MinimumStock >= 0`, `MaximumStock >= MinimumStock`
- **FK Validation**: `CategoryId`, `UnitId` must reference active masters
- **Warehouse Default**: Only one `IsDefault=true`; setting new default auto-clears old

### Business Rules
- ProductType determines available fields (FG vs RM)
- Deactivate (soft delete) preferred over hard delete for referential integrity
- Barcode scanner input → debounced populate Barcode field
- Image URL failure → SVG placeholder, no layout shift
- Offline cache for Categories/Units/Warehouses dropdowns

### State Management
```dart
// product_providers.dart
final productListControllerProvider = AsyncNotifierProvider.autoDispose<
    ProductListController, ProductListState>(ProductListController.new);

class ProductListController extends AutoDisposeAsyncNotifier<ProductListState> {
  // State: items, searchQuery, selectedCategoryId, selectedProductType, page, hasMore
  // Methods: loadInitial(), loadMore(), search(), filterByCategory(), filterByType()
}

final activeCategoriesProvider = FutureProvider<List<Category>>((ref) =>
    ref.watch(categoryRepositoryProvider).getActive());

final productFormControllerProvider = StateNotifierProvider.autoDispose<
    ProductFormController, ProductFormState>(ProductFormController.new);
```

### Edge Cases
- Delete master in use → 409 Conflict → "Cannot delete, linked to transactions. Deactivate instead."
- Large datasets → Virtualized `ListView.builder` with pagination
- Offline → Cached dropdown data with stale indicator

### Testing
- Unit: `ProductRepositoryTest` (CRUD, error mapping), `ProductFormValidationTest` (SKU unique, prices, thresholds)
- Widget: `ProductListScreenTest` (search, filter, empty state), `ProductFormScreenTest` (dropdowns populate, submit)
- Integration: Create Category → Create Unit → Create Product (FG) → Verify in list

---

## 🤝 EPIC #03: PARTNER MASTERS & LOGISTICS FLEET

### File Structure
```
lib/features/masters/
├── suppliers/          # Supplier sub-feature
├── customers/          # Customer sub-feature
├── transporters/       # Transporter sub-feature
├── vehicles/           # Vehicle sub-feature
└── payment_methods/    # Payment method sub-feature
```
Each follows the same pattern as Epic #02.

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Suppliers | GET/POST/PUT/DELETE | `/api/suppliers` | `supplierCode, supplierName, contactPerson, phone, email, address, city, state, zipCode, taxNumber, paymentTermsDays, openingBalance, isActive` |
| Customers | GET/POST/PUT/DELETE | `/api/customers` | `customerCode, customerName, companyName, contactPerson, phone, email, address, city, state, zipCode, taxNumber, creditLimit, openingBalance, isActive` |
| Transporters | GET/POST/PUT/DELETE | `/api/transporters` | `transporterCode, transporterName, contactPerson, phone, email, address, isActive` |
| Vehicles | GET/POST/PUT/DELETE | `/api/vehicles` | `transporterId, vehicleNumber, driverName, driverPhone, vehicleType, isActive` |
| Payment Methods | GET/POST/PUT/DELETE | `/api/payment-methods` | `methodName, isActive` |

### Key Validation Rules
- Phone: 10-15 digits
- Email: Optional or RFC 5322 format
- Codes: Uppercase alphanumeric (e.g., `SUP-001`, `CUS-001`)
- Vehicle Number: Regional license format regex `^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$`
- CreditLimit, OpeningBalance: Non-negative
- Vehicle requires valid TransporterId

### Special Providers
```dart
// vehicles_by_transporter_provider.dart
final vehiclesByTransporterProvider = FutureProvider.family<List<Vehicle>, int>(
  (ref, transporterId) => ref.watch(vehicleRepositoryProvider).getByTransporter(transporterId),
);

// active_payment_methods_provider.dart
final activePaymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) =>
    ref.watch(paymentMethodRepositoryProvider).getActive());
```

### Business Rules
- Inactive supplier → Cannot create new PO
- Inactive customer → Cannot create new Sales Order
- Duplicate code → 409 Conflict → Immediate form validation error
- Vehicle without transporter → Block save

### Testing
- Unit: `SupplierRepositoryTest`, `CustomerValidationTest` (credit limit, phone, email)
- Widget: `SupplierListScreenTest`, `VehicleFormScreenTest` (transporter dropdown → vehicle auto-populate)
- Integration: Register Transporter → Register Vehicle → Verify fleet listing

---

## 🛒 EPIC #04: PURCHASING & RAW MATERIAL INWARD (PO, GRN, VENDOR PAYMENTS)

### File Structure
```
lib/features/purchase/
├── data/
│   ├── models/
│   │   ├── purchase_dto.dart (status: DRAFT, PENDING, APPROVED, PARTIALLY_RECEIVED, RECEIVED, CANCELLED)
│   │   ├── purchase_detail_dto.dart
│   │   ├── goods_receipt_dto.dart
│   │   ├── goods_receipt_detail_dto.dart
│   │   └── vendor_payment_dto.dart
│   ├── datasources/...
│   └── repositories/
│       ├── purchase_repository.dart
│       ├── goods_receipt_repository.dart
│       └── vendor_payment_repository.dart
├── application/
│   ├── providers/
│   │   ├── purchase_list_provider.dart
│   │   ├── purchase_detail_provider.dart (family)
│   │   ├── grn_form_provider.dart
│   │   └── vendor_payment_provider.dart
│   ├── controllers/
│   │   ├── purchase_form_controller.dart
│   │   ├── grn_form_controller.dart
│   │   └── vendor_payment_controller.dart
│   └── state/...
└── presentation/
    ├── screens/
    │   ├── purchase_order_form_screen.dart
    │   ├── purchase_list_screen.dart
    │   ├── purchase_detail_screen.dart
    │   ├── goods_receipt_form_screen.dart
    │   └── vendor_payment_form_screen.dart
    └── widgets/...
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Purchases | GET | `/api/purchases` | `?includeInactive=false&status=&supplierId=&dateFrom=&dateTo=` |
| Purchase | GET | `/api/purchases/{id}` | - |
| Purchase | POST | `/api/purchases` | `purchaseNumber, supplierId, warehouseId, purchaseDate, expectedDeliveryDate, referenceNo, notes, status` |
| Purchase | PUT | `/api/purchases/{id}` | Full header |
| Purchase Details | GET | `/api/purchase-details` | `?purchaseId=` |
| Purchase Detail | POST | `/api/purchase-details` | `purchaseId, productId, quantity, unitCost, discount, tax` |
| GRN | POST | `/api/goods-receipts` | `grnNumber, purchaseId, warehouseId, receiptDate, status, receivedBy` |
| GRN Detail | POST | `/api/goods-receipt-details` | `grnId, productId, orderedQty, receivedQty, rejectedQty, unitCost, batchNo, expiryDate` |
| Vendor Payment | POST | `/api/vendor-payments` | `paymentNumber, supplierId, purchaseId, paymentDate, amount, paymentMethodId, referenceNo, notes` |

### Business Rules & Calculations
```dart
// Purchase Form Calculations (reactive in controller)
Subtotal = Σ(Quantity × UnitCost - Discount)
GrandTotal = Subtotal + Tax + TransportCost + OtherCost

// GRN Validation
ReceivedQty + RejectedQty ≤ RemainingOrderedQty
// Stock credited ONLY when GRN status = CONFIRMED

// Vendor Payment
Amount > 0
Amount ≤ OutstandingBalance(Purchase)
```

### State Management
```dart
// purchase_form_controller.dart
class PurchaseFormController extends StateNotifier<PurchaseFormState> {
  // Manages: header fields, lineItems List<PurchaseDetailFormItem>
  // Reactive: subtotal, tax, grandTotal recalculated on any line change
  // Methods: addLine(), updateLine(), removeLine(), recalculateTotals(), submit()
}

// grn_form_controller.dart
class GRNFormController extends StateNotifier<GRNFormState> {
  // Pre-fills from PurchaseOrder: ordered quantities per line
  // Tracks: receivedQty, rejectedQty per line with validation
  // BatchNo, ExpiryDate per line
  // Submits: GRN header + all GRN details in sequence
}
```

### Edge Cases
- Partial receiving: Multiple GRNs against one PO until fully received
- Price variance: Capture actual unit cost in GRN detail for FIFO/avg cost
- Network failure mid-submit: Sequential rollback or transactional batch
- Cancelled PO → Block GRN/Payment creation

### Testing
- Unit: `PurchaseCalculatorTest` (subtotal, tax, discount edge cases), `GRNValidationTest` (qty limits)
- Widget: `PurchaseOrderFormScreenTest` (line add/edit/delete updates totals), `GRNFormScreenTest` (balance counters)
- Integration: Create PO → Submit → GRN → Confirm → Verify Raw Material Stock +

---

## 📊 EPIC #05: INVENTORY HEALTH, STOCK BALANCES & MOVEMENTS

### File Structure
```
lib/features/inventory/
├── data/
│   ├── models/
│   │   ├── stock_balance_dto.dart
│   │   ├── stock_transaction_dto.dart (TransactionType: IN, OUT, TRANSFER, ADJUSTMENT)
│   │   ├── stock_metric_summary.dart
│   │   └── stock_adjustment_request.dart
│   ├── datasources/...
│   └── repositories/
│       ├── inventory_repository.dart
│       ├── stock_transaction_repository.dart
│       └── audit_log_repository.dart
├── application/
│   ├── providers/
│   │   ├── stock_dashboard_metrics_provider.dart
│   │   ├── stock_balance_list_controller.dart
│   │   ├── stock_transactions_provider.dart (family)
│   │   └── audit_logs_provider.dart
│   ├── controllers/
│   │   └── stock_adjustment_controller.dart
│   └── state/...
└── presentation/
    ├── screens/
    │   ├── stock_dashboard_screen.dart
    │   ├── stock_balance_list_screen.dart
    │   ├── stock_adjustment_dialog.dart
    │   └── stock_movement_screen.dart
    └── widgets/...
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Stock Balances | GET | `/api/stock-balances` | `?includeInactive=false&warehouseId=&productType=` |
| Stock Balance | GET/POST/PUT | `/api/stock-balances/{id}` | `productId, warehouseId, quantity, averageCost` |
| Stock Transactions | GET | `/api/stock-transactions` | `?includeInactive=false&productId=&warehouseId=&type=&dateFrom=&dateTo=` |
| Stock Transaction | POST | `/api/stock-transactions` | `productId, warehouseId, transactionType, quantityIn, quantityOut, unitCost, batchNo, referenceType, referenceId, transactionDate, userId, notes` |
| Audit Logs | GET | `/api/audit-logs` | `?includeInactive=false&tableName=&recordId=` |

### Key Calculations
```dart
// Stock Dashboard Metrics
TotalRawMaterialValue = Σ(stockBalance.quantity × averageCost) WHERE ProductType=RAW_MATERIAL
TotalFinishedGoodsUnits = Σ(stockBalance.quantity) WHERE ProductType=FINISHED_GOOD
LowStockCount = COUNT WHERE quantity ≤ product.minimumStock
OutOfStockCount = COUNT WHERE quantity == 0

// Low Stock Badge: stockBalance.quantity <= product.minimumStock
```

### Validation Rules
- Outward adjustment: Cannot exceed available stock (unless back-order enabled)
- Mandatory: Adjustment reason or notes
- **NEVER** calculate stock locally — always invoke backend transaction API
- Stock movement: `RunningBalance` computed by backend

### Edge Cases
- Concurrent deduction → Optimistic concurrency → 422 → "Insufficient stock"
- Multi-warehouse: Distinguish "zero in selected" vs "zero across all"
- Large datasets → Virtualized list + infinite scroll

### Testing
- Unit: `StockMetricCalculatorTest`, `StockAdjustmentValidationTest`
- Widget: `StockBalanceListScreenTest` (tabs, search, low stock badge), `StockAdjustmentDialogTest`
- Integration: Manual adjustment → Verify balance updated → Verify movement ledger entry

---

## 🧪 EPIC #06: BILL OF MATERIALS (BOM) & RECIPE ENGINEERING

### File Structure
```
lib/features/production/bom/
├── data/
│   ├── models/
│   │   ├── bom_header_dto.dart (status: DRAFT, ACTIVE, ARCHIVED)
│   │   ├── bom_detail_dto.dart
│   │   └── bom_recipe_summary.dart
│   ├── datasources/...
│   └── repositories/
│       └── bom_repository.dart
├── application/
│   ├── providers/
│   │   ├── bom_list_controller.dart
│   │   ├── bom_form_controller.dart
│   │   └── active_bom_by_product_provider.dart (family)
│   ├── controllers/
│   │   └── bom_form_controller.dart
│   └── state/...
└── presentation/
    ├── screens/
    │   ├── bom_list_screen.dart
    │   ├── bom_form_screen.dart
    │   └── bom_detail_screen.dart
    └── widgets/...
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| BOM Headers | GET | `/api/b-o-m-headers` | `?includeInactive=false` |
| BOM Header | GET/POST/PUT/DELETE | `/api/b-o-m-headers/{id}` | `bomCode, finishedProductId, versionNo, batchSize, effectiveFrom, effectiveTo, notes, isActive` |
| BOM Details | GET | `/api/b-o-m-details` | `?bomId=` |
| BOM Detail | POST/PUT/DELETE | `/api/b-o-m-details/{id}` | `bomId, rawMaterialId, quantityRequired, scrapPercent, unitCost, notes` |

### Cost Calculation Formula (Mandatory)
```dart
// Per Component
effectiveQty = quantityRequired * (1 + scrapPercent / 100)
itemCost = effectiveQty * unitCost

// BOM Level
totalBatchCost = Σ(itemCost)
costPerUnit = totalBatchCost / batchSize
```

### Validation Rules
- FinishedProductId: Must be `ProductType == FINISHED_GOOD`
- RawMaterialId: Must be `ProductType == RAW_MATERIAL`
- At least 1 component required
- `BatchSize > 0`, `QuantityRequired > 0`, `ScrapPercent 0-100`
- Unique versioning: No overlapping effective dates for same product with `isActive=true`
- No circular dependency (finished product as raw material)
- Duplicate raw material in same BOM → Warn/merge

### Special Provider
```dart
// active_bom_by_product_provider.dart
final activeBOMByProductProvider = FutureProvider.family<BOMHeader?, int>((ref, productId) async {
  final all = await ref.watch(bomRepositoryProvider).getAll();
  final now = DateTime.now();
  return all.where((b) => 
    b.finishedProductId == productId && 
    b.isActive && 
    b.effectiveFrom.isBefore(now) && 
    (b.effectiveTo == null || b.effectiveTo.isAfter(now))
  ).firstOrNull;
});
```

### Testing
- Unit: `BOMCostCalculatorTest` (scrap %, batch cost, per-unit), `BOMValidationTest` (zero batch, invalid RM)
- Widget: `BOMFormScreenTest` (add rows, scrap% updates cost card), `BOMListScreenTest` (search, status chips)
- Integration: Create BOM (FG + 3 RM) → Submit → Verify retrieval + cost accuracy

---

## 🏭 EPIC #07: PRODUCTION MANAGEMENT, MULTI-STAGE TRACKING & QC

### File Structure
```
lib/features/production/
├── data/
│   ├── models/
│   │   ├── production_order_dto.dart (status: DRAFT, PLANNED, IN_PROGRESS, COMPLETED, CANCELLED)
│   │   ├── production_stage_dto.dart
│   │   ├── production_stage_entry_dto.dart
│   │   ├── production_material_issue_dto.dart
│   │   ├── production_output_dto.dart
│   │   └── quality_check_dto.dart (result: PASS, FAIL, REWORK)
│   ├── datasources/...
│   └── repositories/
│       ├── production_repository.dart
│       └── quality_check_repository.dart
├── application/
│   ├── providers/
│   │   ├── production_order_list_controller.dart
│   │   ├── production_order_details_provider.dart (family - aggregates all)
│   │   ├── production_execution_controller.dart
│   │   └── production_stages_provider.dart
│   ├── controllers/
│   │   ├── production_order_form_controller.dart
│   │   ├── material_issue_controller.dart
│   │   ├── stage_tracker_controller.dart
│   │   ├── production_output_controller.dart
│   │   └── quality_check_controller.dart
│   └── state/...
└── presentation/
    ├── screens/
    │   ├── production_order_list_screen.dart
    │   ├── production_order_form_screen.dart
    │   ├── production_material_issue_screen.dart
    │   ├── production_stage_tracker_screen.dart
    │   ├── production_output_form_screen.dart
    │   └── quality_check_form_screen.dart
    └── widgets/...
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Production Stages | GET/POST | `/api/production-stages` | `stageName, sequenceNo, isActive` |
| Production Orders | GET/POST/PUT | `/api/production-orders` | `productionNumber, bomId, finishedProductId, warehouseId, productionDate, shiftName, plannedQty, status, notes` |
| Material Issues | GET/POST | `/api/production-material-issues` | `productionOrderId, productId, requiredQty, issuedQty, unitCost, batchNo` |
| Stage Entries | GET/POST | `/api/production-stage-entries` | `productionOrderId, stageId, startTime, endTime, status, remarks` |
| Production Outputs | GET/POST | `/api/production-outputs` | `productionOrderId, productId, producedQty, goodQty, rejectQty, batchNo, unitCost, outputDate` |
| Quality Checks | GET/POST | `/api/quality-checks` | `productionOrderId, productId, batchNo, sampleQty, passedQty, failedQty, result, checkedBy, remarks` |

### Business Rules
1. **Material Availability**: On planning, check `rawMaterial.currentStock >= requiredQty` (from BOM × plannedQty)
2. **Output Balance**: `ProducedQty == GoodQty + RejectQty` (enforced client + server)
3. **QC Gate**: Finished goods output **requires** QC `Result == PASS` (or manager override)
4. **Sequential Stages**: Stage entries must follow `sequenceNo` order
5. **Stock Movements**: 
   - Material Issue → `OUT` transaction (Raw Material)
   - Output Confirm → `IN` transaction (Finished Good)

### State Management
```dart
// production_execution_controller.dart - Orchestrates the full workflow
class ProductionExecutionController extends StateNotifier<ProductionExecutionState> {
  // Coordinates: Material Issue → Stage Progress → QC → Output
  // Methods: 
  //   startProduction(orderId) 
  //   issueMaterials(orderId, items)
  //   startStage(orderId, stageId)
  //   completeStage(orderId, stageId, remarks)
  //   recordQC(orderId, qcData)
  //   recordOutput(orderId, outputData)
  //   completeProduction(orderId)
}
```

### Edge Cases
- Excess rejection > BOM scrap tolerance → Mandatory Waste Entry link
- Shift pause/resume → Preserve timestamps
- Batch code: Auto-generate `FG-YYYYMMDD-ORDID` with manual override
- Partial completion → Track per-stage progress %

### Testing
- Unit: `ProductionOrderCalculatorTest` (BOM × qty = required materials), `OutputBalanceValidationTest`
- Widget: `ProductionStageTrackerScreenTest` (visual stage transitions), `QualityCheckFormScreenTest` (Pass/Fail/Rework)
- Integration: Full flow: PO → Issue Materials → Stages → QC Pass → Output → Verify FG Stock +

---

## ♻️ EPIC #08: WASTE & SCRAP TRACKING

### File Structure
```
lib/features/waste/
├── data/
│   ├── models/
│   │   ├── waste_reason_dto.dart
│   │   ├── waste_entry_dto.dart (disposalMethod: RECYCLED, REPULPED, DISCARDED, SOLD_AS_SCRAP)
│   │   └── waste_metric_summary.dart
│   ├── datasources/...
│   └── repositories/
│       └── waste_repository.dart
├── application/
│   ├── providers/
│   │   ├── waste_reason_list_provider.dart
│   │   ├── waste_list_controller.dart
│   │   └── waste_entry_form_controller.dart
│   ├── controllers/
│   │   └── waste_entry_form_controller.dart
│   └── state/...
└── presentation/
    ├── screens/
    │   ├── waste_reason_screen.dart
    │   ├── waste_entry_form_screen.dart
    │   └── waste_list_screen.dart
    └── widgets/...
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Waste Reasons | GET/POST/PUT | `/api/waste-reasons` | `reasonName, isActive` |
| Waste Entries | GET | `/api/waste-entries` | `?includeInactive=false&productId=&reasonId=&disposalMethod=&warehouseId=&dateFrom=&dateTo=` |
| Waste Entry | GET/POST/PUT/DELETE | `/api/waste-entries/{id}` | `wasteNumber, wasteDate, warehouseId, productId, wasteReasonId, quantity, unitCost, productionOrderId, batchNo, disposalMethod, notes, createdBy` |

### Business Rules
- `Quantity > 0` — verify stock sufficient if against warehouse
- `WasteReasonId` must be active
- `TotalLossAmount = Quantity × UnitCost`
- **Inventory Integration**: Every waste entry creates `StockTransaction` with `ReferenceType: "WASTE"`, `TransactionType: "OUT"`
- Recycled/Repulped → Optional corresponding `IN` transaction for recovered material

### Edge Cases
- Recycled raw material return → Link inward credit
- Post-month-close → Prevent edit (backend enforced)
- Waste against production order → Auto-link for scrap analysis

### Testing
- Unit: `WasteLossCalculatorTest`, `WasteRepositoryTest`
- Widget: `WasteEntryFormScreenTest` (product+reason+qty → loss display), `WasteListScreenTest` (filters)
- Integration: Record waste → Verify list → Verify stock balance deduction

---

## 💰 EPIC #09: SALES ORDERS, INVOICING & CUSTOMER PAYMENTS

### File Structure
```
lib/features/sales/
├── data/
│   ├── models/
│   │   ├── sale_dto.dart (status: DRAFT, CONFIRMED, CANCELLED; paymentStatus: PENDING, PARTIALLY_PAID, PAID)
│   │   ├── sale_detail_dto.dart
│   │   ├── customer_payment_dto.dart
│   │   └── invoice_summary_dto.dart
│   ├── datasources/...
│   └── repositories/
│       ├── sales_repository.dart
│       └── customer_payment_repository.dart
├── application/
│   ├── providers/
│   │   ├── sales_form_controller.dart
│   │   ├── sales_list_controller.dart
│   │   ├── sales_detail_provider.dart (family)
│   │   └── customer_payment_controller.dart
│   ├── controllers/...
│   └── state/...
└── presentation/
    ├── screens/
    │   ├── sales_form_screen.dart
    │   ├── sales_list_screen.dart
    │   ├── sales_detail_screen.dart
    │   └── customer_payment_form_screen.dart
    └── widgets/...
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Sales | GET | `/api/sales` | `?includeInactive=false&customerId=&status=&paymentStatus=&dateFrom=&dateTo=` |
| Sale | GET/POST/PUT/DELETE | `/api/sales/{id}` | `invoiceNumber, customerId, warehouseId, saleDate, dueDate, notes, subtotal, tax, transportCharge, status, paymentStatus` |
| Sale Details | GET/POST/PUT/DELETE | `/api/sale-details` | `saleId, productId, quantity, unitPrice, discount, tax` |
| Customer Payments | GET/POST | `/api/customer-payments` | `receiptNumber, customerId, saleId, paymentDate, amount, paymentMethodId, referenceNo, notes, createdBy` |

### Calculations
```dart
Subtotal = Σ(Quantity × UnitPrice - Discount)
TotalAmount = Subtotal + Tax + TransportCharge
```

### Validation Rules
- Min 1 line item: `Quantity > 0`, `UnitPrice > 0`, ProductType=FINISHED_GOOD
- **Credit Limit Check**: If `TotalAmount > (CreditLimit - OutstandingBalance)` → Warning dialog (confirm to proceed)
- **Stock Availability**: Badge if `OrderedQty > WarehouseStock`
- Customer Payment: `Amount > 0`, `Amount ≤ RemainingUnpaidBalance`

### Edge Cases
- Zero/negative → Block
- Inactive customer → Block new sales
- Concurrent orders → Verify stock at dispatch time

### Testing
- Unit: `SalesCalculatorTest`, `CreditLimitValidatorTest`, `SalesRepositoryTest`
- Widget: `SalesFormScreenTest` (dynamic totals), `CustomerPaymentDialogTest`
- Integration: Create Sale (2 FG lines) → Submit → Payment → Verify status PENDING→PAID

---

## 🚚 EPIC #10: DISPATCH LOGISTICS, FLEET DELIVERY & STOCK OUTWARD

### File Structure
```
lib/features/dispatch/
├── data/
│   ├── models/
│   │   ├── delivery_dto.dart (status: DRAFT, DISPATCHED, DELIVERED, CANCELLED)
│   │   ├── delivery_detail_dto.dart
│   │   └── challan_document_dto.dart
│   ├── datasources/...
│   └── repositories/
│       └── delivery_repository.dart
├── application/
│   ├── providers/
│   │   ├── pending_dispatch_provider.dart
│   │   ├── delivery_form_controller.dart
│   │   └── delivery_list_controller.dart
│   ├── controllers/...
│   └── state/...
└── presentation/
    ├── screens/
    │   ├── pending_dispatch_screen.dart
    │   ├── delivery_form_screen.dart
    │   ├── delivery_detail_screen.dart
    │   └── dispatch_history_screen.dart
    └── widgets/...
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Deliveries | GET | `/api/deliveries` | `?includeInactive=false&status=&transporterId=&customerId=&dateFrom=&dateTo=` |
| Delivery | GET/POST/PUT/DELETE | `/api/deliveries/{id}` | `deliveryNumber, saleId, customerId, transporterId, vehicleId, deliveryDate, dispatchDate, deliveredDate, deliveryAddress, freightAmount, status, trackingNumber, driverName, driverPhone, notes` |
| Delivery Details | GET/POST/PUT/DELETE | `/api/delivery-details` | `deliveryId, saleDetailId, productId, quantity` |

### Business Rules
- `DispatchedQuantity > 0`, `≤ SaleDetail.RemainingQuantity`
- `DispatchedQuantity ≤ WarehouseStock` (FG)
- Transporter → Vehicle auto-populates DriverName/DriverPhone
- **Stock Deduction**: Backend deducts FG stock on status → `DISPATCHED`
- Partial shipments: Multiple deliveries per Sale until fulfilled
- Cancelled before dispatch → Replenish reserved stock

### Special Provider
```dart
// pending_dispatch_provider.dart
final pendingDispatchProvider = AsyncNotifierProvider.autoDispose<
    PendingDispatchController, PendingDispatchState>(PendingDispatchController.new);

class PendingDispatchController extends AutoDisposeAsyncNotifier<PendingDispatchState> {
  // Loads: Sales with status=CONFIRMED, paymentStatus!=CANCELLED
  // Computes: pendingQty = orderedQty - dispatchedQty per line
  // Filters: Only lines with pendingQty > 0
}
```

### Testing
- Unit: `DeliveryValidationTest` (qty limits), `DeliveryRepositoryTest`
- Widget: `DeliveryFormScreenTest` (transporter→vehicle→driver auto-fill), `DeliveryDetailScreenTest` (challan render)
- Integration: Pending Sale → Create Delivery → Submit → Verify status=DISPATCHED → Verify FG Stock -

---

## 💸 EPIC #11: EXPENSE MANAGEMENT & OPERATIONAL COST ACCOUNTING

### File Structure
```
lib/features/expenses/
├── data/
│   ├── models/
│   │   ├── expense_category_dto.dart
│   │   ├── expense_dto.dart
│   │   └── expense_summary_report.dart
│   ├── datasources/...
│   └── repositories/
│       └── expense_repository.dart
├── application/
│   ├── providers/
│   │   ├── expense_categories_provider.dart
│   │   ├── expense_list_controller.dart
│   │   └── expense_form_controller.dart
│   ├── controllers/...
│   └── state/...
└── presentation/
    ├── screens/
    │   ├── expense_category_screen.dart
    │   ├── expense_form_screen.dart
    │   └── expense_list_screen.dart
    └── widgets/...
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Expense Categories | GET/POST/PUT/DELETE | `/api/expense-categories` | `categoryName, isActive` |
| Expenses | GET | `/api/expenses` | `?includeInactive=false&categoryId=&warehouseId=&paymentMethodId=&dateFrom=&dateTo=` |
| Expense | GET/POST/PUT/DELETE | `/api/expenses/{id}` | `expenseNumber, expenseCategoryId, warehouseId, expenseDate, description, amount, paymentMethodId, vendorName, referenceNo, createdBy` |

### Business Rules
- `Amount > 0`
- Mandatory: `ExpenseCategoryId`, `ExpenseDate`, `Amount`, `PaymentMethodId`
- Voucher Number: Auto-generate `EXP-YYYYMM-XXXX`
- Deactivated category → Block new expenses

### Testing
- Unit: `ExpenseRepositoryTest`, `ExpenseCalculatorTest` (monthly category totals)
- Widget: `ExpenseFormScreenTest`, `ExpenseListScreenTest` (date range, totals)
- Integration: Create Category → Submit Expense → Verify Register totals

---

## 📈 EPIC #12: EXECUTIVE DASHBOARD, INTERACTIVE FLOW, REPORTS & NOTIFICATIONS

### File Structure
```
lib/features/
├── home/
│   ├── presentation/screens/home_screen.dart
│   ├── application/providers/dashboard_metrics_provider.dart
│   └── application/controllers/dashboard_controller.dart
├── manufacturing_flow/
│   ├── presentation/screens/manufacturing_flow_screen.dart
│   ├── application/providers/manufacturing_flow_provider.dart
│   └── application/controllers/manufacturing_flow_controller.dart
├── notifications/
│   ├── data/models/app_notification_dto.dart
│   ├── data/repositories/notification_repository.dart
│   ├── application/providers/notification_providers.dart
│   ├── application/controllers/notification_controller.dart
│   └── presentation/screens/notifications_screen.dart
└── reports/
    ├── data/models/report_dto.dart
    ├── data/repositories/analytics_repository.dart
    ├── application/providers/reports_provider.dart
    ├── application/controllers/reports_controller.dart
    └── presentation/screens/reports_hub_screen.dart
```

### API Contracts

| Resource | Method | Endpoint | Key Fields |
|----------|--------|----------|------------|
| Notifications | GET | `/api/notifications` | `?includeInactive=false&userId=&type=&isRead=` |
| Notification | GET/PUT/DELETE | `/api/notifications/{id}` | `userId, notificationType, title, message, referenceId, isRead, readAt` |
| KPI Metrics | GET | Composite | Aggregated from: stock-balances, production-orders, purchases, sales, deliveries |

### Notification Types & Deep-Linking
| Type | Navigate To |
|------|-------------|
| `LOW_STOCK` | `/inventory/products/{referenceId}` |
| `PURCHASE_PENDING` | `/purchases/{referenceId}` |
| `PRODUCTION_ALERT` | `/production/{referenceId}` |
| `DISPATCH_READY` | `/dispatch/{referenceId}` |

### Dashboard KPIs (Real-time)
```dart
// dashboard_metrics_provider.dart
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getMetrics(); // Parallel fetches + aggregation
});

class DashboardMetrics {
  final double rawMaterialStockValue;
  final int lowStockCount;
  final int activeProductionOrders;
  final int pendingPurchaseOrders;
  final double todaySalesValue;
  final int pendingDispatches;
  final List<RecentActivity> recentActivities;
}
```

### Manufacturing Flow Screen
- Interactive horizontal pipeline: 5 nodes
- Tap node → Navigate to module + show live stats badge on node
- Nodes: Raw Material Receipt → Raw Material Stock → Manufacturing → Finished Goods → Sales & Dispatch

### Reports Hub (4 Tabs)
| Tab | Key Metrics |
|-----|-------------|
| Inventory | Stock valuation, slow-moving, reorder requirements |
| Purchase | Supplier spend, pending vs received, price trends |
| Production | Planned vs actual, yield efficiency, scrap analysis |
| Sales/Dispatch | Customer revenue, product demand, delivery turnaround |

### Export
- CSV/PDF generation in Dart `Isolate` (background compute)
- Date range filters on all reports

### Edge Cases
- Offline dashboard → Cached metrics + "Last synced at" indicator
- Empty notifications → "All caught up!" graphic
- Large exports → Isolate to prevent UI jank

### Testing
- Unit: `DashboardMetricsAggregatorTest`, `NotificationRepositoryTest`
- Widget: `HomeScreenTest` (KPIs, pull-to-refresh), `ManufacturingFlowScreenTest` (node taps), `NotificationsScreenTest` (unread count)
- Integration: App launch → Dashboard → Notifications → Tap low-stock → Navigate to Product Stock

---

## 🔄 CROSS-CUTTING CONCERNS (ALL EPICS)

### 1. Permission Matrix (Enforce via `RequireRole`/`RequirePermission` widgets)

| Module | Admin | Purchase | Production | Sales | Warehouse |
|--------|-------|----------|------------|-------|-----------|
| Masters | CRUD | R | R | R | R |
| Purchase | CRUD | CRUD | R | R | CRUD |
| Inventory | CRUD | R | CRUD | R | CRUD |
| Production | CRUD | R | CRUD | R | CRUD |
| Sales | CRUD | R | R | CRUD | R |
| Dispatch | CRUD | R | R | CRUD | CRUD |
| Reports | R | R | R | R | R |
| Expenses | CRUD | R | R | R | R |
| Waste | CRUD | R | CRUD | R | R |
| Settings | CRUD | - | - | - | - |

### 2. Audit Fields (All Transactional Entities)
```
createdBy, createdAt, updatedBy, updatedAt, status, referenceNumber, relatedTransactionId
```

### 3. Stock Traceability
```
StockMovement → SourceType (PURCHASE/PRODUCTION/DISPATCH/ADJUSTMENT/WASTE) → SourceId
```

### 4. Pagination Standard
```dart
// All list APIs support:
?page=1&pageSize=20&search=&sortBy=&sortOrder=
// Response: { items: [], totalCount: 100, page: 1, pageSize: 20, totalPages: 5 }
```

### 5. Date/Time Handling
- All dates: ISO 8601 UTC in API
- Display: User's local timezone (from `X-Timezone` header)
- Input: Date pickers → Convert to UTC for API

### 6. Offline-First Considerations
- Master data (Categories, Units, Warehouses, Payment Methods, Waste Reasons) → Cache with `shared_preferences` + timestamp
- Draft forms → Local persistence (Hive/Isar) → Sync on reconnect
- Queue mutations offline → Replay on connectivity

---

## 📝 IMPLEMENTATION CHECKLIST PER SCREEN (Definition of Done)

For **every screen** in every epic:
- [ ] UI matches approved design/Figma
- [ ] Navigation works (forward/back/deep-link)
- [ ] API integration works (success/error/loading)
- [ ] Loading state (skeleton/shimmer)
- [ ] Empty state (illustration + action)
- [ ] Error state (retry + dismiss)
- [ ] Validation (client + server errors mapped)
- [ ] Permission rules enforced (RequireRole/Permission)
- [ ] Success state (toast + list refresh)
- [ ] Duplicate submission prevented
- [ ] Data persisted correctly
- [ ] Unit tests (repository, controller, validators)
- [ ] Widget tests (key interactions)
- [ ] Integration test (critical path)

---

## 🚀 RECOMMENDED IMPLEMENTATION ORDER

### Phase 1: Foundation (Week 1-2)
1. Epic #01 complete (Auth, Session, RBAC, Settings)
2. Verify: `flutter analyze` clean, core tests pass, router guards work

### Phase 2: Master Data Hub (Week 2-3)
3. Epic #02 (Core Masters)
4. Epic #03 (Partner Masters + Fleet)

### Phase 3: Procurement & Inventory Core (Week 3-4)
5. Epic #04 (Purchase, GRN, Vendor Payments)
6. Epic #05 (Stock Balances, Adjustments, Movements)

### Phase 4: Manufacturing & Recipe (Week 4-5)
7. Epic #06 (BOM & Recipe)
8. Epic #07 (Production, Stages, QC)
9. Epic #08 (Waste & Scrap)

### Phase 5: Order-to-Cash & Fulfillment (Week 5-6)
10. Epic #09 (Sales, Invoicing, Customer Payments)
11. Epic #10 (Dispatch, Logistics, Delivery)
12. Epic #11 (Expenses)

### Phase 6: Executive Visibility (Week 6-7)
13. Epic #12 (Dashboard, Flow, Reports, Notifications)

### Phase 7: Hardening (Week 7-8)
- Permission enforcement audit
- Error handling review
- Audit/history verification
- Performance optimization
- Full test suite execution
- Production config & release

---

## 📌 NOTES FOR ANTIGRAVITY AGENT / TICKET UPDATES

When updating GitHub issues:
1. **Link each issue** to this specification document
2. **Add checkboxes** for each screen/API/validation/edge case/test
3. **Reference file paths** from the structure above
4. **Note dependencies** between issues (e.g., #07 needs #06, #10 needs #09)
5. **Tag with labels**: `epic`, `phase-X`, `area:auth|masters|purchase|inventory|production|sales|dispatch|expenses|dashboard`
6. **Milestone**: Assign to corresponding phase milestone
7. **Assignee**: Based on team capacity