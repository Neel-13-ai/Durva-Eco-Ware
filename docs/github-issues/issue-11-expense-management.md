# [Feature]: Expense Management & Operational Cost Accounting

## 1. Feature Overview & Objective
Implement the Operational Expense Tracking system for Durva Eco Ware. Enables accounting and floor managers to categorize expenses (Utilities, Machine Maintenance, Factory Rent, Freight, Fuel, Packaging), log expense vouchers with receipts and payment methods, assign costs to specific warehouses or vendors, and monitor operational overheads.

---

## 2. Target Screens & UI Components
- **Expense Categories Master Screen & Modal** (`lib/features/expenses/presentation/screens/expense_category_screen.dart`):
  - Setup expense heads: `CategoryName` (e.g., Factory Electricity, Machine Spares, Raw Material Freight, Consumables), `IsActive`.
- **Expense Voucher Form Screen** (`lib/features/expenses/presentation/screens/expense_form_screen.dart`):
  - Fields: `ExpenseNumber`, `ExpenseCategoryId`, `WarehouseId`, `ExpenseDate`, `Description`, `Amount`, `PaymentMethodId`, `VendorName`, `ReferenceNo` (Bill / Invoice number), `CreatedBy`.
  - Payment Method dropdown, date picker, quick amount chips.
- **Expense Register & Analysis Screen** (`lib/features/expenses/presentation/screens/expense_list_screen.dart`):
  - Summary KPI cards: Total Monthly Expenses, Category Breakdown Chart, Warehouse Overhead.
  - Filter by Category, Warehouse, Payment Method, and Date Range.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **Expense Categories** | `GET` | `/api/expense-categories` | `?includeInactive=false` | `[ { "id": 1, "categoryName": "Machine Maintenance", "isActive": true } ]` |
| | `POST` | `/api/expense-categories` | `{ "categoryName": "Factory Utilities", "isActive": true }` | `201 Created` |
| | `PUT` | `/api/expense-categories/{id}` | Update Category JSON | `200 OK` |
| | `DELETE` | `/api/expense-categories/{id}` | - | `200 OK` |
| **Expenses** | `GET` | `/api/expenses` | `?includeInactive=false` | `[ { "id": 1, "expenseNumber": "EXP-001", "expenseCategoryId": 1, "warehouseId": 1, "expenseDate": "2026-08-29T12:00:00", "description": "Hydraulic oil replacement", "amount": 3500.0, "paymentMethodId": 1, "vendorName": "Oil Corp", "referenceNo": "INV-7890", "createdBy": 1 } ]` |
| | `GET` | `/api/expenses/{id}` | - | Expense JSON |
| | `POST` | `/api/expenses` | Full Expense JSON | `201 Created` |
| | `PUT` | `/api/expenses/{id}` | Update Expense JSON | `200 OK` |
| | `DELETE` | `/api/expenses/{id}` | - | `200 OK` |

---

## 4. Architecture & State Management
- **Domain Models**: `ExpenseCategory`, `Expense`, `ExpenseSummaryReport`.
- **Repositories**: `ExpenseRepository`.
- **Controllers & Providers**:
  - `expenseCategoriesProvider`: Fast cached lookup for form dropdowns.
  - `expenseListControllerProvider`: AsyncNotifier managing search, filters, pagination, and monthly total aggregation.
  - `expenseFormControllerProvider`: StateNotifier managing expense voucher entry and validation.

---

## 5. Form Validation & Business Rules
- **Amount Constraint**: `Amount > 0`.
- **Mandatory Fields**: `ExpenseCategoryId`, `ExpenseDate`, `Amount`, `PaymentMethodId`.
- **Voucher Sequence**: Auto-generate unique sequential voucher numbers (`EXP-YYYYMM-XXXX`).

---

## 6. Edge Cases & Failure Modes
- **Zero / Negative Amount**: Immediate form validation feedback.
- **Deactivated Expense Head**: Do not allow new expenses logged under deactivated categories.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `ExpenseRepositoryTest`: Mocked list, create, update, and delete calls.
  - `ExpenseCalculatorTest`: Aggregate monthly category-wise expense totals.
- [ ] **Widget Tests**:
  - `ExpenseFormScreenTest`: Dropdown selection, amount input, submit action.
  - `ExpenseListScreenTest`: Date range picker filtering and total summary update.
- [ ] **Integration Test**:
  - Create Expense Category -> Submit new Expense Voucher -> Verify it appears in the Expense Register with correct totals.

---

## 💬 Antigravity Agent Resolution & Verification Comments
- **Reviewer**: `Antigravity Agent`
- **Label**: `[Status: Verified & Resolved]`, `[Feature: Complete]`
- **Resolution**:
  - `ExpenseRepository` is wired to `/api/expenses` and `/api/expense-categories`.
  - Voucher creation, expense category breakdown, and total outflow aggregation verified.
