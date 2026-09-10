# Durva Eco Ware — Home Dashboard API & Data Specification

> **Host**: `https://api-dev.durvaecoware.com`  
> **Auth Header**: `Authorization: Bearer <JWT_TOKEN>`  
> **Target Screen**: `lib/features/home/presentation/screens/home_screen.dart`

---

## 1. 👤 User Profile & Session State

**Source**: `authControllerProvider` / `/api/auth/login`

```json
{
  "userId": "1",
  "userName": "superadmin",
  "fullName": "Super Admin",
  "roles": ["Administrator"],
  "isLiveServer": true,
  "serverHost": "api-dev.durvaecoware.com"
}
```

### Riverpod Access:
```dart
final auth = ref.watch(authControllerProvider);
final userName = auth.user?.displayName ?? 'Plant Manager';
final role = auth.user?.roles.firstOrNull ?? 'Administrator';
```

---

## 2. 📊 Live KPI Metrics (Real-Time Aggregates)

**Provider**: `dashboardMetricsProvider` (`FutureProvider<DashboardKpiSummary>`)  
**Underlying Endpoints**:
- `/api/stock-balances`
- `/api/production-orders`
- `/api/purchases`
- `/api/sales`
- `/api/deliveries`
- `/api/notifications`

```json
{
  "totalStockValuation": 1450000.00,
  "lowStockCount": 3,
  "activeProductionOrders": 5,
  "pendingPurchases": 2,
  "totalSalesRevenue": 820000.00,
  "pendingDispatches": 4,
  "unreadNotifications": 2
}
```

### Metrics Field Reference:
| Metric | Type | Display Example | Description | Source API Endpoint |
|---|---|---|---|---|
| `totalStockValuation` | `double` | ₹14,50,000 | Total current stock valuation across warehouses | `GET /api/stock-balances` |
| `lowStockCount` | `int` | 3 items | Products below minimum stock alert threshold | `GET /api/stock-balances` |
| `activeProductionOrders` | `int` | 5 Orders | Production runs in progress or queued | `GET /api/production-orders` |
| `pendingPurchases` | `int` | 2 Inward | Purchase Orders pending goods receipt (GRN) | `GET /api/purchases` |
| `totalSalesRevenue` | `double` | ₹8,20,000 | Total invoiced sales revenue | `GET /api/sales` |
| `pendingDispatches` | `int` | 4 Shipments | Orders ready awaiting transporter dispatch | `GET /api/deliveries` |
| `unreadNotifications` | `int` | 2 Alerts | Unread system, stock, and factory notifications | `GET /api/notifications` |

### Riverpod Access:
```dart
final metricsAsync = ref.watch(dashboardMetricsProvider);
final unreadCount = ref.watch(unreadNotificationCountProvider);

metricsAsync.when(
  data: (metrics) => Text('Valuation: ₹${metrics.totalStockValuation}'),
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => Text('Error loading metrics: $err'),
);
```

---

## 3. 🏭 8-Stage Manufacturing Storyboard Pipeline

**Source**: `GET /api/production-stages` & `ManufacturingFlowScreen`

```json
[
  {
    "stageNumber": 1,
    "name": "Raw Pulp Inward",
    "description": "Bagasse fiber bale inspection & weighing",
    "code": "STAGE_RAW",
    "icon": "inventory_2_outlined",
    "color": "#1B5E20"
  },
  {
    "stageNumber": 2,
    "name": "Hydration & Slurry Mixing",
    "description": "Pulp hydrapulper mixing, consistency & additives",
    "code": "STAGE_SLURRY",
    "icon": "water_drop_outlined",
    "color": "#0288D1"
  },
  {
    "stageNumber": 3,
    "name": "Thermoforming & Hot Press",
    "description": "Vacuum mold suction & high-temp hot pressing",
    "code": "STAGE_PRESS",
    "icon": "heat_pump_outlined",
    "color": "#E65100"
  },
  {
    "stageNumber": 4,
    "name": "Edge Trimming & Deburring",
    "description": "Automated hydraulic die punch & edge smoothing",
    "code": "STAGE_TRIM",
    "icon": "content_cut_outlined",
    "color": "#6A1B9A"
  },
  {
    "stageNumber": 5,
    "name": "Quality Inspection (QC)",
    "description": "Weight, thickness, rim defect & burst testing",
    "code": "STAGE_QC",
    "icon": "verified_outlined",
    "color": "#2E7D32"
  },
  {
    "stageNumber": 6,
    "name": "UV Sterilization",
    "description": "Continuous UV tunnel antimicrobial treatment",
    "code": "STAGE_UV",
    "icon": "wb_sunny_outlined",
    "color": "#F57F17"
  },
  {
    "stageNumber": 7,
    "name": "Eco Packaging & Boxing",
    "description": "Shrink-wrapping & corrugated box carton packing",
    "code": "STAGE_PACK",
    "icon": "all_inbox_outlined",
    "color": "#00796B"
  },
  {
    "stageNumber": 8,
    "name": "Dispatch & Outward Fleet",
    "description": "Palletizing, delivery challan & truck loading",
    "code": "STAGE_DISPATCH",
    "icon": "local_shipping_outlined",
    "color": "#37474F"
  }
]
```

