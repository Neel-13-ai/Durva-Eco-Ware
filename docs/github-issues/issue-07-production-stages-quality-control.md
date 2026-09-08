# [Feature]: Production Management, Multi-Stage Tracking & Quality Control

## 1. Feature Overview & Objective
Implement the comprehensive Manufacturing Execution System (MES) for Durva Eco Ware. Covers Production Planning & Order scheduling, Raw Material Requisition/Issue against BOM recipes, Multi-Stage Production Tracking (Mixing, Moulding, Drying, Trimming, Packing), Final Output Recording (Good vs Rejected units with batch numbers), and Quality Control (QC Inspection with Pass/Fail gating).

---

## 2. Target Screens & UI Components
- **Production Orders List Screen** (`lib/features/production/presentation/screens/production_order_list_screen.dart`):
  - Filter by Status (`DRAFT`, `PLANNED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`), Warehouse, Shift, Date Range.
  - Progress bar per order indicating stage completion percentage.
- **Production Order Setup / Create Screen** (`lib/features/production/presentation/screens/production_order_form_screen.dart`):
  - Fields: `ProductionNumber`, `BOMId` (auto-loads formula), `FinishedProductId`, `WarehouseId`, `ProductionDate`, `ShiftName` (Morning, Evening, Night), `PlannedQty`, `Notes`.
  - Material Requisition Preview: Displays required raw materials calculated from BOM recipe * planned quantity with real-time stock availability check.
- **Material Issue Requisition Screen** (`lib/features/production/presentation/screens/production_material_issue_screen.dart`):
  - Table of required materials vs actual issued quantities (`RequiredQty`, `IssuedQty`, `BatchNo`, `UnitCost`).
  - "Issue Materials" confirmation (deducts raw material stock).
- **Multi-Stage Execution Tracker Screen** (`lib/features/production/presentation/screens/production_stage_tracker_screen.dart`):
  - Interactive stage timeline showing configured stages (e.g., 1. Raw Prep -> 2. Thermoforming -> 3. Trimming -> 4. Quality -> 5. Packing).
  - Actions per stage: "Start Stage", "Log Remarks", "Complete Stage" with timestamp capture.
- **Production Output Recording Screen** (`lib/features/production/presentation/screens/production_output_form_screen.dart`):
  - Fields: `ProducedQty`, `GoodQty`, `RejectQty`, `BatchNo`, `UnitCost`, `OutputDate`, `Notes`.
  - "Confirm Output" action: Auto-increments Finished Goods inventory with verified Good Quantity.
- **Quality Control (QC) Inspection Screen** (`lib/features/production/presentation/screens/quality_check_form_screen.dart`):
  - Fields: `ProductionOrderId`, `ProductId`, `BatchNo`, `SampleQty`, `PassedQty`, `FailedQty`, `Result` (`PASS`, `FAIL`, `REWORK`), `CheckedBy`, `Remarks`.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **Production Stages** | `GET` | `/api/production-stages` | `?includeInactive=false` | `[ { "id": 1, "stageName": "Thermoforming", "sequenceNo": 1, "isActive": true } ]` |
