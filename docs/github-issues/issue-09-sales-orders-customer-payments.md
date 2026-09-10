# [Feature]: Sales Orders, Invoicing & Customer Payments

## 1. Feature Overview & Objective
Implement the complete Order-to-Cash (O2C) module for Durva Eco Ware. Supports Sales Order / Invoice creation with multi-product line items, automatic tax/discount/transport charge calculations, finished goods stock availability checks, customer credit limit validation, and Customer Payment receipt entry.

---

## 2. Target Screens & UI Components
- **Sales Order / Invoice Form Screen** (`lib/features/sales/presentation/screens/sales_form_screen.dart`):
  - Header: `InvoiceNumber`, `CustomerId` (shows credit balance), `WarehouseId`, `SaleDate`, `DueDate`, `Notes`.
  - Dynamic Line Items Table: Add/remove product rows (`ProductId` / Finished Goods, `Quantity`, `UnitPrice`, `Discount`, `Tax`).
  - Available Stock Badge: Real-time stock display next to each selected finished good.
  - Price Summary Card: `Subtotal`, `Discount`, `Tax`, `TransportCharge`, and **Grand Total**.
  - Status & Payment Status: `DRAFT`, `CONFIRMED`, `CANCELLED` and `PENDING`, `PARTIALLY_PAID`, `PAID`.
- **Sales Order & Invoices List Screen** (`lib/features/sales/presentation/screens/sales_list_screen.dart`):
  - Filter by Customer, Date Range, Order Status, and Payment Status.
  - Quick summary cards: Total Sales Value, Outstanding Receivables, Overdue Invoices.
- **Sales Detail & Action Hub** (`lib/features/sales/presentation/screens/sales_detail_screen.dart`):
  - Complete invoice overview, tax breakdown, customer address, payment history, and linked Dispatches.
  - Action buttons: "Record Customer Payment", "Create Dispatch / Delivery", "Share / Print Invoice PDF".
- **Customer Payment Receipt Modal & Form** (`lib/features/sales/presentation/screens/customer_payment_form_screen.dart`):
  - Fields: `ReceiptNumber`, `CustomerId`, `SaleId`, `PaymentDate`, `Amount`, `PaymentMethodId`, `ReferenceNo`, `Notes`, `CreatedBy`.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **Sales** | `GET` | `/api/sales` | `?includeInactive=false` | `[ { "id": 1, "invoiceNumber": "INV-001", "customerId": 1, "warehouseId": 1, "saleDate": "2026-08-29T12:00:00", "dueDate": "2026-09-29T12:00:00", "subtotal": 15000.0, "tax": 2700.0, "transportCharge": 300.0, "paymentStatus": "PENDING", "status": "CONFIRMED", ... } ]` |
| | `GET` | `/api/sales/{id}` | - | Full Sales JSON |
| | `POST` | `/api/sales` | Full Sales Header JSON | `201 Created` with created Sale ID |
| | `PUT` | `/api/sales/{id}` | Update Sales JSON | `200 OK` |
| | `DELETE` | `/api/sales/{id}` | - | `200 OK` |
| **Sale Details (Line Items)** | `GET` | `/api/sale-details` | `?includeInactive=false` | List of sale line items |
| | `POST` | `/api/sale-details` | `{ "saleId": 1, "productId": 1, "quantity": 1000.0, "unitPrice": 15.0, "discount": 0.0, "tax": 270.0 }` | `201 Created` |
| | `PUT` | `/api/sale-details/{id}` | Update item JSON | `200 OK` |
| | `DELETE` | `/api/sale-details/{id}` | - | `200 OK` |
| **Customer Payments** | `GET` | `/api/customer-payments` | `?includeInactive=false` | List of customer payment receipts |
| | `POST` | `/api/customer-payments` | `{ "receiptNumber": "REC-001", "customerId": 1, "saleId": 1, "paymentDate": "2026-08-29T12:00:00", "amount": 18000.0, "paymentMethodId": 1, "referenceNo": "UPI-REF-999" }` | `201 Created` |

---

## 4. Architecture & State Management
- **Domain Models**: `Sale`, `SaleDetail`, `CustomerPayment`, `InvoiceSummary`.
- **Repositories**: `SalesRepository`, `CustomerPaymentRepository`.
- **Controllers & Providers**:
  - `salesFormControllerProvider`: StateNotifier managing draft sales order lines, real-time total recalculations, and customer credit limit checks.
  - `salesListControllerProvider`: AsyncNotifier handling list filtering, search, and pagination.
  - `salesDetailProvider(id)`: Combines sale header, line items, payments, and delivery fulfillment status.
  - `customerPaymentControllerProvider`: Manages customer payment submissions and updates invoice payment status.

---

## 5. Form Validation & Business Rules
- **Line Items Validation**: Must contain at least 1 finished good item with `Quantity > 0` and `UnitPrice > 0`.
- **Customer Credit Limit Check**: If the order total exceeds the customer's remaining available credit (`CreditLimit - OutstandingBalance`), display an explicit warning dialog requiring confirmation.
- **Stock Availability Alert**: If ordered quantity > current warehouse stock for any item, show a warning badge ("Exceeds current stock: X available").
- **Auto-Calculations**:
  - `Subtotal = sum(Quantity * UnitPrice - Discount)`
  - `TotalAmount = Subtotal + Tax + TransportCharge`
- **Customer Payment Balance**: Payment receipt amount cannot exceed remaining unpaid balance on the invoice.

---

## 6. Edge Cases & Failure Modes
- **Zero Quantity / Negative Prices**: Strict client and server validation blocking negative numbers.
- **Customer Deactivation**: Prevent creating new sales orders for deactivated customer accounts.
- **Concurrent Order Placement**: Verify final stock before dispatching goods.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `SalesCalculatorTest`: Tax, line discounts, transport charges, and grand total computations.
  - `CreditLimitValidatorTest`: Correct warning trigger when order value exceeds available customer credit.
  - `SalesRepositoryTest`: Serialization of sales orders and payment receipts against mocked APIs.
- [ ] **Widget Tests**:
  - `SalesFormScreenTest`: Adding line items dynamically updates the total summary card.
  - `CustomerPaymentDialogTest`: Entering payment amount and method triggers receipt creation.
- [ ] **Integration Test**:
  - Create Sales Order -> Add 2 Finished Good line items -> Submit -> Record Customer Payment -> Verify invoice status changes from `PENDING` to `PAID`.

---

## 💬 Antigravity Agent Resolution & Verification Comments
- **Reviewer**: `Antigravity Agent`
- **Label**: `[Status: Verified & Resolved]`, `[Feature: Complete]`
- **Resolution**:
  - `SalesRepository` and `CustomerPaymentRepository` are wired to `/api/sales` and `/api/customer-payments`.
  - GST tax calculations, invoice balances, and overdue status logic verified.
