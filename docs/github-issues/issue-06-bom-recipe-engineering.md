# [Feature]: Bill of Materials (BOM) & Recipe Engineering

## 1. Feature Overview & Objective
Build the Bill of Materials (BOM) and Recipe Engineering system for Durva Eco Ware. Enables production planners to define exact raw material formulas required to produce finished products, including version control, batch sizing, scrap percentage allowances, unit cost estimations, and effective date validity periods.

---

## 2. Target Screens & UI Components
- **BOM List Screen** (`lib/features/production/bom/presentation/screens/bom_list_screen.dart`):
  - List of BOMs showing BOM Code, Finished Product Name, Version Number, Batch Size, Status (`Active` / `Draft` / `Archived`), and Effective Date range.
  - Search by BOM Code or Finished Product Name.
- **BOM Recipe Builder / Form Screen** (`lib/features/production/bom/presentation/screens/bom_form_screen.dart`):
  - Header: `BOMCode`, `FinishedProductId` (dropdown of Products where `ProductType == FINISHED_GOOD`), `VersionNo` (e.g., `v1.0`, `v2.1`), `BatchSize` (standard yield, e.g., 1000 units), `EffectiveFrom`, `EffectiveTo`, `Notes`, `IsActive`.
  - Raw Material Components Table: Dynamic rows to add Raw Materials (`RawMaterialId`, `QuantityRequired`, `ScrapPercent`, `UnitCost`, `Notes`).
  - Recipe Cost Estimation Card: Auto-calculates total raw material cost per batch and estimated cost per single finished good unit.
- **BOM Detail View** (`lib/features/production/bom/presentation/screens/bom_detail_screen.dart`):
  - Read-only visual recipe diagram, total component breakdown, scrap percentages, and production run history.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **BOM Headers** | `GET` | `/api/b-o-m-headers` | `?includeInactive=false` | `[ { "id": 1, "bomCode": "BOM-BWL-001", "finishedProductId": 1, "versionNo": "v1.0", "batchSize": 1000.0, "isActive": true, "effectiveFrom": "2026-08-29T12:00:00", "effectiveTo": "2027-08-29T12:00:00", "notes": "Standard 500ml bowl recipe", "createdBy": 1 } ]` |
| | `GET` | `/api/b-o-m-headers/{id}` | - | BOM Header JSON |
| | `POST` | `/api/b-o-m-headers` | Full BOM Header JSON | `201 Created` with created BOM ID |
| | `PUT` | `/api/b-o-m-headers/{id}` | Update BOM Header | `200 OK` |
| | `DELETE` | `/api/b-o-m-headers/{id}` | - | `200 OK` |
| **BOM Details (Components)** | `GET` | `/api/b-o-m-details` | `?includeInactive=false` | `[ { "id": 1, "bomId": 1, "rawMaterialId": 2, "quantityRequired": 120.0, "scrapPercent": 5.0, "unitCost": 15.0, "notes": "Bagasse fiber" } ]` |
| | `POST` | `/api/b-o-m-details` | Component JSON | `201 Created` |
| | `PUT` | `/api/b-o-m-details/{id}` | Update component | `200 OK` |
| | `DELETE` | `/api/b-o-m-details/{id}` | - | `200 OK` |

---

## 4. Architecture & State Management
- **Domain Models**: `BOMHeader`, `BOMDetail`, `BOMRecipeSummary`.
- **Repositories**: `BOMRepository`.
- **Controllers & Providers**:
  - `bomListControllerProvider`: AsyncNotifier for listing and filtering BOM recipes.
  - `bomFormControllerProvider`: StateNotifier managing draft BOM header and dynamic list of component items, calculating total batch cost reactively.
  - `activeBOMByProductProvider(productId)`: Computes the current active, effective BOM recipe for a finished product to auto-populate Production Orders.

---

## 5. Form Validation & Business Rules
- **Product Type Restriction**: The finished product must strictly be of type `FINISHED_GOOD`.
- **Raw Material Components**: Must contain at least 1 raw material item. All component products must be of type `RAW_MATERIAL`.
- **Positive Quantities**: `BatchSize > 0`, `QuantityRequired > 0`, `ScrapPercent >= 0 and <= 100`.
- **Unique Versioning**: No two active BOMs for the same Finished Product should have overlapping effective dates with active status.
- **Cost Calculation Formula**:
  - Item Effective Quantity = `QuantityRequired * (1 + ScrapPercent / 100)`
  - Total Item Cost = `Effective Quantity * UnitCost`
  - Total Batch Cost = `Sum of all Total Item Costs`
  - Cost Per Unit = `Total Batch Cost / BatchSize`

---

## 6. Edge Cases & Failure Modes
- **Circular Dependency**: Prevent adding the finished product itself as a raw material component.
- **Duplicate Raw Material in Same BOM**: Prompt a merge or validation warning if the user adds the same Raw Material in multiple lines.
- **Deactivated Material Component**: Warn user if a raw material in an existing BOM has been deactivated in the Master data.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `BOMCostCalculatorTest`: Unit and batch cost calculations including scrap percentage allowance.
  - `BOMValidationTest`: Rejection of zero batch size or invalid raw material component assignments.
- [ ] **Widget Tests**:
  - `BOMFormScreenTest`: Adding raw material rows, scrap percentage changes dynamically updating estimated cost card.
  - `BOMListScreenTest`: Search query filtering and status indicator chip display.
- [ ] **Integration Test**:
  - Create a new BOM for a Finished Product with 3 Raw Material components -> Submit -> Verify it is retrievable and calculated cost is accurate.
