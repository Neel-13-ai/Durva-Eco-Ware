# Durva Eco Ware — Application Screens & API Integration Inventory

**Document Version:** 1.1  
**Generated Date:** 2026-10-03  
**Application:** Durva Eco Ware (Manufacturing Stock Management App)  
**Total Screens Implemented:** 61  
**Total Epics / Modules:** 12  
**Total Backend APIs Mapped:** 202 across 82 endpoints  

---

## Executive Overview

This document provides a comprehensive inventory of all **61 user-interface screens** in the Durva Eco Ware application, detailing their routes, business purpose, UI components, and all backend API endpoints integrated into each screen.

```text
DURVA ECO WARE CORE LIFECYCLE
Raw Material Setup (Masters) ──► Purchasing & GRN Inwarding ──► Stock & Inventory
                                                                   │
                                                                   ▼
Reports & Analytics ◄── Dispatch & Logistics ◄── Sales & Invoicing ◄── BOM & Production Floor
```

---

## 1. Summary by Epic / Feature Module

| Epic # | Feature Module | Screen Count | Key Responsibilities |
|---|---|:---:|---|
| **01** | **Auth, Security & System Settings** | 8 | Authentication, password recovery, RBAC, users, app & company configs, audit logs, alerts |
| **02** | **Core Master Data** | 8 | Products, Raw Materials, Categories, Units of Measure, Warehouses, Sequences |
| **03** | **Partners & Fleet Logistics** | 8 | Suppliers, Customers, Transporters, Fleet Vehicles, Payment Methods |
| **04** | **Purchasing & Inbound Inwarding** | 6 | Purchase orders, PO lines, physical Goods Receipt Notes (GRN), Vendor payouts, Payment receipts |
| **05** | **Inventory & Stock Management** | 2 | Warehouse stock balances, lot/batch tracking, movement journals |
| **06** | **BOM & Recipe Engineering** | 3 | Bill of Materials (BOM), raw material consumption formulas, recipe revisions |
| **07** | **Production Management & QC** | 6 | Job orders, stage tracking (Extrusion, Forming, Trimming), Material issue, Output, QC |
| **08** | **Waste & Scrap Management** | 3 | Defect logging, scrap recording, scrap reason configurations |
| **09** | **Sales & Customer Invoicing** | 6 | Sales orders, invoices, tax breakdown, payment collections history & receipts |
| **10** | **Dispatch, Deliveries & Fleet** | 4 | Pending order queue, Delivery Challans, shipment tracking, delivery proof |
| **11** | **Expense Management** | 3 | Factory overheads, operational expenses, expense categories |
| **12** | **Operations Dashboard, Flow & Reports Hub** | 4 | Executive KPI dashboard, Interactive flow diagram, BI reports hub |

---

## 2. Complete Screen-by-Screen & API Integration Details

---

### 📦 Epic 01: Authentication, Security & Settings (7 Screens)

#### 1. SplashScreen
- **File:** `lib/features/auth/presentation/screens/splash_screen.dart`
- **Route:** `/`
- **Purpose:** Bootstraps application context, checks local hardware tokens, and verifies session authentication.
- **Integrated APIs:**
  - `GET /api/auth/me` *(Session verification & user context)*

#### 2. LoginScreen
- **File:** `lib/features/auth/presentation/screens/login_screen.dart`
- **Route:** `/login`
- **Purpose:** Authenticates superadmins, plant managers, and floor operators with username/password.
- **Integrated APIs:**
  - `POST /api/auth/login` *(Validates credentials and returns JWT Bearer token)*

