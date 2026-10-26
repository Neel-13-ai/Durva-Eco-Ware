# Missing UI Documentation: Delete/Cancel Actions & Edit Dialogs

## Overview
This document tracks the missing UI screens and actions that need to be implemented based on existing backend API support. All delete/edit endpoints are already implemented in repositories but lack corresponding UI triggers.

---

## 1. 🖥️ Entire Screens Still Missing UI

### 1.1 Audit Logs & Activity History Screen
- **Backend APIs**: `GET /api/audit-logs`, `GET /api/audit-logs/{id}`
- **Proposed Location**: More Hub → System
- **User Need**: Plant managers & admins to see who changed stock, deleted records, or modified settings
- **UI Components Needed**:
  - List screen with filtering (date range, user, action type, entity)
  - Detail screen showing full audit trail (old/new values, timestamp, user)
  - Export to CSV/PDF capability

### 1.2 Customer Payment Receipt Screen
- **Backend API**: `GET /api/customer-payments/{id}`
- **Proposed Location**: Sales → Payments
- **User Need**: View paid receipt details, mode of payment, bank transaction ID, linked invoice info
- **UI Components Needed**:
  - Receipt view with print/share option
  - Payment method details, reference number, bank transaction ID
  - Linked invoice navigation

### 1.3 Vendor Payment Receipt Screen
- **Backend API**: `GET /api/vendor-payments/{id}`
- **Proposed Location**: Purchasing → Payments
- **User Need**: View supplier payout receipt, payment proof reference, settled PO details
- **UI Components Needed**:
  - Receipt view with print/share option
  - Payment proof attachment viewer
  - Linked purchase order navigation

---

## 2. 🗑️ Missing "Delete / Cancel" Actions on Existing Screens

### 2.1 Production Order List Screen
**File**: `lib/features/production/presentation/screens/production_order_list_screen.dart`
**Backend**: `DELETE /api/production-orders/{id}` (Implemented in `ProductionRepository.deleteProductionOrder`)

**Current UI**: List of production order cards with tap-to-track functionality
**Missing**: "Cancel / Delete Production Order" action in popup menu on each card

**UI Flow**:
```
User long-presses or taps menu on ProductionOrderCard
    → Show PopupMenuButton with "Cancel Order" / "Delete Order"
    → Confirm dialog: "Are you sure? This cannot be undone."
    → Call ProductionRepository.deleteProductionOrder(order.id)
    → On success: Show snackbar, invalidate productionOrdersListProvider
    → On failure: Show error snackbar
```

**Unit Tests**:
- `ProductionOrderListScreen` widget test: Verify popup menu appears on long press
- `ProductionRepository.deleteProductionOrder` test: Verify correct API call
- Provider test: Verify list refreshes after deletion

**Integration Tests**:
- Full flow: Create order → Delete order → Verify removed from list
- Permission test: Non-admin users cannot delete completed orders

---

### 2.2 Sales Detail Screen
**File**: `lib/features/sales/presentation/screens/sales_detail_screen.dart`
**Backend**: `DELETE /api/sales/{id}` (Implemented in `SalesRepository.deleteSale`)

**Current UI**: Invoice detail with status badges, line items, payment history, "Record Payment" button
**Missing**: "Delete / Void Invoice" button in app bar menu

**UI Flow**:
```
User taps 3-dot menu in AppBar
    → Show "Void Invoice" / "Delete Invoice" option
    → Confirm dialog with warning: "Voiding will reverse stock & accounting entries"
    → Call SalesRepository.deleteSale(saleId)
    → On success: Navigate back to sales list, show success snackbar
    → On failure: Show error snackbar
```

**Unit Tests**:
- `SalesDetailScreen` widget test: Verify menu item appears for voidable invoices
- `SalesRepository.deleteSale` test: Verify API call with correct ID
- State test: Verify navigation pop on success

**Integration Tests**:
- Draft invoice void flow
- Partially paid invoice void (should fail/require payment reversal first)
- Completed invoice void with stock reversal verification

---

### 2.3 Delivery Detail Screen
**File**: `lib/features/dispatch/presentation/screens/delivery_detail_screen.dart`
**Backend**: `DELETE /api/deliveries/{id}` (Implemented in `DeliveryRepository.deleteDelivery`)

**Current UI**: Delivery challan detail with status actions (Draft→Dispatched→Delivered)
**Missing**: "Cancel Delivery Challan" button

**UI Flow**:
```
User taps "Cancel Challan" button (visible for DRAFT/DISPATCHED status)
    → Confirm dialog: "Cancel this delivery? Stock will be restored if dispatched."
    → Call DeliveryRepository.deleteDelivery(deliveryId)
    → On success: Navigate back, show success snackbar
    → On failure: Show error snackbar
```

