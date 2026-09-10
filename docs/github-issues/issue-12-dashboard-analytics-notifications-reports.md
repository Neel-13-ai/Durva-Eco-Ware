# [Feature]: Operational Dashboard, Interactive Flow, Reports & Notifications

## 1. Feature Overview & Objective
Implement the central Executive & Operational Hub for Durva Eco Ware. Includes the Interactive Manufacturing Flow storyboard diagram, Real-Time Executive KPI Dashboard, Comprehensive Analytics & Reports (Inventory, Purchasing, Production, Sales, Dispatch), and the In-App Notification Center with actionable deep-linking.

---

## 2. Target Screens & UI Components
- **Main Executive Dashboard Screen** (`lib/features/home/presentation/screens/home_screen.dart`):
  - Top Bar: Company branding, active warehouse selector, notification bell icon with unread count badge, user profile.
  - KPI Metrics Grid:
    - Raw Material Stock Value & Low Stock count
    - Active Production Orders in progress
    - Pending Purchase Orders awaiting GRN
    - Today's Sales Value & Pending Dispatches
  - Quick Action Shortcuts: "New Purchase Order", "New Production Order", "New Sales Order", "Stock Adjustment", "Master Hub".
  - Recent Activities Stream: Live feed of last transactions across the factory.
- **Interactive Manufacturing Flow Screen** (`lib/features/manufacturing_flow/presentation/screens/manufacturing_flow_screen.dart`):
  - Visual horizontal business-process pipeline:
    `Raw Material Receipt` ➔ `Raw Material Stock` ➔ `Manufacturing / Production` ➔ `Finished Goods` ➔ `Sales & Dispatch`.
  - Tapping any node displays live operational stats and direct navigation to that module.
- **In-App Notification Center Drawer / Screen** (`lib/features/notifications/presentation/screens/notifications_screen.dart`):
  - Filter by `All`, `Unread`, `Urgent / Alert`.
  - Notification Card: Title, Message, Timestamp, Read status, Action button ("View Order", "View Stock").
  - "Mark all as read" button.
- **Reports & Analytics Hub Screen** (`lib/features/reports/presentation/screens/reports_hub_screen.dart`):
  - Tab 1: **Inventory Report** (Stock valuation, slow-moving items, reorder requirements).
  - Tab 2: **Purchase Report** (Supplier spend, pending vs received POs, price trends).
  - Tab 3: **Production Report** (Planned vs Actual output, yield efficiency, scrap analysis).
  - Tab 4: **Sales & Dispatch Report** (Customer revenue, product demand, delivery turnaround).
  - Date range filters and Export to CSV / PDF capabilities.

---

## 3. API Contracts & Endpoints
| Resource | Method | Endpoint | Query / Body | Expected Output |
|---|---|---|---|---|
| **Notifications** | `GET` | `/api/notifications` | `?includeInactive=false` | `[ { "id": 1, "userId": 1, "notificationType": "LOW_STOCK", "title": "Low Stock Warning", "message": "Bagasse fiber (SKU-RM-001) is below minimum threshold (8.0 KG remaining)", "referenceId": 2, "isRead": false, "readAt": null } ]` |
| | `GET` | `/api/notifications/{id}` | - | Notification JSON |
| | `POST` | `/api/notifications` | Notification JSON | `201 Created` |
| | `PUT` | `/api/notifications/{id}` | `{ "id": 1, "isRead": true, "readAt": "2026-08-29T12:00:00", ... }` | `200 OK` |
| | `DELETE` | `/api/notifications/{id}` | - | `200 OK` |
| **Aggregated KPI Metrics** | `GET` | Composite queries across `/api/stock-balances`, `/api/production-orders`, `/api/purchases`, `/api/sales`, `/api/deliveries` | Filter parameters | Aggregated dashboard view model |

---

## 4. Architecture & State Management
- **Domain Models**: `AppNotification`, `DashboardMetrics`, `ManufacturingStageNode`, `ReportFilter`, `AnalyticsTimeSeriesData`.
- **Repositories**: `NotificationRepository`, `AnalyticsRepository`, `DashboardRepository`.
- **Controllers & Providers**:
  - `unreadNotificationCountProvider`: Auto-refreshing stream or periodic polling provider for the notification badge.
  - `dashboardMetricsProvider`: Combines live metrics across inventory, production, sales, and purchasing with pull-to-refresh.
  - `notificationListControllerProvider`: AsyncNotifier managing notification list and "Mark as Read" actions.
  - `reportsControllerProvider(reportType, filter)`: Family provider generating tabular report summaries.

---

## 5. Form Validation & Business Rules
- **Notification Deep-Linking**:
  - When `notificationType == 'LOW_STOCK'`, tapping navigates to `/inventory/products/{referenceId}`.
  - When `notificationType == 'PURCHASE_PENDING'`, tapping navigates to `/purchases/{referenceId}`.
  - When `notificationType == 'PRODUCTION_ALERT'`, tapping navigates to `/production/{referenceId}`.
  - When `notificationType == 'DISPATCH_READY'`, tapping navigates to `/dispatch/{referenceId}`.
- **Auto-Read on Click**: Opening a notification automatically updates `isRead: true` and `readAt: timestamp`.

---

## 6. Edge Cases & Failure Modes
- **Offline / Low Connectivity on Dashboard**: Display cached metrics with a subtle "Offline / Last synced at [Time]" indicator.
- **Empty Notifications**: Display an aesthetic "All caught up! No new notifications" vector graphic.
- **Large Report Export**: Background compute worker (Dart `Isolate` or compute) to prevent UI jank during CSV/PDF generation.

---

## 7. Testing & Acceptance Criteria (DoD)
- [ ] **Unit Tests**:
  - `DashboardMetricsAggregatorTest`: Accurate summation of active KPI cards.
  - `NotificationRepositoryTest`: Mocked GET, mark-as-read PUT, and DELETE calls.
- [ ] **Widget Tests**:
  - `HomeScreenTest`: KPI cards render with formatted numbers; pull-to-refresh triggers data reload.
  - `ManufacturingFlowScreenTest`: Interactive node taps navigate to corresponding feature routes.
  - `NotificationsScreenTest`: Unread notification counter updates upon marking items as read.
- [ ] **Integration Test**:
  - Launch app -> View Dashboard metrics -> Open Notifications -> Tap low-stock notification -> Verify navigation to the correct Product Stock screen.

---

## 💬 Antigravity Agent Resolution & Verification Comments
- **Reviewer**: `Antigravity Agent`
- **Label**: `[Status: Verified & Resolved]`, `[Feature: Complete]`
- **Resolution**:
  - Redesigned Home Screen matching user poster, 5-tab Bottom Navigation Shell, `ReportsRepository`, and `NotificationRepository` are implemented and verified.
  - Live Overview metrics bound to real backend streams without mock fallbacks.