---

## 4. 📋 Live Feed Lists Available for Dashboard Cards

### A. Active Production Runs (`productionOrdersListProvider`)
- **Endpoint**: `GET /api/production-orders`
```json
[
  {
    "id": 101,
    "orderNumber": "MO-2026-001",
    "productName": "10-inch Round Bagasse Plate",
    "productCode": "PLT-10-RND",
    "plannedQuantity": 5000.0,
    "goodQuantity": 3200.0,
    "rejectedQuantity": 45.0,
    "currentStage": "Thermoforming",
    "progressPercentage": 64.0,
    "status": "InProgress",
    "startDate": "2026-09-09T08:00:00Z"
  }
]
```

### B. Recent Purchase Orders (`purchasesListProvider`)
- **Endpoint**: `GET /api/purchases`
```json
[
  {
    "id": 51,
    "purchaseNumber": "PO-2026-089",
    "supplierName": "Green Pulp Agro Ltd",
    "totalAmount": 125000.00,
    "paidAmount": 50000.00,
    "outstandingBalance": 75000.00,
    "status": "Pending",
    "orderDate": "2026-09-09"
  }
]
```

### C. Low Stock Alert Items (`stockBalancesListProvider`)
- **Endpoint**: `GET /api/stock-balances`
```json
[
  {
    "productId": 12,
    "productName": "Bleached Sugarcane Bagasse Pulp",
    "sku": "RAW-PULP-001",
    "warehouseName": "Raw Material Silo A",
    "currentQuantity": 180.0,
    "minimumQuantity": 500.0,
    "unit": "Kg",
    "healthStatus": "LowStock",
    "valuation": 54000.00
  }
]
```

---

## 5. 🎯 Quick Action Router Paths

| Action / Button | Route | Destination Screen |
|---|---|---|
| **New Purchase Order (PO)** | `/purchases/new` | `PurchaseOrderFormScreen` |
| **New Production Run (MO)** | `/production/new` | `ProductionOrderFormScreen` |
| **New Sales Order** | `/sales/new` | `SalesFormScreen` |
| **View Stock Health** | `/inventory` | `StockDashboardScreen` |
| **Track Production Floor** | `/production/:id/track` | `ProductionStageTrackerScreen` |
| **Interactive Factory Flow** | `/manufacturing-flow` | `ManufacturingFlowScreen` |
| **BI Reports Hub** | `/reports` | `ReportsHubScreen` |
| **Notification Center** | `/notifications` | `NotificationsScreen` |
| **Master Data Setup** | `/masters` | `MasterEntryHubScreen` |
| **Transporters & Fleet** | `/partners/transporters` | `TransporterListScreen` |
| **Logistics & Dispatch** | `/dispatch` | `DispatchHistoryScreen` |
| **Operating Expenses** | `/expenses` | `ExpenseListScreen` |

---

## 6. 🎨 Color Tokens & Design Specs

```dart
// Primary Eco Green Palette
const Color primary = Color(0xFF1B5E20);      // Forest Eco Green
const Color secondary = Color(0xFF2E7D32);    // Leaf Green
const Color accent = Color(0xFF43A047);       // Light Green Accent
const Color background = Color(0xFFF7F9FA);   // Off-White Surface
const Color cardBorder = Color(0xFFE2E8F0);   // Subtle Slate Border
```