**Unit Tests**:
- `DeliveryDetailScreen` widget test: Verify cancel button visibility by status
- `DeliveryRepository.deleteDelivery` test: Verify API call
- State test: Verify stock restoration logic trigger

**Integration Tests**:
- Cancel draft delivery (no stock impact)
- Cancel dispatched delivery (stock restoration verification)
- Cannot cancel delivered delivery

---

### 2.4 Expense List Screen
**File**: `lib/features/expenses/presentation/screens/expense_list_screen.dart`
**Backend**: `DELETE /api/expenses/{id}` (Implemented in `ExpenseRepository.deleteExpense`)

**Current UI**: Expense list cards with category filter, search, metrics
**Missing**: "Delete Expense" swipe action or trailing button on expense list tile

**UI Flow**:
```
User swipes left on expense card OR taps trailing delete icon
    → Show confirmation: "Delete expense voucher #{expenseNumber}?"
    → Call ExpenseRepository.deleteExpense(expense.id)
    → On success: Remove from list with animation, show snackbar
    → On failure: Show error snackbar, revert swipe
```

**Unit Tests**:
- `ExpenseListScreen` widget test: Verify swipe-to-delete or delete button
- `ExpenseRepository.deleteExpense` test: Verify API call
- Dismissible test: Verify list updates correctly

**Integration Tests**:
- Delete expense → Verify metrics update (total outflow, count, average)
- Delete with attachment handling
- Permission-based deletion

---

### 2.5 Waste List Screen
**File**: `lib/features/waste/presentation/screens/waste_list_screen.dart`
**Backend**: `DELETE /api/waste-entries/{id}` (Implemented in `WasteRepository.deleteEntry`)

**Current UI**: Waste entry cards with disposal method badges, KPI metrics
**Missing**: "Delete Scrap Entry" action on recorded waste item

**UI Flow**:
```
User taps menu on _WasteEntryCard OR long-presses
    → Show "Delete Entry" option
    → Confirm dialog: "Delete this scrap incident? Loss amount will be removed from metrics."
    → Call WasteRepository.deleteEntry(entry.id)
    → On success: Remove card with animation, update KPI metrics, show snackbar
    → On failure: Show error snackbar
```

**Unit Tests**:
- `WasteListScreen` widget test: Verify delete action on card
- `WasteRepository.deleteEntry` test: Verify API call
- Metrics test: Verify KPI recalculation after deletion

**Integration Tests**:
- Delete recycled entry → Verify recycling % updates
- Delete discarded entry → Verify total loss updates
- Bulk delete (if implemented)

---

### 2.6 Waste Reason Screen
**File**: `lib/features/waste/presentation/screens/waste_reason_screen.dart`
**Backend**: `DELETE /api/waste-reasons/{id}` (Implemented in `WasteRepository.deleteReason`)

**Current UI**: List of waste reasons with only "Add Reason" FAB
**Missing**: "Delete Reason" button on waste reason tile

**UI Flow**:
```
User taps trailing delete icon on reason tile
    → Confirm dialog: "Delete reason '{reasonName}'? Existing waste entries will be unaffected."
    → Call WasteRepository.deleteReason(reason.id)
    → On success: Remove from list, show snackbar
    → On failure: Show error (e.g., "Reason in use by waste entries")
```

**Unit Tests**:
- `WasteReasonScreen` widget test: Verify delete icon on each tile
- `WasteRepository.deleteReason` test: Verify API call
- Error handling test: Verify "in use" error display

**Integration Tests**:
- Delete unused reason → Success
- Delete reason with existing entries → Proper error handling
- Verify reason removed from dropdown in waste entry form

---

### 2.7 Customer Payments List (New Screen Needed)
**Backend**: `DELETE /api/customer-payments/{id}` (Implemented in `CustomerPaymentRepository.deleteCustomerPayment`)

**Current State**: No dedicated list screen exists (only form screen)
**Needed**: Customer Payments List Screen with "Void Payment" button

**UI Flow**:
```
Navigate to Customer Payments List (new route)
    → List shows all payments with receipt #, date, amount, customer, invoice
    → User taps "Void Payment" on payment tile
    → Confirm dialog: "Void payment receipt #{receiptNumber}? Invoice outstanding balance will increase."
    → Call CustomerPaymentRepository.deleteCustomerPayment(paymentId)
    → On success: Update list, refresh related sale detail, show snackbar
    → On failure: Show error snackbar
```

**Unit Tests**:
- New `CustomerPaymentListScreen` widget tests
- `CustomerPaymentRepository.deleteCustomerPayment` test
- Sale detail refresh test after void

