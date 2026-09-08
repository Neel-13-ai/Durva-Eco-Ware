# [Feature]: Inventory Health Dashboard, Stock Balances & Stock Movement History

## 1. Feature Overview & Objective
Implement the real-time Inventory Control module for Durva Eco Ware. Provides real-time stock balances across warehouses for both Raw Materials and Finished Goods, visual stock health indicators (low stock, out of stock, overstocked), manual stock adjustment workflows (with mandatory reason codes), and an immutable stock transaction movement ledger.

---

## 2. Target Screens & UI Components
- **Stock Dashboard Screen** (`lib/features/inventory/presentation/screens/stock_dashboard_screen.dart`):
  - Metric summary cards: Total Raw Material Value, Total Finished Goods Units, Low Stock Alert Count, Out of Stock Count.
  - Warehouse switcher dropdown.
  - Quick action buttons: "Stock Adjustment", "Stock Transfer", "Download Inventory Report".
- **Stock Balances List Screen** (`lib/features/inventory/presentation/screens/stock_balance_list_screen.dart`):
  - Segmented control: `All`, `Raw Materials`, `Finished Goods`, `Low Stock`.
  - Item Card: Product Name, SKU, Category, Warehouse, Current Quantity, Unit, Average Cost, Total Stock Value (`Quantity * AverageCost`), Low Stock threshold badge.
  - Search by Product Name, SKU, or Barcode.
- **Stock Adjustment Modal & Form** (`lib/features/inventory/presentation/screens/stock_adjustment_dialog.dart`):
  - Fields: `ProductId`, `WarehouseId`, `AdjustmentType` (`IN` for addition, `OUT` for write-off/damage/correction), `Quantity`, `UnitCost`, `ReasonId` / `Notes`, `ReferenceNo`.
- **Stock Movement History / Transaction Ledger** (`lib/features/inventory/presentation/screens/stock_movement_screen.dart`):
  - Filterable audit table of all inventory movements (`TransactionType`: `IN`, `OUT`, `TRANSFER`, `ADJUSTMENT`).
  - Columns: Timestamp, Product Name, Warehouse, Type (Inward green / Outward red), Quantity, Running Balance, Reference (`PUR-001`, `PROD-001`, `DEL-001`, `ADJ-001`), User.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **Stock Balances** | `GET` | `/api/stock-balances` | `?includeInactive=false` | `[ { "id": 1, "productId": 1, "warehouseId": 1, "quantity": 450.0, "averageCost": 48.5 } ]` |
| | `GET` | `/api/stock-balances/{id}` | - | Stock Balance JSON |
| | `POST` | `/api/stock-balances` | `{ "productId": 1, "warehouseId": 1, "quantity": 100.0, "averageCost": 50.0 }` | `201 Created` |
| | `PUT` | `/api/stock-balances/{id}` | Update balance payload | `200 OK` |
| **Stock Transactions** | `GET` | `/api/stock-transactions` | `?includeInactive=false` | `[ { "id": 1, "productId": 1, "warehouseId": 1, "transactionType": "IN", "quantityIn": 100.0, "quantityOut": 0.0, "unitCost": 50.0, "batchNo": "BAT-01", "referenceType": "PURCHASE", "referenceId": 1, "transactionDate": "2026-08-29T12:00:00", "userId": 1, "notes": "GRN Receipt" } ]` |
| | `POST` | `/api/stock-transactions` | Full Stock Transaction JSON | `201 Created` |
| **Audit Logs** | `GET` | `/api/audit-logs` | `?includeInactive=false` | `[ { "id": 1, "userId": 1, "actionName": "STOCK_ADJUSTMENT", "tableName": "StockBalances", "recordId": 1, "oldValue": "100", "newValue": "90", "ipAddress": "..." } ]` |

---

## 4. Architecture & State Management
- **Domain Models**: `StockBalance`, `StockTransaction`, `StockMetricSummary`, `StockAdjustmentRequest`.
- **Repositories**: `InventoryRepository`, `StockTransactionRepository`, `AuditLogRepository`.
- **Controllers & Providers**:
  - `stockDashboardMetricsProvider`: Aggregates active stock balances, calculates total valuation and low-stock count.
  - `stockBalanceListControllerProvider`: AsyncNotifier with debounced search, warehouse filtering, and category filtering.
  - `stockAdjustmentControllerProvider`: Mutation notifier that posts transaction adjustment and triggers balance invalidation/refresh.
  - `stockTransactionsProvider(filter)`: Paginated family provider for the movement ledger.

---

## 5. Form Validation & Business Rules
- **Non-Negative Stock Balances**: Outward adjustments cannot exceed available stock unless explicit system back-order setting is enabled.
- **Mandatory Adjustment Audit**: Every manual adjustment must require `Notes` or a valid Reason.
- **Authoritative Calculations**: UI must NEVER calculate or mutate stock locally without invoking the backend API transaction endpoint.
- **Low Stock Criteria**: A product is marked "Low Stock" when `stockBalance.quantity <= product.minimumStock`.

---

## 6. Edge Cases & Failure Modes
- **Concurrent Stock Deduction**: If two operators attempt to consume the same stock batch simultaneously, handle optimistic concurrency / insufficient stock backend responses (422 Unprocessable Entity) with a friendly alert: "Insufficient stock available for this operation."
- **Multi-Warehouse Zero Stock**: Clearly distinguish between "No stock in selected warehouse" vs "No stock across all warehouses".
- **Large Inventory Datasets**: Ensure infinite scroll or virtualized `ListView.builder` is utilized to handle thousands of product SKU records smoothly at 60fps.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `StockMetricCalculatorTest`: Accurate calculation of low stock counts and total inventory valuation.
  - `StockAdjustmentValidationTest`: Rejection of negative adjustment amounts or missing reasons.
- [ ] **Widget Tests**:
  - `StockBalanceListScreenTest`: Category tab switching, search filtering, and low stock badge rendering.
  - `StockAdjustmentDialogTest`: Dropdown selection, quantity input, submit triggering repository update.
- [ ] **Integration Test**:
  - Perform manual stock adjustment -> Post transaction -> Verify stock balance list reflects updated quantity -> Verify new row in Stock Movement History.
