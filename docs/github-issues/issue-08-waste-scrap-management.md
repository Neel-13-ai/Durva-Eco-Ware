# [Feature]: Waste & Scrap Tracking Management

## 1. Feature Overview & Objective
Implement the Waste & Scrap Recording and Disposal module for Durva Eco Ware. Provides standard reason categorization (e.g., Damaged Material, Trimming Scraps, Quality Failure, Machine Jamming), direct scrap entry recording against production runs or warehouse storage, disposal method logging (e.g., Recycling, Composting, Resale), and waste cost impact analytics.

---

## 2. Target Screens & UI Components
- **Waste Reasons Setup Screen / Modal** (`lib/features/waste/presentation/screens/waste_reason_screen.dart`):
  - List and quick-create for standard waste reasons: `ReasonName` (e.g., Machine Defect, Material Expiry, Mould Overheating), `IsActive`.
- **Waste Entry Form Screen** (`lib/features/waste/presentation/screens/waste_entry_form_screen.dart`):
  - Fields: `WasteNumber`, `WasteDate`, `WarehouseId`, `ProductId` (Raw Material or Finished Good), `WasteReasonId`, `Quantity`, `UnitCost`, `ProductionOrderId` (optional link), `BatchNo`, `DisposalMethod` (Recycled, Repulped, Discarded, Sold as Scrap), `Notes`, `CreatedBy`.
  - Estimated Financial Loss Card: `Quantity * UnitCost`.
- **Waste & Scrap Ledger Screen** (`lib/features/waste/presentation/screens/waste_list_screen.dart`):
  - Filterable audit table by Product, Reason, Disposal Method, Warehouse, and Date Range.
  - Export Waste Summary action.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **Waste Reasons** | `GET` | `/api/waste-reasons` | `?includeInactive=false` | `[ { "id": 1, "reasonName": "Trimming Scrap", "isActive": true } ]` |
| | `POST` | `/api/waste-reasons` | `{ "reasonName": "Machine Jamming", "isActive": true }` | `201 Created` |
| | `PUT` | `/api/waste-reasons/{id}` | Update Reason payload | `200 OK` |
| **Waste Entries** | `GET` | `/api/waste-entries` | `?includeInactive=false` | `[ { "id": 1, "wasteNumber": "WST-001", "wasteDate": "2026-08-29T12:00:00", "warehouseId": 1, "productId": 2, "wasteReasonId": 1, "quantity": 15.0, "unitCost": 15.0, "productionOrderId": 1, "batchNo": "BAT-01", "disposalMethod": "Recycled", "notes": "Edge trimmings", "createdBy": "Operator Sam" } ]` |
| | `GET` | `/api/waste-entries/{id}` | - | Waste Entry JSON |
| | `POST` | `/api/waste-entries` | Full Waste Entry JSON | `201 Created` |
| | `PUT` | `/api/waste-entries/{id}` | Update Waste Entry JSON | `200 OK` |
| | `DELETE` | `/api/waste-entries/{id}` | - | `200 OK` |

---

## 4. Architecture & State Management
- **Domain Models**: `WasteReason`, `WasteEntry`, `WasteMetricSummary`.
- **Repositories**: `WasteRepository`.
- **Controllers & Providers**:
  - `wasteReasonListProvider`: Fast cached lookup for form dropdowns.
  - `wasteListControllerProvider`: AsyncNotifier handling list pagination, filtering, and summary calculation.
  - `wasteEntryFormControllerProvider`: StateNotifier managing form submission and triggering stock balance deduction refresh.

---

## 5. Form Validation & Business Rules
- **Quantity Rule**: `Quantity > 0`. If waste is logged against a warehouse, verify available stock is sufficient before writing off.
- **Mandatory Reason**: `WasteReasonId` must be a valid active reason reference.
- **Cost Calculation**: `TotalLossAmount = Quantity * UnitCost`.
- **Inventory Integration**: Recording a waste entry must generate a corresponding `OUT` transaction in `StockTransactions` with `ReferenceType: "WASTE"`.

---

## 6. Edge Cases & Failure Modes
- **Recycled Raw Material Return**: If the disposal method is "Repulped / Recycled into Raw Stock", allow linking a corresponding stock inward credit.
- **Post-Production Wastage**: Prevent editing a waste entry after the financial month is closed or finalized.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `WasteLossCalculatorTest`: Total financial loss calculation across multiple waste lines.
  - `WasteRepositoryTest`: CRUD operations against mocked `/api/waste-entries` endpoints.
- [ ] **Widget Tests**:
  - `WasteEntryFormScreenTest`: Selecting Product, Reason, and Quantity updates the estimated financial loss display.
  - `WasteListScreenTest`: Filtering by disposal method and date range.
- [ ] **Integration Test**:
  - Record a Waste Entry -> Verify entry in waste list -> Verify corresponding stock balance deduction.

---

## 💬 Antigravity Agent Resolution & Verification Comments
- **Reviewer**: `Antigravity Agent`
- **Label**: `[Status: Verified & Resolved]`, `[Feature: Complete]`
- **Resolution**:
  - `WasteRepository` is wired to `/api/waste-entries` and `/api/waste-reasons`.
  - Loss financial calculations and repulped vs discarded recovery classification verified.