#### 3. ForgotPasswordScreen
- **File:** `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- **Route:** `/forgot-password`
- **Purpose:** Initiates self-service password reset workflow for registered accounts.
- **Integrated APIs:**
  - `POST /api/auth/forgot-password` *(Requests reset token / OTP)*

#### 4. WelcomeScreen
- **File:** `lib/features/auth/presentation/screens/welcome_screen.dart`
- **Route:** Internal Widget / First-time Launch
- **Purpose:** Brand introduction and operational onboarding overview.
- **Integrated APIs:**
  - App state initialization & configuration verification

#### 5. UserManagementScreen
- **File:** `lib/features/auth/presentation/screens/user_management_screen.dart`
- **Route:** `/users`
- **Purpose:** Central administrator console to invite, edit, deactivate users, and reset employee passwords.
- **Integrated APIs:**
  - `GET /api/users` *(List all user accounts)*
  - `POST /api/users` *(Create new operator/manager account)*
  - `GET /api/users/{id}` *(Fetch user profile details)*
  - `PUT /api/users/{id}` *(Update user details and assigned roles)*
  - `DELETE /api/users/{id}` *(Deactivate or delete user account)*
  - `POST /api/users/change-password` *(Administrative password override)*

#### 6. AppSettingsScreen
- **File:** `lib/features/auth/presentation/screens/app_settings_screen.dart`
- **Route:** `/settings`
- **Purpose:** Configures company tax profile (GSTIN), default currency, UI theme, printer preferences, and security roles.
- **Integrated APIs:**
  - `GET /api/app-settings` *(Fetch application parameters)*
  - `PUT /api/app-settings/{id}` *(Update app parameters)*
  - `GET /api/company-settings` *(Fetch company tax and legal identity)*
  - `PUT /api/company-settings/{id}` *(Update company profile)*
  - `GET /api/roles` *(List RBAC security roles)*

#### 7. NotificationsScreen
- **File:** `lib/features/notifications/presentation/screens/notifications_screen.dart`
- **Route:** `/notifications`
- **Purpose:** Notification feed for low-stock thresholds, order approvals, and QC rejections.
- **Integrated APIs:**
  - `GET /api/notifications` *(List notification feed)*
  - `GET /api/notifications/{id}` *(Mark as read / view notification details)*

---

### 📦 Epic 02: Core Master Data (8 Screens)

#### 8. MasterEntryHubScreen
- **File:** `lib/features/masters/presentation/screens/master_entry_hub_screen.dart`
- **Route:** `/masters`
- **Purpose:** Master data menu hub directing users to Products, Categories, Units, Warehouses, and Numbering Sequences.
- **Integrated APIs:**
  - Master navigation orchestrator

#### 9. ProductListScreen
- **File:** `lib/features/masters/presentation/screens/products/product_list_screen.dart`
- **Route:** `/masters/products`
- **Purpose:** Searchable and filterable catalog of all raw materials, packaging supplies, and finished eco-ware goods.
- **Integrated APIs:**
  - `GET /api/products` *(List products with category & type filters)*
  - `DELETE /api/products/{id}` *(Delete product item)*

#### 10. ProductFormScreen
- **File:** `lib/features/masters/presentation/screens/products/product_form_screen.dart`
- **Route:** `/masters/products/new` & `/masters/products/:id/edit`
- **Purpose:** Form to create or edit product specifications, HSN/SAC code, GST tax rate, UOM, and standard unit cost.
- **Integrated APIs:**
  - `POST /api/products` *(Create new product/raw material)*
  - `PUT /api/products/{id}` *(Update product specifications)*
  - `GET /api/categories` *(Dropdown selection for categories)*
  - `GET /api/units` *(Dropdown selection for units)*

#### 11. ProductDetailScreen
- **File:** `lib/features/masters/presentation/screens/products/product_detail_screen.dart`
- **Route:** `/masters/products/:id`
- **Purpose:** Detailed view of product technical specs, reorder thresholds, inventory valuation, and supplier links.
- **Integrated APIs:**
  - `GET /api/products/{id}` *(Fetch single product by ID)*

#### 12. CategoryScreen
- **File:** `lib/features/masters/presentation/screens/categories/category_screen.dart`
- **Route:** `/masters/categories`
- **Purpose:** Category management table (Raw Materials, Semi-Finished, Finished Ware, Packaging).
- **Integrated APIs:**
  - `GET /api/categories` *(List item categories)*
  - `POST /api/categories` *(Create new category)*
  - `PUT /api/categories/{id}` *(Update category name/description)*
  - `DELETE /api/categories/{id}` *(Delete category)*

#### 13. UnitScreen
- **File:** `lib/features/masters/presentation/screens/units/unit_screen.dart`
- **Route:** `/masters/units`
- **Purpose:** Units of Measure (UOM) management table (KG, Gram, Metric Ton, Pieces, Boxes, Bundles).
- **Integrated APIs:**
  - `GET /api/units` *(List units)*
  - `POST /api/units` *(Create new unit)*
  - `PUT /api/units/{id}` *(Update unit code & symbol)*
  - `DELETE /api/units/{id}` *(Delete unit)*

#### 14. WarehouseScreen
- **File:** `lib/features/masters/presentation/screens/warehouses/warehouse_screen.dart`
- **Route:** `/masters/warehouses`
- **Purpose:** Factory storage locations, Silos, Raw Material Yards, and Finished Goods Warehouses.
- **Integrated APIs:**
  - `GET /api/warehouses` *(List factory warehouses)*
  - `POST /api/warehouses` *(Create storage warehouse)*
  - `PUT /api/warehouses/{id}` *(Update warehouse location/capacity)*
  - `DELETE /api/warehouses/{id}` *(Delete warehouse)*

#### 15. SequenceScreen
- **File:** `lib/features/masters/presentation/screens/sequences/sequence_screen.dart`
- **Route:** `/masters/sequences`
- **Purpose:** Auto-numbering sequence formatters (e.g. `PO-2026-0001`, `GRN-0001`, `INV-0001`, `DC-0001`).
- **Integrated APIs:**
  - `GET /api/document-sequences` *(List numbering sequences)*
  - `PUT /api/document-sequences/{id}` *(Update prefix, suffix, and next counter)*

---

### 📦 Epic 03: Partners & Fleet Logistics (8 Screens)

#### 16. SupplierListScreen
- **File:** `lib/features/partners/presentation/screens/suppliers/supplier_list_screen.dart`
- **Route:** `/partners/suppliers`
- **Purpose:** Supplier and vendor directory with contact numbers, balances, and search capabilities.
- **Integrated APIs:**
  - `GET /api/suppliers` *(List vendors)*
  - `DELETE /api/suppliers/{id}` *(Delete vendor)*

#### 17. SupplierFormScreen
- **File:** `lib/features/partners/presentation/screens/suppliers/supplier_form_screen.dart`
- **Route:** `/partners/suppliers/new` & `/partners/suppliers/:id/edit`
- **Purpose:** Create/Edit supplier profile, GSTIN, PAN, bank account details, and payment credit period.
- **Integrated APIs:**
  - `POST /api/suppliers` *(Create supplier)*
  - `PUT /api/suppliers/{id}` *(Update supplier)*

#### 18. CustomerListScreen
- **File:** `lib/features/partners/presentation/screens/customers/customer_list_screen.dart`
- **Route:** `/partners/customers`
- **Purpose:** Customer directory showing outstanding balances, credit limits, and contact info.
- **Integrated APIs:**
  - `GET /api/customers` *(List customers)*
  - `DELETE /api/customers/{id}` *(Delete customer)*

#### 19. CustomerFormScreen
- **File:** `lib/features/partners/presentation/screens/customers/customer_form_screen.dart`
- **Route:** `/partners/customers/new` & `/partners/customers/:id/edit`
- **Purpose:** Create/Edit customer records, shipping address, billing address, GSTIN, and credit terms.
- **Integrated APIs:**
  - `POST /api/customers` *(Create customer)*
  - `PUT /api/customers/{id}` *(Update customer)*

#### 20. TransporterListScreen
- **File:** `lib/features/partners/presentation/screens/transporters/transporter_list_screen.dart`
- **Route:** `/partners/transporters`
- **Purpose:** Logistics agencies and freight courier partner registry.
- **Integrated APIs:**
  - `GET /api/transporters` *(List transporters)*
  - `DELETE /api/transporters/{id}` *(Delete transporter)*

#### 21. TransporterFormScreen
- **File:** `lib/features/partners/presentation/screens/transporters/transporter_form_screen.dart`
- **Route:** `/partners/transporters/new` & `/partners/transporters/:id/edit`
- **Purpose:** Create/Edit transporter company, transporter ID, registration, and dispatch rate agreements.
- **Integrated APIs:**
  - `POST /api/transporters` *(Create transporter)*
  - `PUT /api/transporters/{id}` *(Update transporter)*

#### 22. VehicleListScreen
- **File:** `lib/features/partners/presentation/screens/vehicles/vehicle_list_screen.dart`
- **Route:** `/partners/vehicles`
- **Purpose:** Fleet truck and dispatch vehicle table with driver license and payload capacity info.
- **Integrated APIs:**
  - `GET /api/vehicles` *(List vehicles)*
  - `POST /api/vehicles` *(Add vehicle)*
  - `PUT /api/vehicles/{id}` *(Update vehicle info)*
  - `DELETE /api/vehicles/{id}` *(Remove vehicle)*

#### 23. PaymentMethodScreen
- **File:** `lib/features/partners/presentation/screens/payment_methods/payment_method_screen.dart`
- **Route:** `/partners/payment-methods`
- **Purpose:** Manage payment options (Bank Transfer/NEFT, UPI, Cheque, Cash, Credit Line).
- **Integrated APIs:**
  - `GET /api/payment-methods` *(List payment methods)*
  - `POST /api/payment-methods` *(Create payment method)*
  - `PUT /api/payment-methods/{id}` *(Update payment method)*

---

### 📦 Epic 04: Purchasing & Inbound Inwarding (5 Screens)

#### 24. PurchaseListScreen
- **File:** `lib/features/purchasing/presentation/screens/purchase_list_screen.dart`
- **Route:** `/purchases` (Main Tab 1)
- **Purpose:** Purchase Orders dashboard with status filters (Draft, Confirmed, Received, Paid).
- **Integrated APIs:**
  - `GET /api/purchases` *(List purchase orders)*
  - `GET /api/suppliers` *(Filter by supplier)*

#### 25. PurchaseOrderFormScreen
- **File:** `lib/features/purchasing/presentation/screens/purchase_order_form_screen.dart`
- **Route:** `/purchases/new`
- **Purpose:** Multi-item purchase order generation with rate calculations, taxes, and delivery date.
- **Integrated APIs:**
  - `POST /api/purchases` *(Create PO header)*
  - `POST /api/purchase-details` *(Create PO item lines)*
  - `GET /api/suppliers` *(Supplier selection)*
  - `GET /api/products` *(Raw material product selection)*

#### 26. PurchaseDetailScreen
- **File:** `lib/features/purchasing/presentation/screens/purchase_detail_screen.dart`
- **Route:** `/purchases/:id`
- **Purpose:** View PO line items, received vs pending quantities, and vendor payout status.
- **Integrated APIs:**
  - `GET /api/purchases/{id}` *(Fetch PO header)*
  - `GET /api/purchase-details` *(Fetch PO lines)*

#### 27. GoodsReceiptFormScreen
- **File:** `lib/features/purchasing/presentation/screens/goods_receipt_form_screen.dart`
- **Route:** `/purchases/:id/grn`
- **Purpose:** Inward raw materials, record physical GRN, verify weighbridge count, and allocate to warehouse.
- **Integrated APIs:**
  - `POST /api/goods-receipts` *(Create GRN header)*
  - `POST /api/goods-receipt-details` *(Create GRN inwarded lines)*
  - `GET /api/warehouses` *(Select target storage location)*

#### 28. VendorPaymentFormScreen
- **File:** `lib/features/purchasing/presentation/screens/vendor_payment_form_screen.dart`
- **Route:** `/purchases/:id/pay`
- **Purpose:** Record payout against supplier invoice, transaction reference, and mode of payment.
- **Integrated APIs:**
  - `POST /api/vendor-payments` *(Create vendor payment transaction)*
  - `GET /api/payment-methods` *(Payment method selector)*

---

### 📦 Epic 05: Inventory & Stock Management (2 Screens)

#### 29. StockDashboardScreen
- **File:** `lib/features/inventory/presentation/screens/stock_dashboard_screen.dart`
- **Route:** `/inventory` (Main Tab 3)
- **Purpose:** Real-time stock levels, warehouse distribution, reorder alerts, and valuation metrics.
- **Integrated APIs:**
  - `GET /api/stock-balances` *(List current stock balances)*
  - `GET /api/warehouses` *(Filter by warehouse)*
  - `GET /api/products` *(Filter by item)*

#### 30. StockMovementScreen
- **File:** `lib/features/inventory/presentation/screens/stock_movement_screen.dart`
- **Route:** `/inventory/movements`
- **Purpose:** Audit ledger of all stock transactions (GRN inwarding, production issue, scrap, dispatch).
- **Integrated APIs:**
  - `GET /api/stock-transactions` *(List stock movement log)*
  - `GET /api/audit-logs` *(List audit transactions)*

---

### 📦 Epic 06: BOM & Recipe Engineering (3 Screens)

#### 31. BomListScreen
- **File:** `lib/features/production/bom/presentation/screens/bom_list_screen.dart`
- **Route:** `/bom`
- **Purpose:** Catalog of production recipes, BOM revisions, and yield ratios.
- **Integrated APIs:**
  - `GET /api/boms` *(List BOM recipes)*

#### 32. BomFormScreen
- **File:** `lib/features/production/bom/presentation/screens/bom_form_screen.dart`
- **Route:** `/bom/new` & `/bom/:id/edit`
- **Purpose:** Configure recipe composition, input raw material quantities, ratios, and expected scrap %.
- **Integrated APIs:**
  - `POST /api/boms` *(Create BOM)*
  - `POST /api/bom-details` *(Add raw material components)*
  - `PUT /api/boms/{id}` *(Update BOM)*
  - `GET /api/products` *(Select finished good and raw material components)*

#### 33. BomDetailScreen
- **File:** `lib/features/production/bom/presentation/screens/bom_detail_screen.dart`
- **Route:** `/bom/:id`
- **Purpose:** Comprehensive breakdown of BOM ingredients, component quantities, and standard batch sizes.
- **Integrated APIs:**
  - `GET /api/boms/{id}` *(Fetch BOM header)*
  - `GET /api/bom-details` *(Fetch BOM components)*

---

### 📦 Epic 07: Production Management & QC (6 Screens)

#### 34. ProductionOrderListScreen
- **File:** `lib/features/production/presentation/screens/production_order_list_screen.dart`
- **Route:** `/production` (Main Tab 2)
- **Purpose:** Shop floor production queue with status tracking (Planned, Running, Completed).
- **Integrated APIs:**
  - `GET /api/production-orders` *(List production work orders)*

#### 35. ProductionOrderFormScreen
- **File:** `lib/features/production/presentation/screens/production_order_form_screen.dart`
- **Route:** `/production/new`
- **Purpose:** Create manufacturing work orders by selecting approved BOM and target batch quantity.
- **Integrated APIs:**
  - `POST /api/production-orders` *(Create work order)*
  - `GET /api/boms` *(Select BOM recipe)*
  - `GET /api/products` *(Select target product)*

#### 36. ProductionStageTrackerScreen
- **File:** `lib/features/production/presentation/screens/production_stage_tracker_screen.dart`
- **Route:** `/production/:id/track`
- **Purpose:** Track production stage milestones (Extrusion, Forming, Trimming, Finishing, Packaging).
- **Integrated APIs:**
  - `GET /api/production-stages` *(List defined stages)*
  - `GET /api/production-stage-entries` *(Fetch current order stage entries)*
  - `PUT /api/production-stage-entries/{id}` *(Update stage start/end/status)*

#### 37. ProductionMaterialIssueScreen
- **File:** `lib/features/production/presentation/screens/production_material_issue_screen.dart`
- **Route:** `/production/:id/issue`
- **Purpose:** Transfer raw materials from warehouse to factory floor for batch execution.
- **Integrated APIs:**
  - `POST /api/production-material-issues` *(Record raw material issue)*
  - `GET /api/stock-balances` *(Check available warehouse stock)*

#### 38. ProductionOutputFormScreen
- **File:** `lib/features/production/presentation/screens/production_output_form_screen.dart`
- **Route:** `/production/:id/output`
- **Purpose:** Record finished goods quantity produced from the batch into target storage warehouse.
- **Integrated APIs:**
  - `POST /api/production-outputs` *(Record output batch quantity)*
  - `GET /api/warehouses` *(Select target warehouse)*

#### 39. ProductionQualityCheckScreen
- **File:** `lib/features/production/presentation/screens/production_quality_check_form_screen.dart`
- **Route:** `/production/:id/qc`
- **Purpose:** Log quality inspection metrics, passed units, rejected units, and inspection notes.
- **Integrated APIs:**
  - `POST /api/quality-checks` *(Create QC report)*
  - `GET /api/quality-checks` *(Fetch QC inspection history)*

---

### 📦 Epic 08: Waste & Scrap Management (3 Screens)

#### 40. WasteListScreen
- **File:** `lib/features/waste/presentation/screens/waste_list_screen.dart`
- **Route:** `/waste`
- **Purpose:** Scrap register recording waste generated during manufacturing operations.
- **Integrated APIs:**
  - `GET /api/waste-entries` *(List recorded scrap)*

#### 41. WasteEntryFormScreen
- **File:** `lib/features/waste/presentation/screens/waste_entry_form_screen.dart`
- **Route:** `/waste/new`
- **Purpose:** Record scrap weight/quantity, associate with production order/stage, and specify waste reason.
- **Integrated APIs:**
  - `POST /api/waste-entries` *(Record scrap entry)*
  - `GET /api/waste-reasons` *(Waste reason selection)*
  - `GET /api/products` *(Scrap material selection)*

#### 42. WasteReasonScreen
- **File:** `lib/features/waste/presentation/screens/waste_reason_screen.dart`
- **Route:** `/waste/reasons`
- **Purpose:** Manage defect categories (e.g. Edge trimming, Machine start loss, Color defect, Edge curl).
- **Integrated APIs:**
  - `GET /api/waste-reasons` *(List waste reasons)*
  - `POST /api/waste-reasons` *(Create new waste reason)*

---

### 📦 Epic 09: Sales & Customer Invoicing (4 Screens)

#### 43. SalesListScreen
- **File:** `lib/features/sales/presentation/screens/sales_list_screen.dart`
- **Route:** `/sales`
- **Purpose:** Sales order register showing customer, invoice totals, payment status, and dispatch status.
- **Integrated APIs:**
  - `GET /api/sales` *(List sales orders)*
  - `GET /api/customers` *(Customer filter)*

#### 44. SalesFormScreen
- **File:** `lib/features/sales/presentation/screens/sales_form_screen.dart`
- **Route:** `/sales/new`
- **Purpose:** Multi-item sales invoice creation with automated tax (GST), pricing, and discounts.
- **Integrated APIs:**
  - `POST /api/sales` *(Create sales order header)*
  - `POST /api/sale-details` *(Add sales order lines)*
  - `GET /api/customers` *(Customer selector)*
  - `GET /api/products` *(Product selector)*

#### 45. SalesDetailScreen
- **File:** `lib/features/sales/presentation/screens/sales_detail_screen.dart`
- **Route:** `/sales/:id`
- **Purpose:** Detailed view of customer order, line items, taxes, payment history, and delivery challans.
- **Integrated APIs:**
  - `GET /api/sales/{id}` *(Fetch sales order header)*
  - `GET /api/sale-details` *(Fetch sales order line items)*

#### 46. CustomerPaymentFormScreen
- **File:** `lib/features/sales/presentation/screens/customer_payment_form_screen.dart`
- **Route:** `/sales/payments/new`
- **Purpose:** Record incoming payment receipt against customer sales invoices.
- **Integrated APIs:**
  - `POST /api/customer-payments` *(Record customer payment)*
  - `GET /api/payment-methods` *(Payment method selector)*
  - `GET /api/customers` *(Customer selector)*

---

### 📦 Epic 10: Dispatch, Deliveries & Fleet Logistics (4 Screens)

#### 47. PendingDispatchScreen
- **File:** `lib/features/dispatch/presentation/screens/pending_dispatch_screen.dart`
- **Route:** `/dispatch/pending`
- **Purpose:** Queue of packed sales orders ready for shipment dispatch and vehicle loading.
- **Integrated APIs:**
  - `GET /api/sales` *(Filter orders by Confirmed/Ready status)*

#### 48. DeliveryFormScreen
- **File:** `lib/features/dispatch/presentation/screens/delivery_form_screen.dart`
- **Route:** `/dispatch/new`
- **Purpose:** Generate Delivery Challan (DC), assign transporter, vehicle number, and driver details.
- **Integrated APIs:**
  - `POST /api/deliveries` *(Create delivery challan header)*
  - `POST /api/delivery-details` *(Add dispatched items)*
  - `GET /api/transporters` *(Select transporter)*
  - `GET /api/vehicles` *(Select fleet vehicle)*

#### 49. DispatchHistoryScreen
- **File:** `lib/features/dispatch/presentation/screens/dispatch_history_screen.dart`
- **Route:** `/dispatch`
- **Purpose:** Outbound shipment history, delivery tracking, and Proof of Delivery (POD) records.
- **Integrated APIs:**
  - `GET /api/deliveries` *(List dispatch shipments)*

#### 50. DeliveryDetailScreen
- **File:** `lib/features/dispatch/presentation/screens/delivery_detail_screen.dart`
- **Route:** `/dispatch/:id`
- **Purpose:** Detailed view of Delivery Challan, dispatched items, vehicle info, and recipient signoff.
- **Integrated APIs:**
  - `GET /api/deliveries/{id}` *(Fetch delivery header)*
  - `GET /api/delivery-details` *(Fetch delivery item lines)*

---

### 📦 Epic 11: Expense Management (3 Screens)

#### 51. ExpenseListScreen
- **File:** `lib/features/expenses/presentation/screens/expense_list_screen.dart`
- **Route:** `/expenses`
- **Purpose:** Factory operating expenses register and payout ledger.
- **Integrated APIs:**
  - `GET /api/expenses` *(List expenses)*
  - `GET /api/expense-categories` *(Category filter)*

#### 52. ExpenseFormScreen
- **File:** `lib/features/expenses/presentation/screens/expense_form_screen.dart`
- **Route:** `/expenses/new`
- **Purpose:** Submit operational expense voucher (e.g. Fuel, Machine Maintenance, Power, Factory Rent).
- **Integrated APIs:**
  - `POST /api/expenses` *(Create expense)*
  - `GET /api/expense-categories` *(Select expense category)*
  - `GET /api/payment-methods` *(Select payment mode)*

#### 53. ExpenseCategoryScreen
- **File:** `lib/features/expenses/presentation/screens/expense_category_screen.dart`
- **Route:** `/expenses/categories`
- **Purpose:** Manage factory expense categories.
- **Integrated APIs:**
  - `GET /api/expense-categories` *(List categories)*
  - `POST /api/expense-categories` *(Create category)*
  - `PUT /api/expense-categories/{id}` *(Update category)*

---

### 📦 Epic 12: Operations Dashboard, Flow & Reports Hub (4 Screens)

#### 54. HomeScreen
- **File:** `lib/features/home/presentation/screens/home_screen.dart`
- **Route:** `/home` (Main Tab 0)
- **Purpose:** Executive plant dashboard showing daily output, low stock alerts, pending orders, and shortcuts.
- **Integrated APIs:**
  - `GET /api/stock-balances` *(Stock valuation summary)*
  - `GET /api/production-orders` *(Active production counts)*
  - `GET /api/purchases` *(Pending purchase orders)*
  - `GET /api/sales` *(Today's sales totals)*
  - `GET /api/notifications` *(High-priority factory alerts)*

#### 55. MoreMenuScreen
- **File:** `lib/features/home/presentation/screens/more_menu_screen.dart`
- **Route:** `/more` (Main Tab 4)
- **Purpose:** Central navigation hub connecting all factory submodules (Masters, Partners, Sales, Dispatch, Waste, Expenses, Reports, Flow).
- **Integrated APIs:**
  - Sub-module navigation orchestrator

#### 56. ManufacturingFlowScreen
- **File:** `lib/features/manufacturing_flow/presentation/screens/manufacturing_flow_screen.dart`
- **Route:** `/manufacturing-flow`
- **Purpose:** Interactive visualization of the end-to-end factory lifecycle stages from Raw Material to Dispatch.
- **Integrated APIs:**
  - `GET /api/production-stages` *(Stage definitions)*
  - `GET /api/stock-balances` *(Inventory status per stage)*

#### 57. ReportsHubScreen
- **File:** `lib/features/reports/presentation/screens/reports_hub_screen.dart`
- **Route:** `/reports`
- **Purpose:** Business intelligence analytics hub (Stock Valuation, Production Output, Sales Revenue, Scrap Analysis, Expense Breakdowns).
- **Integrated APIs:**
  - `GET /api/stock-balances` *(Stock reports)*
  - `GET /api/production-orders` *(Production yield reports)*
  - `GET /api/sales` *(Sales revenue reports)*
  - `GET /api/waste-entries` *(Waste & defect analysis)*
  - `GET /api/expenses` *(Expense breakdown reports)*

---

## 3. Screen File Hierarchy & Quick Reference

```text
lib/
├── features/
│   ├── auth/presentation/screens/
│   │   ├── splash_screen.dart (1)
│   │   ├── login_screen.dart (2)
│   │   ├── forgot_password_screen.dart (3)
│   │   ├── welcome_screen.dart (4)
│   │   ├── user_management_screen.dart (5)
│   │   └── app_settings_screen.dart (6)
│   ├── notifications/presentation/screens/
│   │   └── notifications_screen.dart (7)
│   ├── masters/presentation/screens/
│   │   ├── master_entry_hub_screen.dart (8)
│   │   ├── products/
│   │   │   ├── product_list_screen.dart (9)
│   │   │   ├── product_form_screen.dart (10)
│   │   │   └── product_detail_screen.dart (11)
│   │   ├── categories/category_screen.dart (12)
│   │   ├── units/unit_screen.dart (13)
│   │   ├── warehouses/warehouse_screen.dart (14)
│   │   └── sequences/sequence_screen.dart (15)
│   ├── partners/presentation/screens/
│   │   ├── suppliers/
│   │   │   ├── supplier_list_screen.dart (16)
│   │   │   └── supplier_form_screen.dart (17)
│   │   ├── customers/
│   │   │   ├── customer_list_screen.dart (18)
│   │   │   └── customer_form_screen.dart (19)
│   │   ├── transporters/
│   │   │   ├── transporter_list_screen.dart (20)
│   │   │   └── transporter_form_screen.dart (21)
│   │   ├── vehicles/vehicle_list_screen.dart (22)
│   │   └── payment_methods/payment_method_screen.dart (23)
│   ├── purchasing/presentation/screens/
│   │   ├── purchase_list_screen.dart (24)
│   │   ├── purchase_order_form_screen.dart (25)
│   │   ├── purchase_detail_screen.dart (26)
│   │   ├── goods_receipt_form_screen.dart (27)
│   │   └── vendor_payment_form_screen.dart (28)
│   ├── inventory/presentation/screens/
│   │   ├── stock_dashboard_screen.dart (29)
│   │   └── stock_movement_screen.dart (30)
│   ├── production/
│   │   ├── bom/presentation/screens/
│   │   │   ├── bom_list_screen.dart (31)
│   │   │   ├── bom_form_screen.dart (32)
│   │   │   └── bom_detail_screen.dart (33)
│   │   └── presentation/screens/
│   │       ├── production_order_list_screen.dart (34)
│   │       ├── production_order_form_screen.dart (35)
│   │       ├── production_stage_tracker_screen.dart (36)
│   │       ├── production_material_issue_screen.dart (37)
│   │       ├── production_output_form_screen.dart (38)
│   │       └── production_quality_check_form_screen.dart (39)
│   ├── waste/presentation/screens/
│   │   ├── waste_list_screen.dart (40)
│   │   ├── waste_entry_form_screen.dart (41)
│   │   └── waste_reason_screen.dart (42)
│   ├── sales/presentation/screens/
│   │   ├── sales_list_screen.dart (43)
│   │   ├── sales_form_screen.dart (44)
│   │   ├── sales_detail_screen.dart (45)
│   │   └── customer_payment_form_screen.dart (46)
│   ├── dispatch/presentation/screens/
│   │   ├── pending_dispatch_screen.dart (47)
│   │   ├── delivery_form_screen.dart (48)
│   │   ├── dispatch_history_screen.dart (49)
│   │   └── delivery_detail_screen.dart (50)
│   ├── expenses/presentation/screens/
│   │   ├── expense_list_screen.dart (51)
│   │   ├── expense_form_screen.dart (52)
│   │   └── expense_category_screen.dart (53)
│   ├── home/presentation/screens/
│   │   ├── home_screen.dart (54)
│   │   └── more_menu_screen.dart (55)
│   ├── manufacturing_flow/presentation/screens/
│   │   └── manufacturing_flow_screen.dart (56)
│   └── reports/presentation/screens/
│       └── reports_hub_screen.dart (57)
```