**Integration Tests**:
- Void payment → Verify invoice outstanding balance increases
- Void payment → Verify sale payment status updates (PAID→PARTIALLY_PAID/PENDING)
- Cannot void if invoice already cancelled

---

## 3. ✏️ Missing "Edit / Modify" Dialogs on Existing Screens

### 3.1 Waste Reason Screen - Edit Reason
**File**: `lib/features/waste/presentation/screens/waste_reason_screen.dart`
**Backend**: `PUT /api/waste-reasons/{id}` (Implemented in `WasteRepository.updateReason`)

**Current UI**: Only "Add Reason" dialog exists
**Missing**: "Edit Reason Name / Code" dialog when tapping existing reason

**UI Flow**:
```
User taps on reason tile (or edit icon)
    → Show pre-filled dialog with current reasonName & description
    → User modifies fields
    → Call WasteRepository.updateReason(reason.id, updatedReason)
    → On success: Update list, show snackbar
    → On failure: Show error snackbar
```

**Unit Tests**:
- Edit dialog pre-population test
- `WasteRepository.updateReason` test with modified data
- Validation test: Empty name rejected

**Integration Tests**:
- Edit reason → Verify updated name appears in waste entry form dropdown
- Edit reason used by entries → Verify entries still reference correctly

---

### 3.2 Waste List Screen - Edit Waste Entry
**File**: `lib/features/waste/presentation/screens/waste_list_screen.dart`
**Backend**: `PUT /api/waste-entries/{id}` (Implemented in `WasteRepository.updateEntry`)

**Current UI**: Read-only waste entry cards
**Missing**: "Edit Waste Quantity / Reason" dialog when tapping on existing log

**UI Flow**:
```
User taps on _WasteEntryCard (or edit icon)
    → Show edit dialog pre-filled with: product, quantity, reason, disposal method, notes, date
    → User modifies fields
    → Call WasteRepository.updateEntry(entry.id, updatedEntry)
    → On success: Update card, recalculate KPI metrics, show snackbar
    → On failure: Show error snackbar
```

**Unit Tests**:
- Edit dialog pre-population with all fields
- `WasteRepository.updateEntry` test
- Metrics recalculation test after edit

**Integration Tests**:
- Edit quantity → Verify total loss amount recalculates
- Edit disposal method → Verify recycling % updates
- Edit reason → Verify reason name updates in card

---

### 3.3 Customer Payments List - Edit Payment
**Backend**: `PUT /api/customer-payments/{id}` (Implemented in `CustomerPaymentRepository.updateCustomerPayment`)

**Current State**: No list screen exists
**Needed**: Edit dialog on Customer Payments List Screen

**UI Flow**:
```
User taps "Edit" on payment tile in list
    → Show dialog pre-filled with: receipt number, date, amount, reference, notes
    → User modifies fields (amount change requires invoice balance check)
    → Call CustomerPaymentRepository.updateCustomerPayment(paymentId, updatedPayment)
    → On success: Update list, refresh sale detail, show snackbar
    → On failure: Show error (e.g., "Amount exceeds outstanding balance")
```

**Unit Tests**:
- Edit dialog pre-population test
- Amount validation test (cannot exceed outstanding + current payment)
- `CustomerPaymentRepository.updateCustomerPayment` test

**Integration Tests**:
- Edit amount → Verify invoice outstanding balance adjusts correctly
- Edit reference/notes → Verify updates reflect in receipt screen
- Edit date → Verify chronological order in payment history

---

## 4. 📋 Implementation Priority & Dependencies

### Phase 1: High Priority (Core Operations)
| Item | Screen | Effort | Dependencies |
|------|--------|--------|--------------|
| Delete Production Order | ProductionOrderListScreen | Medium | None |
| Delete Sale/Invoice | SalesDetailScreen | Medium | Stock reversal logic |
| Delete Delivery | DeliveryDetailScreen | Medium | Stock restoration logic |
| Delete Expense | ExpenseListScreen | Low | None |
| Delete Waste Entry | WasteListScreen | Low | Metrics recalculation |
| Delete Waste Reason | WasteReasonScreen | Low | None |

### Phase 2: Medium Priority (Payment Operations)
| Item | Screen | Effort | Dependencies |
|------|--------|--------|--------------|
| Customer Payments List Screen | New Screen | High | Routing, providers |
| Void Customer Payment | CustomerPaymentsListScreen | Medium | Phase 1 complete |
| Edit Customer Payment | CustomerPaymentsListScreen | Medium | Phase 1 complete |

