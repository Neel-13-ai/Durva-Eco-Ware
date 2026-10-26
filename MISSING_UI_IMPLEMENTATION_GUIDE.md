# Missing UI Implementation Guide

**Project**: Durva Eco Ware ERP
**Generated**: 2026-10-03
**Scope**: 13 missing UI actions/screens backed by existing backend APIs

---

## Table of Contents

1. [Entire Missing Screens](#1-entire-missing-screens)
2. [Missing Delete/Cancel Actions](#2-missing-deletecancel-actions)
3. [Missing Edit/Modify Dialogs](#3-missing-editmodify-dialogs)
4. [Common Implementation Patterns](#4-common-implementation-patterns)
5. [Validation Rules](#5-validation-rules)
6. [E2E Navigation & Routes](#6-e2e-navigation--routes)
7. [Testing Checklist](#7-testing-checklist)

---

## 1. Entire Missing Screens

### 1.1 Audit Logs & Activity History Screen

**API Endpoints**:
- `GET /api/audit-logs` (with query: `tableName`, `recordId`, `includeInactive`)
- `GET /api/audit-logs/{id}`

**Backend Status**: ✅ Complete
- DTO: `lib/features/inventory/data/models/audit_log_dto.dart`
- Repository: `lib/features/inventory/data/repositories/audit_log_repository.dart`
- Provider: `lib/features/inventory/application/providers/inventory_providers.dart` (line 181-188)

**Files to Create**:
```
lib/features/inventory/presentation/screens/audit_log_list_screen.dart
lib/features/inventory/presentation/screens/audit_log_detail_screen.dart
```

**UI Requirements**:
- **List Screen**: Filterable table (TableName, RecordId, Action, ChangedBy, ChangeDate)
- Filter chips: Table Name dropdown, Date range picker, Include Inactive toggle
- Search by table name / record ID / user
- Tap row → navigate to detail screen
- Route: `/audit-logs` (list), `/audit-logs/:id` (detail)
- Add to MoreMenuScreen → System Administration section

**Detail Screen Fields**:
| Field | Display |
|-------|---------|
| ID | `AuditLogDto.id` |
| Table Name | `tableName` |
| Record ID | `recordId` |
| Action | `action` (CREATE/UPDATE/DELETE) |
| Changed By | `changedBy` |
| Change Date | `changeDate` formatted |
| Old Values | JSON pretty-print `oldValues` |
| New Values | JSON pretty-print `newValues` |

**Navigation**:
```dart
// In router.dart - add under "System Administration & Security" branch
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/audit-logs',
  builder: (context, state) => const RouteGuard(child: AuditLogListScreen()),
),
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/audit-logs/:id',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: AuditLogDetailScreen(auditLogId: id));
  },
),
```

---

### 1.2 Customer Payment Receipt Screen

**API Endpoint**: `GET /api/customer-payments/{id}`

**Backend Status**: ✅ Complete
- DTO: `lib/features/sales/data/models/customer_payment_dto.dart`
- Repository: `lib/features/sales/data/repositories/customer_payment_repository.dart`
- Provider: `customerPaymentsProvider` (family by customerId), `salePaymentsProvider` (family by saleId)

**Files to Create**:
```
lib/features/sales/presentation/screens/customer_payment_detail_screen.dart
```

**UI Requirements**:
- **Detail Screen** (read-only receipt view):
  - Receipt header: Receipt Number, Date, Status badge
  - Customer: Name, linked invoice number
  - Payment: Amount, Method, Reference/Txn No
  - Notes if any
  - "Print Receipt" / "Share" actions (future)
- Route: `/sales/payments/:id`
- Accessible from: SalesDetailScreen payment history list (tap payment row)

**Navigation**:
```dart
// In router.dart - add under Sales routes (after line 441)
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/sales/payments/:id',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: CustomerPaymentDetailScreen(paymentId: id));
  },
),
```

**Integration in SalesDetailScreen** (line 198-210):
```dart
// Wrap ListTile in InkWell or onTap
onTap: () => context.push('/sales/payments/${p.id}'),
```

---

### 1.3 Vendor Payment Receipt Screen

**API Endpoint**: `GET /api/vendor-payments/{id}`

**Backend Status**: ✅ Complete
- DTO: `lib/features/purchasing/data/models/vendor_payment_dto.dart`
- Repository: `lib/features/purchasing/data/repositories/vendor_payment_repository.dart`

**Files to Create**:
```
lib/features/purchasing/presentation/screens/vendor_payment_detail_screen.dart
```

**UI Requirements**:
- Mirrors CustomerPaymentDetailScreen
- Shows: Receipt Number, Date, Supplier, Linked PO, Amount, Method, Reference
- Route: `/purchases/payments/:id`
- Accessible from: PurchaseDetailScreen → vendor payments list (when implemented)

**Navigation**:
```dart
// In router.dart - add under Purchasing routes (after line 325)
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/purchases/payments/:id',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: VendorPaymentDetailScreen(paymentId: id));
  },
),
```

---

## 2. Missing Delete/Cancel Actions

### 2.1 Delete Production Order

**Screen**: `ProductionOrderListScreen` (`lib/features/production/presentation/screens/production_order_list.dart`)
**Card Widget**: `_ProductionOrderCard` (line 140-262)
**Repository Method**: `ProductionRepository.deleteProductionOrder(int id)` (line 243)

**Implementation**:
```dart
// Add to _ProductionOrderCard - trailing IconButton or PopupMenuButton
PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'delete') _confirmDelete(context, ref, order.id);
  },
  itemBuilder: (context) => [
    const PopupMenuItem(value: 'delete', child: Text('Cancel / Delete Order')),
  ],
  icon: const Icon(Icons.more_vert),
)

// Confirmation dialog
Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int orderId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Production Order?'),
      content: const Text('This action cannot be undone. Linked stage entries and material issues will also be removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  
  if (confirmed == true && context.mounted) {
    final repo = ref.read(productionRepositoryProvider);
    final result = await repo.deleteProductionOrder(orderId);
    result.when(
      success: (_) {
        ref.invalidate(productionOrdersListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Production order deleted'), backgroundColor: Colors.red),
        );
      },
      failure: (err) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${err.message}'), backgroundColor: Colors.red),
      ),
    );
  }
}
```

**Validation**:
- Only allow delete if status is `DRAFT` or `PLANNED` (not `IN_PROGRESS`, `COMPLETED`)
- Backend should enforce; UI can pre-check: `order.status != ProductionStatus.inProgress && order.status != ProductionStatus.completed`

---

### 2.2 Delete/Void Sales Invoice

**Screen**: `SalesDetailScreen` (`lib/features/sales/presentation/screens/sales_detail_screen.dart`)
**AppBar Actions**: Line 23-31 (only refresh)
**Repository Method**: `SalesRepository.deleteSale(int id)` (line 125)

**Implementation**:
```dart
// Add to AppBar actions (after refresh button)
PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'void') _confirmVoid(context, ref, sale.id, sale.status);
  },
  itemBuilder: (context) => [
    if (sale.status != 'CANCELLED' && sale.status != 'VOIDED')
      const PopupMenuItem(value: 'void', child: Text('Void / Delete Invoice')),
  ],
  icon: const Icon(Icons.more_vert),
)

Future<void> _confirmVoid(BuildContext context, WidgetRef ref, int saleId, String status) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Void Invoice?'),
      content: Text('This will void invoice and reverse stock. Paid amount: ₹${sale.paidAmount.toStringAsFixed(2)}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Void Invoice'),
        ),
      ],
    ),
  );
  
  if (confirmed == true && context.mounted) {
    final repo = ref.read(salesRepositoryProvider);
    final result = await repo.deleteSale(saleId);
    result.when(
      success: (_) {
        ref.invalidate(salesListProvider);
        ref.invalidate(saleDetailProvider(saleId));
        if (context.mounted) context.pop(); // Return to list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice voided'), backgroundColor: Colors.red),
        );
      },
      failure: (err) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${err.message}'), backgroundColor: Colors.red),
      ),
    );
  }
}
```

**Validation**:
- Allow void only if: `status != 'CANCELLED'` and `status != 'VOIDED'`
- If `paidAmount > 0`, warn user (reversal needed)
- Backend should handle stock reversal

---

### 2.3 Cancel Delivery Challan

**Screen**: `DeliveryDetailScreen` (`lib/features/dispatch/presentation/screens/delivery_detail_screen.dart`)
**Current Actions**: Lines 179-257 (Mark Dispatched / Mark Delivered)
**Repository Method**: `DeliveryRepository.deleteDelivery(int id)` (line 127)

**Implementation**:
```dart
// Add after status action buttons (line 257), before closing Column
if (delivery.status == 'DRAFT' || delivery.status == 'DISPATCHED')
  OutlinedButton.icon(
    onPressed: () => _confirmCancel(context, ref, delivery),
    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
    label: const Text('Cancel Delivery Challan', style: TextStyle(color: Colors.red)),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.red),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
  ),

Future<void> _confirmCancel(BuildContext context, WidgetRef ref, DeliveryDto delivery) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel Delivery Challan?'),
      content: Text('Status: ${delivery.status}. This will release reserved stock.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cancel Challan'),
        ),
      ],
    ),
  );
  
  if (confirmed == true && context.mounted) {
    final repo = ref.read(deliveryRepositoryProvider);
    final result = await repo.deleteDelivery(delivery.id);
    result.when(
      success: (_) {
        ref.invalidate(deliveryDetailProvider(delivery.id));
        ref.invalidate(deliveryListProvider);
        if (context.mounted) context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery challan cancelled'), backgroundColor: Colors.red),
        );
      },
      failure: (err) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${err.message}'), backgroundColor: Colors.red),
      ),
    );
  }
}
```

**Validation**:
- Allow cancel only if: `status == 'DRAFT'` or `status == 'DISPATCHED'`
- Not allowed if `status == 'DELIVERED'` or `status == 'CANCELLED'`
- Backend restores stock on cancel

---

### 2.4 Delete Expense

**Screen**: `ExpenseListScreen` (`lib/features/expenses/presentation/screens/expense_list_screen.dart`)
**Card Widget**: Lines 165-218 (Card with expense details)
**Repository Method**: `ExpenseRepository.deleteExpense(int id)` (line 216)

**Implementation**:
```dart
// Option A: Swipe-to-delete (Dissmissible)
return Dismissible(
  key: ValueKey(exp.id),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    color: Colors.red,
    child: const Icon(Icons.delete, color: Colors.white),
  ),
  confirmDismiss: (direction) async {
    return await _confirmDelete(context, ref, exp.id);
  },
  onDismissed: (_) => _deleteExpense(context, ref, exp.id),
  child: Card(...), // existing card
);

// Option B: PopupMenuButton on card trailing
// Add trailing to Card or ListTile:
trailing: PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'delete') _confirmDelete(context, ref, exp.id);
  },
  itemBuilder: (context) => [
    const PopupMenuItem(value: 'delete', child: Text('Delete Expense')),
  ],
),

Future<bool?> _confirmDelete(BuildContext context, WidgetRef ref, int expenseId) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Expense?'),
      content: const Text('This voucher will be permanently removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

Future<void> _deleteExpense(BuildContext context, WidgetRef ref, int expenseId) async {
  final repo = ref.read(expenseRepositoryProvider);
  final result = await repo.deleteExpense(expenseId);
  result.when(
    success: (_) {
      ref.invalidate(expensesListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted'), backgroundColor: Colors.red),
      );
    },
    failure: (err) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: ${err.message}'), backgroundColor: Colors.red),
    ),
  );
}
```

---

### 2.5 Delete Waste/Scrap Entry

**Screen**: `WasteListScreen` (`lib/features/waste/presentation/screens/waste_list_screen.dart`)
**Card Widget**: `_WasteEntryCard` (line 273-350)
**Repository Method**: `WasteRepository.deleteEntry(int id)` (line 237)

**Implementation**: Same pattern as Expense - add `PopupMenuButton` or `Dismissible` to `_WasteEntryCard`

```dart
// In _WasteEntryCard build method - add trailing to Card or Row
trailing: PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'delete') _confirmDelete(context, ref, entry.id);
  },
  itemBuilder: (context) => [
    const PopupMenuItem(value: 'delete', child: Text('Delete Scrap Entry')),
  ],
  icon: const Icon(Icons.more_vert, size: 20),
),
```

---

### 2.6 Delete Waste Reason

**Screen**: `WasteReasonScreen` (`lib/features/waste/presentation/screens/waste_reason_screen.dart`)
**ListTile**: Lines 113-126 (no trailing actions)
**Repository Method**: `WasteRepository.deleteReason(int id)` (line 178)

**Implementation**:
```dart
// Modify ListTile (line 113-126) - add trailing PopupMenuButton
ListTile(
  leading: const CircleAvatar(...),
  title: Text(reason.reasonName, style: const TextStyle(fontWeight: FontWeight.bold)),
  subtitle: reason.description != null ? Text(reason.description!) : null,
  trailing: PopupMenuButton<String>(
    onSelected: (value) {
      if (value == 'edit') _showEditDialog(reason);
      if (value == 'delete') _confirmDelete(context, ref, reason.id);
    },
    itemBuilder: (context) => [
      const PopupMenuItem(value: 'edit', child: Text('Edit Reason')),
      const PopupMenuItem(value: 'delete', child: Text('Delete Reason')),
    ],
  ),
),
```

**Validation**:
- Prevent delete if reason is referenced by existing waste entries
- Backend should return 409/400 if referenced; UI shows error

---

### 2.7 Void Customer Payment

**Prerequisite**: Customer Payments List Screen must exist first (see Section 1.2)

**Implementation** (once list screen exists):
```dart
// In payment list tile - add PopupMenuButton
PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'void') _confirmVoid(context, ref, payment.id);
  },
  itemBuilder: (context) => [
    const PopupMenuItem(value: 'void', child: Text('Void Payment')),
  ],
),

Future<void> _confirmVoid(BuildContext context, WidgetRef ref, int paymentId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Void Payment?'),
      content: const Text('This will reverse the payment and reopen the invoice balance.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Void'),
        ),
      ],
    ),
  );
  
  if (confirmed == true && context.mounted) {
    final repo = ref.read(customerPaymentRepositoryProvider);
    final result = await repo.deletePayment(paymentId); // Verify method name
    // ... handle result
  }
}
```

---

## 3. Missing Edit/Modify Dialogs

### 3.1 Edit Waste Reason

**Screen**: `WasteReasonScreen` (`lib/features/waste/presentation/screens/waste_reason_screen.dart`)
**Current**: Only `_showAddDialog()` (lines 15-69)
**Repository Method**: `WasteRepository.updateReason(int id, WasteReasonDto reason)` - verify exists

**Implementation**:
```dart
// Add _showEditDialog method
void _showEditDialog(WasteReasonDto reason) {
  final nameCtrl = TextEditingController(text: reason.reasonName);
  final descCtrl = TextEditingController(text: reason.description ?? '');

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Waste Reason'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Reason Name *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;

            final updated = WasteReasonDto(
              id: reason.id,
              reasonName: name,
              description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            );

            final repo = ref.read(wasteRepositoryProvider);
            final result = await repo.updateReason(reason.id, updated);
            if (result.isSuccess && ctx.mounted) {
              Navigator.of(ctx).pop();
              ref.invalidate(activeWasteReasonsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Waste reason updated!'), backgroundColor: BrandColors.primary),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
          child: const Text('Save Changes'),
        ),
      ],
    ),
  );
}

// Hook to ListTile onTap or PopupMenu 'edit'
onTap: () => _showEditDialog(reason),
```

---

### 3.2 Edit Waste Entry

**Screen**: `WasteListScreen` (`lib/features/waste/presentation/screens/waste_list_screen.dart`)
**Card**: `_WasteEntryCard` (read-only)
**Repository Method**: `WasteRepository.updateEntry(int id, WasteEntryDto entry)` - verify exists

**Implementation**:
```dart
// Make _WasteEntryCard a ConsumerWidget or pass callback
// Add onTap to Card or trailing edit button

// In _WasteEntryCard:
class _WasteEntryCard extends ConsumerWidget {
  final WasteEntryDto entry;
  const _WasteEntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      // ... existing
      child: InkWell(
        onTap: () => _showEditDialog(context, ref, entry),
        // ... existing content
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, WasteEntryDto entry) {
    // Similar to WasteEntryFormScreen but prefilled
    // Navigate to /waste/edit/:id route (better) or show dialog
    context.push('/waste/edit/${entry.id}');
  }
}

// Better: Create WasteEntryFormScreen with optional entryId for edit mode
// Route: /waste/:id/edit
```

**Recommended Approach**: Reuse `WasteEntryFormScreen` with optional `entryId` parameter for edit mode.

```dart
// In router.dart
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/waste/:id/edit',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: WasteEntryFormScreen(entryId: id));
  },
),
```

---

### 3.3 Edit Customer Payment

**Prerequisite**: Customer Payments List Screen must exist

**Implementation**: Reuse `CustomerPaymentFormScreen` with `prefilledPayment` parameter

```dart
// Modify CustomerPaymentFormScreen to accept optional payment for edit
class CustomerPaymentFormScreen extends ConsumerStatefulWidget {
  final SaleDto? prefilledSale;
  final int? prefilledCustomerId;
  final CustomerPaymentDto? prefilledPayment; // NEW
  
  const CustomerPaymentFormScreen({
    super.key,
    this.prefilledSale,
    this.prefilledCustomerId,
    this.prefilledPayment,
  });
}

// In initState - populate from prefilledPayment if provided
// In _submit - use repo.updatePayment if prefilledPayment != null

// Route: /sales/payments/:id/edit
```

---

## 4. Common Implementation Patterns

### 4.1 Confirmation Dialog Helper

```dart
// lib/shared/widgets/confirm_dialog.dart
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color? confirmColor,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelText)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive ? Colors.red : (confirmColor ?? BrandColors.primary),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}
```

### 4.2 Repository Result Handling Pattern

```dart
// Standard pattern for all delete/update operations
final repo = ref.read(xyzRepositoryProvider);
final result = await repo.deleteXyz(id);

result.when(
  success: (_) {
    ref.invalidate(xyzListProvider);
    ref.invalidate(xyzDetailProvider(id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success message'), backgroundColor: BrandColors.primary),
      );
      // Navigate back if on detail screen
      context.pop();
    }
  },
  failure: (err) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${err.message}'), backgroundColor: Colors.red),
      );
    }
  },
);
```

### 4.3 Loading State During Mutation

```dart
bool _isDeleting = false;

// In dialog onPressed:
setState(() => _isDeleting = true);
final result = await repo.deleteXyz(id);
setState(() => _isDeleting = false);

// Disable button while loading
FilledButton(
  onPressed: _isDeleting ? null : () => _confirmDelete(),
  child: _isDeleting 
    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
    : const Text('Delete'),
)
```

---

## 5. Validation Rules

### 5.1 Delete Validations (Client-Side Pre-Checks)

| Entity | Allow Delete If | Block If |
|--------|-----------------|----------|
| Production Order | status == DRAFT or PLANNED | IN_PROGRESS, COMPLETED, CANCELLED |
| Sales Invoice | status != CANCELLED, status != VOIDED | Already voided/cancelled |
| Delivery Challan | status == DRAFT or DISPATCHED | DELIVERED, CANCELLED |
| Expense | Always (no status) | - |
| Waste Entry | Always | - |
| Waste Reason | Not referenced by entries | Referenced (backend 409) |
| Customer Payment | Not yet reconciled | Reconciled (backend check) |
| Vendor Payment | Not yet reconciled | Reconciled (backend check) |

### 5.2 Edit Validations

| Entity | Required Fields | Business Rules |
|--------|----------------|----------------|
| Waste Reason | reasonName (non-empty) | Unique name (backend) |
| Waste Entry | productId, quantity > 0, wasteReasonId, wasteDate | Quantity ≤ available stock (if tracked) |
| Customer Payment | customerId, saleId, amount > 0, paymentMethodId, paymentDate | Amount ≤ outstanding balance (warn only) |
| Vendor Payment | supplierId, purchaseId, amount > 0, paymentMethodId, paymentDate | Amount ≤ PO outstanding (warn only) |

---

## 6. E2E Navigation & Routes

### 6.1 New Routes to Add in `router.dart`

```dart
// Audit Logs (System Administration)
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/audit-logs',
  builder: (context, state) => const RouteGuard(child: AuditLogListScreen()),
),
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/audit-logs/:id',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: AuditLogDetailScreen(auditLogId: id));
  },
),

// Customer Payment Receipt
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/sales/payments/:id',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: CustomerPaymentDetailScreen(paymentId: id));
  },
),
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/sales/payments/:id/edit',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: CustomerPaymentFormScreen(prefilledPaymentId: id));
  },
),

// Vendor Payment Receipt
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/purchases/payments/:id',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: VendorPaymentDetailScreen(paymentId: id));
  },
),
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/purchases/payments/:id/edit',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: VendorPaymentFormScreen(prefilledPaymentId: id));
  },
),

// Waste Entry Edit
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/waste/:id/edit',
  builder: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
    return RouteGuard(child: WasteEntryFormScreen(entryId: id));
  },
),
```

### 6.2 MoreMenuScreen Integration

Add to "System Administration & Security" section (around line 323):

```dart
_MenuItem(
  icon: Icons.history_outlined,
  title: 'Audit Logs & Activity History',
  subtitle: 'Track all data changes across the system',
  route: '/audit-logs',
  color: const Color(0xFF37474F),
),
```

### 6.3 Navigation Flow Diagrams

```
ProductionOrderListScreen
  → _ProductionOrderCard (tap) → /production/:id/track (ProductionStageTrackerScreen)
  → _ProductionOrderCard (menu: Delete) → Confirm → DELETE /api/production-orders/:id → refresh list

SalesDetailScreen
  → AppBar menu: Void → Confirm → DELETE /api/sales/:id → pop to SalesListScreen
  → Payment history ListTile (tap) → /sales/payments/:id (CustomerPaymentDetailScreen)

DeliveryDetailScreen
  → Cancel button (if DRAFT/DISPATCHED) → Confirm → DELETE /api/deliveries/:id → pop to DispatchHistoryScreen

ExpenseListScreen
  → Expense Card (swipe/menu: Delete) → Confirm → DELETE /api/expenses/:id → refresh list

WasteListScreen
  → WasteEntryCard (tap) → /waste/:id/edit (WasteEntryFormScreen in edit mode)
  → WasteEntryCard (menu: Delete) → Confirm → DELETE /api/waste-entries/:id → refresh list

WasteReasonScreen
  → Reason ListTile (tap/menu: Edit) → Dialog /waste/reasons (edit inline)
  → Reason ListTile (menu: Delete) → Confirm → DELETE /api/waste-reasons/:id → refresh list

CustomerPaymentDetailScreen (NEW)
  → From SalesDetailScreen payment history tap
  → Menu: Edit → /sales/payments/:id/edit (CustomerPaymentFormScreen)
  → Menu: Void → Confirm → DELETE /api/customer-payments/:id → pop
```

---

## 7. Testing Checklist

### 7.1 Unit Tests (Repository Layer)

```dart
// For each repository delete/update method:
group('ProductionRepository', () {
  test('deleteProductionOrder calls correct endpoint', () async {
    // Mock client, verify DELETE /api/production-orders/123
  });
  
  test('deleteProductionOrder returns Success on 200', () async {
    // Mock 200 response, expect Success(true)
  });
  
  test('deleteProductionOrder returns Failure on 404', () async {
    // Mock 404, expect ServerFailure
  });
});
```

### 7.2 Widget Tests (Screen Layer)

```dart
// ProductionOrderListScreen
testWidgets('shows delete option in production order card menu', (tester) async {
  await tester.pumpWidget(appWithProviders(ProductionOrderListScreen()));
  await tester.tap(find.byIcon(Icons.more_vert).first);
  await tester.pumpAndSettle();
  expect(find.text('Cancel / Delete Order'), findsOneWidget);
});

testWidgets('delete confirmation dialog appears', (tester) async {
  // ... tap delete, verify AlertDialog shows
});

testWidgets('successful delete shows snackbar and refreshes list', (tester) async {
  // Mock repo success, verify snackbar and list update
});
```

### 7.3 Integration/E2E Tests (flutter_driver / integration_test)

```dart
// integration_test/delete_flows_test.dart
group('Delete Flows', () {
  testWidgets('User can delete a production order in draft status', (tester) async {
    await app.start();
    await login();
    await navigateTo('/production');
    await createProductionOrder(status: 'DRAFT');
    await openOrderMenu(0);
    await tapMenuItem('Cancel / Delete Order');
    await confirmDialog('Delete');
    expect(find.text('Production order deleted'), findsOneWidget);
    expect(find.text('PROD-001'), findsNothing); // Removed from list
  });

  testWidgets('User cannot delete completed production order', (tester) async {
    // Create COMPLETED order, verify delete option hidden/disabled
  });

  testWidgets('User can void sales invoice with no payments', (tester) async {
    // Create DRAFT sale, void it, verify removed
  });

  testWidgets('User sees warning when voiding paid invoice', (tester) async {
    // Create sale with payment, void shows warning about reversal
  });
});
```

### 7.4 Manual Testing Checklist

| Feature | Test Case | Expected |
|---------|-----------|----------|
| **Audit Logs List** | Navigate to `/audit-logs` | List loads with filters |
| | Filter by table name | Results filtered |
| | Tap row → detail | Detail screen opens |
| **Customer Payment Detail** | From SalesDetail, tap payment | Opens receipt detail |
| | Print/Share buttons visible | UI present (functional later) |
| **Delete Production Order** | Draft order → menu → delete | Success snackbar, list refreshes |
| | Completed order → menu | Delete option hidden |
| **Void Sales Invoice** | Draft invoice → void | Removed from list |
| | Paid invoice → void | Warning shown, proceeds on confirm |
| **Cancel Delivery** | DRAFT challan → cancel | Stock released, status CANCELLED |
| | DELIVERED challan → cancel | Button hidden |
| **Delete Expense** | Swipe/delete → confirm | Removed from list |
| **Delete Waste Entry** | Tap entry → menu → delete | Removed, metrics update |
| **Edit Waste Reason** | Tap reason → edit → save | Name updated in list |
| **Edit Waste Entry** | Tap entry → edit form → save | Updated in list |
| **Navigation** | All new routes accessible | No 404, proper guards |
| | Back navigation works | Returns to correct list |

---

## 8. File Creation Summary

### New Files Needed (11 screens)

| # | File | Purpose |
|---|------|---------|
| 1 | `lib/features/inventory/presentation/screens/audit_log_list_screen.dart` | Audit logs list |
| 2 | `lib/features/inventory/presentation/screens/audit_log_detail_screen.dart` | Audit log detail |
| 3 | `lib/features/sales/presentation/screens/customer_payment_detail_screen.dart` | Customer payment receipt |
| 4 | `lib/features/purchasing/presentation/screens/vendor_payment_detail_screen.dart` | Vendor payment receipt |
| 5 | `lib/features/sales/presentation/screens/customer_payments_list_screen.dart` | **NEW** - List screen for customer payments (prereq for void) |
| 6 | `lib/features/purchasing/presentation/screens/vendor_payments_list_screen.dart` | **NEW** - List screen for vendor payments |

### Modified Files (7 existing screens)

| # | File | Changes |
|---|------|---------|
| 1 | `lib/features/production/presentation/screens/production_order_list_screen.dart` | Add delete menu to `_ProductionOrderCard` |
| 2 | `lib/features/sales/presentation/screens/sales_detail_screen.dart` | Add void menu to AppBar |
| 3 | `lib/features/dispatch/presentation/screens/delivery_detail_screen.dart` | Add cancel button for DRAFT/DISPATCHED |
| 4 | `lib/features/expenses/presentation/screens/expense_list_screen.dart` | Add swipe/menu delete to expense cards |
| 5 | `lib/features/waste/presentation/screens/waste_list_screen.dart` | Add edit navigation + delete menu to `_WasteEntryCard` |
| 6 | `lib/features/waste/presentation/screens/waste_reason_screen.dart` | Add edit dialog + delete menu to ListTile |
| 7 | `lib/app/router.dart` | Add 9 new routes |
| 8 | `lib/features/home/presentation/screens/more_menu_screen.dart` | Add Audit Logs menu item |

### Shared Helper (1 new file)

| # | File | Purpose |
|---|------|---------|
| 1 | `lib/shared/widgets/confirm_dialog.dart` | Reusable confirmation dialog |

---

## 9. Implementation Priority Order

| Priority | Items | Rationale |
|----------|-------|-----------|
| **P0** (Blockers) | Customer Payments List Screen, Vendor Payments List Screen | Required for void payment feature |
| **P1** (High Value) | Audit Logs List/Detail, Delete Production Order, Void Sales, Cancel Delivery | Core business actions |
| **P2** (Medium) | Delete Expense, Delete Waste Entry/Reason, Edit Waste Reason/Entry | Operational completeness |
| **P3** (Polish) | Customer/Vendor Payment Receipt Detail, Edit Payment | UX improvement |

---

## 10. Dependencies & Prerequisites

- **Riverpod providers** already exist for all repositories
- **RouteGuard** and **AppShellScaffold** patterns established
- **Theme tokens** (BrandColors, Spacing, Radii) consistent
- **SnackBar** pattern for feedback established
- **Confirmation dialog** pattern to be extracted to shared widget

---

*End of Implementation Guide*