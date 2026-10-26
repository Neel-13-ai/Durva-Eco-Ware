import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/purchasing/data/models/purchase_dto.dart';

class PurchaseDetailScreen extends ConsumerWidget {
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  final int purchaseId;

  Color _statusColor(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.draft:
        return const Color(0xFF64748B);
      case PurchaseStatus.pending:
        return const Color(0xFFE65100);
      case PurchaseStatus.approved:
        return const Color(0xFF1565C0);
      case PurchaseStatus.partiallyReceived:
        return const Color(0xFF00796B);
      case PurchaseStatus.received:
        return const Color(0xFF2E7D32);
      case PurchaseStatus.cancelled:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseAsync = ref.watch(purchaseDetailProvider(purchaseId));
    final suppliers = ref.watch(activeSuppliersProvider).valueOrNull;
    final warehouses = ref.watch(activeWarehousesProvider).valueOrNull;
    final products = ref.watch(productsListProvider).valueOrNull;
    final paymentMethods = ref.watch(activePaymentMethodsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PO Details'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          purchaseAsync.whenOrNull(
                data: (po) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit PO',
                      onPressed: () => context.push('/purchases/${po.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete PO',
                      onPressed: () => _confirmDelete(context, ref, po),
                    ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async {
          ref.invalidate(purchaseDetailProvider(purchaseId));
          ref.invalidate(vendorPaymentsListProvider(purchaseId));
          ref.invalidate(activeSuppliersProvider);
          try {
            await ref.read(purchaseDetailProvider(purchaseId).future);
          } catch (_) {}
        },
        child: purchaseAsync.when(
          data: (po) {
            final statusCol = _statusColor(po.status);
            final supplierName = (po.supplierName != null && !po.supplierName!.startsWith('Supplier #'))
                ? po.supplierName!
                : (suppliers?.where((s) => s.id == po.supplierId).firstOrNull?.supplierName ?? 'Supplier #${po.supplierId}');
            final warehouseName = (po.warehouseName != null && !po.warehouseName!.startsWith('Warehouse #'))
                ? po.warehouseName!
                : (warehouses?.where((w) => w.id == po.warehouseId).firstOrNull?.name ?? 'Warehouse #${po.warehouseId}');

            final recordedPayments = ref.watch(vendorPaymentsListProvider(po.id)).valueOrNull ?? [];
            final computedPaidAmount = recordedPayments.isNotEmpty
                ? recordedPayments.fold<double>(0.0, (sum, p) => sum + p.amount)
                : po.paidAmount;
            final effectivePaidAmount = computedPaidAmount > po.paidAmount ? computedPaidAmount : po.paidAmount;
            final effectiveBalance = (po.totalAmount - effectivePaidAmount).clamp(0.0, double.infinity);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              po.purchaseNumber,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusCol.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Text(
                              po.status.name.toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusCol),
                            ),
                          ),
                          if (effectivePaidAmount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (effectiveBalance <= 0.01) ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(Radii.sm),
                              ),
                              child: Text(
                                (effectiveBalance <= 0.01) ? 'PAID' : 'PARTIAL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: (effectiveBalance <= 0.01) ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 20),
                      _InfoRow(label: 'Supplier', value: supplierName),
                      _InfoRow(label: 'Warehouse', value: warehouseName),
                      _InfoRow(
                        label: 'Order Date',
                        value: '${po.purchaseDate.day.toString().padLeft(2, '0')}/${po.purchaseDate.month.toString().padLeft(2, '0')}/${po.purchaseDate.year}',
                      ),
                      if (po.expectedDeliveryDate != null)
                        _InfoRow(
                          label: 'Expected Delivery',
                          value: '${po.expectedDeliveryDate!.day.toString().padLeft(2, '0')}/${po.expectedDeliveryDate!.month.toString().padLeft(2, '0')}/${po.expectedDeliveryDate!.year}',
                        ),
                      if (po.referenceNo != null && po.referenceNo!.isNotEmpty)
                        _InfoRow(label: 'Reference / Quotation', value: po.referenceNo!),
                      if (po.notes != null && po.notes!.isNotEmpty)
                        _InfoRow(label: 'Notes / Remarks', value: po.notes!),
                      const Divider(height: 20),
                      _InfoRow(label: 'Total Amount', value: '₹${po.totalAmount.toStringAsFixed(2)}'),
                      _InfoRow(label: 'Paid Amount', value: '₹${effectivePaidAmount.toStringAsFixed(2)}'),
                      _InfoRow(
                        label: 'Balance Due',
                        value: '₹${effectiveBalance.toStringAsFixed(2)}',
                        valueColor: effectiveBalance > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // Action Buttons Row
                Row(
                  children: [
                    if (po.status == PurchaseStatus.pending || po.status == PurchaseStatus.draft) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await ref.read(purchaseRepositoryProvider).updateStatus(po.id, PurchaseStatus.approved);
                            if (ok.isSuccess) {
                              ref.invalidate(purchaseDetailProvider(po.id));
                              ref.invalidate(purchasesListProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Purchase Order approved successfully'),
                                    backgroundColor: BrandColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else if (context.mounted) {
                              final err = ok.failureOrNull?.message ?? 'Failed to approve Purchase Order';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(err),
                                  backgroundColor: SemanticColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Approve PO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (po.status == PurchaseStatus.approved || po.status == PurchaseStatus.partiallyReceived) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/purchases/${po.id}/grn'),
                          icon: const Icon(Icons.inventory, size: 18),
                          label: const Text('Confirm GRN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (!po.isFullyPaid)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/purchases/${po.id}/pay'),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Pay Vendor'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BrandColors.primary,
                            side: const BorderSide(color: BrandColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // Line Items Section
                Row(
                  children: [
                    const Text('Raw Material Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${po.items.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),

                if (po.items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No raw material items recorded for this purchase order.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...po.items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: Spacing.sm),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          title: Text(
                            (item.productName != null && !item.productName!.startsWith('Product #'))
                                ? item.productName!
                                : (products?.where((p) => p.id == item.productId).firstOrNull?.name ?? 'Product #${item.productId}'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Qty: ${item.quantity} ${(item.unitName != null && item.unitName!.isNotEmpty) ? item.unitName! : "Units"} • Rate: ₹${item.unitCost.toStringAsFixed(2)} • Recv: ${item.receivedQuantity}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: Text('₹${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      )),
                const SizedBox(height: Spacing.md),

                // Vendor Payments History Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment History & Vouchers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary)),
                        const SizedBox(height: Spacing.sm),
                        ref.watch(vendorPaymentsListProvider(po.id)).when(
                              data: (payments) {
                                if (payments.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text('No payments recorded yet for this purchase order.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: payments.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (ctx, index) {
                                    final p = payments[index];
                                    final pMethod = (p.paymentMethodName != null && p.paymentMethodName!.isNotEmpty)
                                        ? p.paymentMethodName!
                                        : (paymentMethods?.where((m) => m.id == p.paymentMethodId).firstOrNull?.methodName ?? "Direct Payout");

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const CircleAvatar(
                                        backgroundColor: Color(0xFFE8F5E9),
                                        foregroundColor: Color(0xFF2E7D32),
                                        radius: 16,
                                        child: Icon(Icons.check, size: 16),
                                      ),
                                      title: Text(p.paymentNumber.isNotEmpty ? p.paymentNumber : 'Voucher #${p.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text(
                                        '${p.paymentDate.day.toString().padLeft(2, '0')}/${p.paymentDate.month.toString().padLeft(2, '0')}/${p.paymentDate.year} • $pMethod',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('₹${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                                        ],
                                      ),
                                      onTap: () => context.push('/purchases/payments/${p.id}'),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))),
                              error: (e, _) => Text('Failed to load payments: $e', style: const TextStyle(color: Colors.red)),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, PurchaseDto po) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase Order'),
        content: Text('Are you sure you want to delete purchase order ${po.purchaseNumber}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: SemanticColors.danger, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final res = await ref.read(purchaseRepositoryProvider).delete(po.id);
      if (res.isSuccess && context.mounted) {
        ref.invalidate(purchasesListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase Order deleted successfully'),
            backgroundColor: BrandColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      } else if (context.mounted) {
        final err = res.failureOrNull?.message ?? 'Failed to delete Purchase Order';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: SemanticColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