### Phase 3: Lower Priority (Enhancement)
| Item | Screen | Effort | Dependencies |
|------|--------|--------|--------------|
| Edit Waste Reason | WasteReasonScreen | Low | None |
| Edit Waste Entry | WasteListScreen | Medium | Phase 1 complete |
| Audit Logs Screen | New Screen | High | Backend pagination |
| Customer Payment Receipt Screen | New Screen | Medium | Routing |
| Vendor Payment Receipt Screen | New Screen | Medium | Routing |

---

## 5. 🧪 Testing Strategy Summary

### Unit Tests Required (Per Feature)
1. **Repository Layer**: Test each delete/update method with mock API client
2. **Provider Layer**: Test state invalidation and refresh after mutations
3. **Widget Layer**: Test UI interactions (dialogs, menus, swipe actions)
4. **Validation**: Test input validation in edit dialogs

### Integration Tests Required (Per Feature)
1. **Happy Path**: Create → Edit/Delete → Verify state
2. **Error Handling**: Network errors, server errors, validation errors
3. **Business Logic**: Stock reversal, balance adjustments, metrics recalculation
4. **Permissions**: Role-based access control (admin vs operator)
5. **Cross-Feature**: Verify related screens update (e.g., void payment → sale detail updates)

### Test File Locations (Suggested)
```
test/features/production/presentation/screens/production_order_list_screen_test.dart
test/features/sales/presentation/screens/sales_detail_screen_test.dart
test/features/dispatch/presentation/screens/delivery_detail_screen_test.dart
test/features/expenses/presentation/screens/expense_list_screen_test.dart
test/features/waste/presentation/screens/waste_list_screen_test.dart
test/features/waste/presentation/screens/waste_reason_screen_test.dart
test/features/sales/presentation/screens/customer_payment_list_screen_test.dart (new)
test/features/sales/presentation/screens/customer_payment_receipt_screen_test.dart (new)
test/features/purchasing/presentation/screens/vendor_payment_receipt_screen_test.dart (new)
test/features/system/presentation/screens/audit_logs_screen_test.dart (new)
```

---

## 6. 🔧 Technical Notes

### Common Patterns to Follow
- Use `ConsumerWidget`/`ConsumerStatefulWidget` with Riverpod
- Show `AlertDialog` for confirmations with destructive actions
- Use `ScaffoldMessenger` for success/error feedback
- Invalidate relevant providers after mutations: `ref.invalidate(provider)`
- Follow existing code style: `BrandColors`, `Spacing`, `Radii` tokens
- Use `context.push()` for navigation (go_router)

### Repository Methods Available
| Feature | Delete Method | Update Method |
|---------|---------------|---------------|
| Production Orders | `deleteProductionOrder(id)` | `updateProductionOrder(id, dto)` |
| Sales | `deleteSale(id)` | `updateSale(id, dto)` |
| Deliveries | `deleteDelivery(id)` | `updateDelivery(id, dto)` |
| Expenses | `deleteExpense(id)` | `updateExpense(id, dto)` |
| Waste Entries | `deleteEntry(id)` | `updateEntry(id, dto)` |
| Waste Reasons | `deleteReason(id)` | `updateReason(id, dto)` |
| Customer Payments | `deleteCustomerPayment(id)` | `updateCustomerPayment(id, dto)` |

### Provider Invalidation Patterns
```dart
// After deletion
ref.invalidate(productionOrdersListProvider);
ref.invalidate(salesListProvider);
ref.invalidate(deliveryListProvider);
ref.invalidate(expensesListProvider);
ref.invalidate(wasteEntriesListProvider);
ref.invalidate(activeWasteReasonsProvider);
ref.invalidate(customerPaymentsProvider(customerId));
ref.invalidate(saleDetailProvider(saleId));
ref.invalidate(salePaymentsProvider(saleId));
ref.invalidate(wasteMetricsProvider);
```

---

## 7. ✅ Acceptance Criteria Checklist

For each delete action:
- [ ] UI trigger visible (menu, swipe, button)
- [ ] Confirmation dialog with clear warning
- [ ] Loading state during API call
- [ ] Success: List updates, snackbar shown, related providers invalidated
- [ ] Error: Snackbar with error message, no UI corruption
- [ ] Unit tests pass
- [ ] Integration tests pass

For each edit dialog:
- [ ] Pre-filled with current data
- [ ] Validation on submit
- [ ] Loading state during API call
- [ ] Success: UI updates, snackbar shown, related providers invalidated
- [ ] Error: Dialog stays open, error shown inline
- [ ] Unit tests pass
- [ ] Integration tests pass

---

*Generated: 2026-10-03*
*Status: Pending Implementation*