# Durva Eco Ware — Feature Implementation & GitHub Issue Catalog

This directory contains the complete, production-grade GitHub Issue tickets created from the **Screen & Flow Specification** (`durva_eco_ware_screen_and_flow_specification.md`) and the **ASP.NET Core REST API / Swagger Specification** (`https://api-dev.durvaecoware.com/swagger/index.html`).

---

## 📋 Epic & Feature Ticket Index

| Issue # | Title | Core APIs Covered | Target Screens |
|---|---|---|---|
| **#01** | [Auth, Session Lifecycle, RBAC & App Settings](file:///c:/workspace/durvaeco/docs/github-issues/issue-01-auth-session-settings.md) | `/api/auth/login`, `/api/app-settings`, `/api/company-settings`, `/api/roles` | Login Screen, Session Expiry Modal, Company & App Settings |
| **#02** | [Core Master Data (Products, Materials, Categories, Units, Warehouses, Sequences)](file:///c:/workspace/durvaeco/docs/github-issues/issue-02-core-master-data.md) | `/api/products`, `/api/categories`, `/api/units`, `/api/warehouses`, `/api/document-sequences` | Master Entry Hub, Product/Material Lists & Forms, Unit/Category Modals, Warehouse Config |
| **#03** | [Partner Master Data & Logistics Fleet (Suppliers, Customers, Transporters, Vehicles, Payment Methods)](file:///c:/workspace/durvaeco/docs/github-issues/issue-03-partner-masters-payment-methods.md) | `/api/suppliers`, `/api/customers`, `/api/transporters`, `/api/vehicles`, `/api/payment-methods` | Supplier Master, Customer Master, Transporters & Vehicle Fleet Setup, Payment Methods |
| **#04** | [Purchasing & Raw Material Inward (PO Management, GRN & Vendor Payments)](file:///c:/workspace/durvaeco/docs/github-issues/issue-04-purchasing-grn-vendor-payments.md) | `/api/purchases`, `/api/purchase-details`, `/api/goods-receipts`, `/api/goods-receipt-details`, `/api/vendor-payments` | PO Builder & List, PO Detail, Goods Receipt (GRN) Inward Inspection, Vendor Payments |
| **#05** | [Inventory Health Dashboard, Stock Balances & Movement History](file:///c:/workspace/durvaeco/docs/github-issues/issue-05-inventory-stock-balances-movements.md) | `/api/stock-balances`, `/api/stock-transactions`, `/api/audit-logs` | Stock Dashboard, Stock Balances Ledger, Manual Stock Adjustment Dialog, Stock Movement History |
| **#06** | [Bill of Materials (BOM) & Recipe Engineering](file:///c:/workspace/durvaeco/docs/github-issues/issue-06-bom-recipe-engineering.md) | `/api/b-o-m-headers`, `/api/b-o-m-details` | BOM List & Status, BOM Recipe Builder (Finished Good -> Raw Materials mapping), BOM Detail |
| **#07** | [Production Management, Multi-Stage Tracking & Quality Control](file:///c:/workspace/durvaeco/docs/github-issues/issue-07-production-stages-quality-control.md) | `/api/production-orders`, `/api/production-stages`, `/api/production-stage-entries`, `/api/production-material-issues`, `/api/production-outputs`, `/api/quality-checks` | Production Planner, Material Requisition, Multi-stage Manufacturing Tracker, Output Form, QC Inspection |
| **#08** | [Waste & Scrap Tracking Management](file:///c:/workspace/durvaeco/docs/github-issues/issue-08-waste-scrap-management.md) | `/api/waste-reasons`, `/api/waste-entries` | Waste Reason Master, Scrap/Waste Recording Form, Waste Register & Loss Analytics |
| **#09** | [Sales Orders, Invoicing & Customer Payments](file:///c:/workspace/durvaeco/docs/github-issues/issue-09-sales-orders-customer-payments.md) | `/api/sales`, `/api/sale-details`, `/api/customer-payments` | Sales Order / Invoice Builder, Sales List & Filters, Sales Detail View, Customer Payment Receipts |
| **#10** | [Dispatch Logistics, Fleet Delivery & Stock Outward Fulfillment](file:///c:/workspace/durvaeco/docs/github-issues/issue-10-dispatch-logistics-delivery.md) | `/api/deliveries`, `/api/delivery-details`, `/api/transporters`, `/api/vehicles` | Pending Dispatch Queue, Delivery Creation Form, Delivery Challan Preview, Dispatch History |
| **#11** | [Expense Management & Operational Cost Accounting](file:///c:/workspace/durvaeco/docs/github-issues/issue-11-expense-management.md) | `/api/expense-categories`, `/api/expenses` | Expense Category Setup, Expense Voucher Entry, Expense Register & Breakdown |
| **#12** | [Operational Dashboard, Interactive Flow, Reports & Notifications](file:///c:/workspace/durvaeco/docs/github-issues/issue-12-dashboard-analytics-notifications-reports.md) | `/api/notifications`, Aggregated System APIs | Executive KPI Dashboard, Interactive Manufacturing Flow, Notification Action Center, Reports Hub |

---

## 🎯 Implementation Phasing & Dependency Graph

```text
Phase 1: Foundation & Security
  └─ Issue #01 (Auth, Session, RBAC, Settings)
       ↓
Phase 2: Master Data Hub
  ├─ Issue #02 (Core Masters: Products, Raw Materials, Categories, Units, Warehouses)
  └─ Issue #03 (Partner Masters: Suppliers, Customers, Transporters, Fleet)
       ↓
Phase 3: Procurement & Inventory Core
  ├─ Issue #04 (Purchasing, GRN & Vendor Payments)
  └─ Issue #05 (Stock Balances, Adjustments & Movements)
       ↓
Phase 4: Manufacturing & Recipe Execution
  ├─ Issue #06 (BOM & Recipe Engineering)
  ├─ Issue #07 (Production Execution, Multi-Stage Tracking & QC)
  └─ Issue #08 (Waste & Scrap Management)
       ↓
Phase 5: Order-to-Cash & Fulfillment
  ├─ Issue #09 (Sales Orders, Invoicing & Customer Payments)
  ├─ Issue #10 (Dispatch Logistics & Delivery Challans)
  └─ Issue #11 (Operational Expense Tracking)
       ↓
Phase 6: Executive Visibility & Intelligence
  └─ Issue #12 (Executive Dashboard, Interactive Flow, Reports & Notifications)
```
