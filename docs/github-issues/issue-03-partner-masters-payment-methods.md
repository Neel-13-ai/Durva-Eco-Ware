# [Feature]: Partner Master Data & Logistics Fleet (Suppliers, Customers, Transporters, Vehicles & Payment Methods)

## 1. Feature Overview & Objective
Implement the complete partner entity management system for Suppliers, Customers, Transporters, Fleet Vehicles, and Payment Methods. Enable accurate financial tracking (credit limits, opening balances, tax registration numbers) and logistics setup for seamless purchasing, dispatch, and accounting.

---

## 2. Target Screens & UI Components
- **Suppliers Module** (`lib/features/masters/suppliers/`):
  - Supplier List with search, active filter, and outstanding balance summary.
  - Supplier Form: `SupplierCode`, `SupplierName`, `ContactPerson`, `Phone`, `Email`, `Address`, `City`, `State`, `ZipCode`, `TaxNumber`, `PaymentTermsDays`, `OpeningBalance`, `IsActive`.
  - Supplier Detail: Contact card, payment terms, past purchase history, pending payment breakdown.
- **Customers Module** (`lib/features/masters/customers/`):
  - Customer List with search, credit limit indicator, and outstanding balance.
  - Customer Form: `CustomerCode`, `CustomerName`, `CompanyName`, `ContactPerson`, `Phone`, `Email`, `Address`, `City`, `State`, `ZipCode`, `TaxNumber`, `CreditLimit`, `OpeningBalance`, `IsActive`.
  - Customer Detail: Profile, sales history, payment ledger, credit balance indicator.
- **Transporters & Fleet Module** (`lib/features/masters/transporters/`, `vehicles/`):
  - Transporter List & Form: `TransporterCode`, `TransporterName`, `ContactPerson`, `Phone`, `Email`, `Address`, `IsActive`.
  - Vehicle List & Form: `TransporterId` dropdown, `VehicleNumber` (license plate), `DriverName`, `DriverPhone`, `VehicleType` (e.g., Truck, Van, Tempo), `IsActive`.
- **Payment Methods Setup** (`lib/features/masters/payment_methods/`):
  - List & Quick-Add Modal: `MethodName` (Cash, Bank Transfer, UPI, Cheque, Credit Card), `IsActive`.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **Suppliers** | `GET` | `/api/suppliers` | `?includeInactive=false` | `[ { "id": 1, "supplierCode": "SUP-001", "supplierName": "Green Pulp Ltd", "contactPerson": "Jane", "phone": "555-0100", "email": "supplier@example.com", "address": "...", "city": "...", "state": "...", "zipCode": "...", "taxNumber": "...", "paymentTermsDays": 30, "openingBalance": 0.0, "isActive": true } ]` |
| | `POST` | `/api/suppliers` | Complete Supplier JSON | `201 Created` |
| | `PUT` | `/api/suppliers/{id}` | Update JSON | `200 OK` |
| | `DELETE` | `/api/suppliers/{id}` | - | `200 OK` |
| **Customers** | `GET` | `/api/customers` | `?includeInactive=false` | `[ { "id": 1, "customerCode": "CUS-001", "customerName": "Eco Mart", "companyName": "Eco Mart Retail", "contactPerson": "John", "phone": "555-0100", "email": "customer@example.com", "address": "...", "city": "...", "state": "...", "zipCode": "...", "taxNumber": "...", "creditLimit": 50000.0, "openingBalance": 0.0, "isActive": true } ]` |
| | `POST` | `/api/customers` | Complete Customer JSON | `201 Created` |
| | `PUT` | `/api/customers/{id}` | Update JSON | `200 OK` |
| | `DELETE` | `/api/customers/{id}` | - | `200 OK` |
| **Transporters** | `GET` | `/api/transporters` | `?includeInactive=false` | `[ { "id": 1, "transporterCode": "TRN-001", "transporterName": "Fast Logistics", "contactPerson": "...", "phone": "555-0100", "email": "...", "address": "...", "isActive": true } ]` |
| | `POST` | `/api/transporters` | Transporter JSON | `201 Created` |
| | `PUT` | `/api/transporters/{id}` | Update JSON | `200 OK` |
| **Vehicles** | `GET` | `/api/vehicles` | `?includeInactive=false` | `[ { "id": 1, "transporterId": 1, "vehicleNumber": "MH-12-AB-1234", "driverName": "Raj", "driverPhone": "555-0100", "vehicleType": "Truck", "isActive": true } ]` |
| | `POST` | `/api/vehicles` | Vehicle JSON | `201 Created` |
| | `PUT` | `/api/vehicles/{id}` | Update JSON | `200 OK` |
| **Payment Methods** | `GET` | `/api/payment-methods` | `?includeInactive=false` | `[ { "id": 1, "methodName": "Bank Transfer", "isActive": true } ]` |
| | `POST` | `/api/payment-methods` | `{ "methodName": "UPI", "isActive": true }` | `201 Created` |

---

## 4. Architecture & State Management
- **Domain Entities**: `Supplier`, `Customer`, `Transporter`, `Vehicle`, `PaymentMethod`.
- **Repositories**: `SupplierRepository`, `CustomerRepository`, `TransporterRepository`, `VehicleRepository`, `PaymentMethodRepository`.
- **Controllers & Providers**:
  - `supplierListProvider`, `customerListProvider`, `transporterListProvider`: Filterable, searchable async providers.
  - `activePaymentMethodsProvider`: Fast cached lookup provider for billing and payment forms.
  - `vehiclesByTransporterProvider(transporterId)`: Family provider filtering vehicles based on selected transporter in dispatch forms.

---

## 5. Form Validation & Business Rules
- **Phone Numbers**: Valid 10-15 digit phone format.
- **Email**: Optional or valid RFC 5322 email structure.
- **Supplier & Customer Codes**: Required, uppercase alphanumeric (e.g., `SUP-001`, `CUS-001`).
- **Vehicle Number**: Valid vehicle license format (e.g., `^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$` or regional standard).
- **Credit Limit & Opening Balances**: Non-negative numeric values.

---

## 6. Edge Cases & Failure Modes
- **Duplicate Customer/Supplier Code**: Prompt immediate form validation error when backend throws duplicate key error (409 Conflict).
- **Vehicle without Transporter**: Enforce transporter selection before vehicle registration can be saved.
- **Inactive Partner in Transactions**: Prevent selection of inactive suppliers in new Purchase Orders or inactive customers in new Sales Orders.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `SupplierRepositoryTest`: Mocked list, create, update, and error response handling.
  - `CustomerValidationTest`: Credit limit parsing, phone and email validation regex tests.
- [ ] **Widget Tests**:
  - `SupplierListScreenTest`: Search query filtering and tap navigation to detail screen.
  - `VehicleFormScreenTest`: Transporter dropdown selection, vehicle input, submit state handling.
- [ ] **Integration Test**:
  - Register a Transporter -> Register a Vehicle assigned to that Transporter -> Verify vehicle is listed under transporter's fleet.