| | `POST` | `/api/production-stages` | `{ "stageName": "Packing", "sequenceNo": 5, "isActive": true }` | `201 Created` |
| **Production Orders** | `GET` | `/api/production-orders` | `?includeInactive=false` | `[ { "id": 1, "productionNumber": "PROD-001", "bomId": 1, "finishedProductId": 1, "warehouseId": 1, "productionDate": "2026-08-29T12:00:00", "shiftName": "Morning", "plannedQty": 5000.0, "status": "IN_PROGRESS", ... } ]` |
| | `GET` | `/api/production-orders/{id}` | - | Full Production Order JSON |
| | `POST` | `/api/production-orders` | Full Production Order JSON | `201 Created` |
| | `PUT` | `/api/production-orders/{id}` | Update Order JSON | `200 OK` |
| **Material Issues** | `GET` | `/api/production-material-issues` | `?includeInactive=false` | List of material issues |
| | `POST` | `/api/production-material-issues` | `{ "productionOrderId": 1, "productId": 2, "requiredQty": 500.0, "issuedQty": 500.0, "unitCost": 15.0, "batchNo": "RM-BAT-01" }` | `201 Created` |
| **Stage Entries** | `GET` | `/api/production-stage-entries` | `?includeInactive=false` | List of stage logs |
| | `POST` | `/api/production-stage-entries` | `{ "productionOrderId": 1, "stageId": 1, "startTime": "2026-08-29T08:00:00", "endTime": "2026-08-29T10:00:00", "status": "COMPLETED", "remarks": "No defects observed" }` | `201 Created` |
| **Production Outputs** | `GET` | `/api/production-outputs` | `?includeInactive=false` | List of production outputs |
| | `POST` | `/api/production-outputs` | `{ "productionOrderId": 1, "productId": 1, "producedQty": 5000.0, "goodQty": 4900.0, "rejectQty": 100.0, "batchNo": "FG-2026-001", "unitCost": 3.5, "outputDate": "2026-08-29T16:00:00" }` | `201 Created` |
| **Quality Checks** | `GET` | `/api/quality-checks` | `?includeInactive=false` | List of QC records |
| | `POST` | `/api/quality-checks` | `{ "productionOrderId": 1, "productId": 1, "batchNo": "FG-2026-001", "sampleQty": 50.0, "passedQty": 49.0, "failedQty": 1.0, "result": "PASS", "checkedBy": "Inspector Dave", "remarks": "Passed food-grade test" }` | `201 Created` |

---

## 4. Architecture & State Management
- **Domain Models**: `ProductionOrder`, `ProductionStage`, `ProductionStageEntry`, `ProductionMaterialIssue`, `ProductionOutput`, `QualityCheck`.
- **Repositories**: `ProductionRepository`, `QualityCheckRepository`.
- **Controllers & Providers**:
  - `productionOrderListControllerProvider`: Filterable, searchable async list provider.
  - `productionOrderDetailsProvider(orderId)`: Aggregates order header, material issues, stage entries, outputs, and QC inspection status.
  - `productionExecutionControllerProvider`: State notifier coordinating multi-step execution (Material Issue -> Stage Progress -> QC -> Output Finalization).

---

## 5. Form Validation & Business Rules
- **Material Availability Check**: When planning a production order, verify if `rawMaterial.currentStock >= requiredMaterialQty`. Warn if stock is deficient.
- **Output Balance Rule**: `ProducedQty == GoodQty + RejectQty`.
- **QC Gatekeeping Rule**: Finished goods inventory output cannot be confirmed without an approved Quality Check record where `Result == PASS` (or explicit manager override).
- **Sequential Stage Progression**: Stage entries should strictly progress in order of `sequenceNo`.

---

## 6. Edge Cases & Failure Modes
- **Excess Scrap / Rejection**: If `RejectQty` exceeds allowable scrap tolerance (from BOM), prompt user to record a mandatory Waste Entry log.
- **Interrupted Production Shift**: Support pausing and resuming stage entries without losing timestamp duration calculations.
- **Batch Code Collision**: Auto-generate unique batch codes (`FG-YYYYMMDD-ORDID`) with manual edit option.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `ProductionOrderCalculatorTest`: Calculate required raw materials from BOM batch size multiplier.
  - `OutputBalanceValidationTest`: Verify rejection when `ProducedQty != GoodQty + RejectQty`.
  - `ProductionRepositoryTest`: Mock serialization of all 6 production controller endpoints.
- [ ] **Widget Tests**:
  - `ProductionStageTrackerScreenTest`: Visual stage transition on tapping "Complete Stage".
  - `QualityCheckFormScreenTest`: Pass/Fail radio selector and sample validation checks.
- [ ] **Integration Test**:
  - Create Production Order -> Issue Materials -> Advance through all stages -> Record QC Pass -> Record Finished Goods Output -> Verify Finished Goods stock increases.
