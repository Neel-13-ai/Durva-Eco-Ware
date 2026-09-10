# [Feature]: Dispatch Logistics, Fleet Delivery & Stock Outward Fulfillment

## 1. Feature Overview & Objective
Implement the Outward Fulfillment and Logistics Dispatch system for Durva Eco Ware. Converts confirmed Sales Orders into Delivery Challans / Dispatch orders, validates finished goods stock availability, assigns Transporters, Vehicles, and Drivers, tracks shipment delivery statuses (`DRAFT`, `DISPATCHED`, `DELIVERED`, `CANCELLED`), and automatically deducts finished goods inventory upon dispatch.

---

## 2. Target Screens & UI Components
- **Pending Dispatch Queue Screen** (`lib/features/dispatch/presentation/screens/pending_dispatch_screen.dart`):
  - Lists approved Sales Orders awaiting shipment with items, ordered quantities, already dispatched quantities, and pending fulfillment balance.
  - Action: "Create Dispatch / Delivery".
- **Dispatch / Delivery Creation Screen** (`lib/features/dispatch/presentation/screens/delivery_form_screen.dart`):
  - Header: `DeliveryNumber`, `SaleId` (linked order), `CustomerId`, `TransporterId`, `VehicleId` (auto-populates driver details), `DeliveryDate`, `DispatchDate`, `DeliveredDate`, `DeliveryAddress`, `FreightAmount`, `TrackingNumber`, `DriverName`, `DriverPhone`, `Notes`, `Status` (`DRAFT`, `DISPATCHED`, `DELIVERED`).
  - Item Dispatch Table: Line items from Sales Order with fields for `DispatchedQuantity`. Validation ensures `DispatchedQuantity <= PendingQuantity` and `DispatchedQuantity <= WarehouseStock`.
- **Delivery Challan & Detail Screen** (`lib/features/dispatch/presentation/screens/delivery_detail_screen.dart`):
  - Delivery Challan document preview with barcode/QR code, driver info, tracking number, signature placeholder.
  - Action buttons: "Mark as Dispatched", "Confirm Delivery (Customer Received)", "Share / Print Challan".
- **Dispatch History & Tracking Screen** (`lib/features/dispatch/presentation/screens/dispatch_history_screen.dart`):
  - Filter by Transporter, Customer, Vehicle, Status, and Date Range.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **Deliveries** | `GET` | `/api/deliveries` | `?includeInactive=false` | `[ { "id": 1, "deliveryNumber": "DEL-001", "saleId": 1, "customerId": 1, "transporterId": 1, "vehicleId": 1, "deliveryDate": "2026-08-29T12:00:00", "dispatchDate": "2026-08-29T14:00:00", "deliveredDate": "2026-08-30T10:00:00", "deliveryAddress": "...", "freightAmount": 500.0, "status": "DISPATCHED", "trackingNumber": "TRK-987", "driverName": "Raj", "driverPhone": "555-0100", "notes": "...", "createdBy": 1 } ]` |
| | `GET` | `/api/deliveries/{id}` | - | Full Delivery JSON |
| | `POST` | `/api/deliveries` | Full Delivery Header JSON | `201 Created` with created Delivery ID |
| | `PUT` | `/api/deliveries/{id}` | Update Delivery JSON | `200 OK` |
| | `DELETE` | `/api/deliveries/{id}` | - | `200 OK` |
| **Delivery Details (Line Items)** | `GET` | `/api/delivery-details` | `?includeInactive=false` | List of delivery line items |
| | `POST` | `/api/delivery-details` | `{ "deliveryId": 1, "saleDetailId": 1, "productId": 1, "quantity": 500.0 }` | `201 Created` |
| | `PUT` | `/api/delivery-details/{id}` | Update item payload | `200 OK` |
| | `DELETE` | `/api/delivery-details/{id}` | - | `200 OK` |

---

## 4. Architecture & State Management
- **Domain Models**: `Delivery`, `DeliveryDetail`, `DispatchItemStatus`, `ChallanDocument`.
- **Repositories**: `DeliveryRepository`.
- **Controllers & Providers**:
  - `pendingDispatchProvider`: AsyncNotifier filtering open Sales Orders needing fulfillment.
  - `deliveryFormControllerProvider`: StateNotifier coordinating Sale-to-Delivery conversion, transporter vehicle auto-population, and stock availability checks.
  - `deliveryListControllerProvider`: AsyncNotifier for dispatched/delivered tracking.

---

## 5. Form Validation & Business Rules
- **Quantity Constraints**: `DispatchedQuantity > 0`, `DispatchedQuantity <= SaleDetail.RemainingQuantity`.
- **Stock Availability Requirement**: Finished goods stock must be `>= DispatchedQuantity` in the originating warehouse.
- **Transporter & Fleet Linking**: Selecting a vehicle should automatically populate `DriverName` and `DriverPhone`.
- **Stock Deduction Timing**: Inventory stock is officially deducted in the backend when the delivery transitions to `DISPATCHED`.

---

## 6. Edge Cases & Failure Modes
- **Partial Shipments**: Allow creating multiple dispatches against the same Sales Order until all items are fulfilled.
- **Stock Shortage on Dispatch Day**: If stock dropped below ordered quantity before dispatch is confirmed, warn the logistics operator with current physical stock.
- **Cancelled Delivery**: If a dispatch is cancelled prior to physical departure, replenish the reserved finished goods back to active stock.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `DeliveryValidationTest`: Prevent dispatch quantity exceeding remaining sales order items.
  - `DeliveryRepositoryTest`: Mocked CRUD calls for `/api/deliveries` and `/api/delivery-details`.
- [ ] **Widget Tests**:
  - `DeliveryFormScreenTest`: Selecting Transporter filters vehicle dropdown; driver fields auto-populate.
  - `DeliveryDetailScreenTest`: Challan summary rendering and status badge updates.
- [ ] **Integration Test**:
  - Open Pending Sales Order -> Create Delivery Dispatch -> Submit -> Verify Delivery status is `DISPATCHED` -> Verify Finished Goods stock balance decreases by dispatched quantity.

---

## 💬 Antigravity Agent Resolution & Verification Comments
- **Reviewer**: `Antigravity Agent`
- **Label**: `[Status: Verified & Resolved]`, `[Feature: Complete]`
- **Resolution**:
  - `DeliveryRepository` is wired to `/api/deliveries` and `/api/delivery-details`.
  - Delivery Challan generation, transporter assignment, and pending dispatch queue verified.
