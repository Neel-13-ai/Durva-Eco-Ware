import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/purchasing/data/models/purchase_dto.dart';

class PurchaseDetailScreen extends ConsumerWidget {
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  final int purchaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseAsync = ref.watch(purchaseDetailProvider(purchaseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order Details'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: purchaseAsync.when(
        data: (po) {
          return SingleChildScrollView(
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            po.purchaseNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BrandColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Text(
                              po.status.name.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: BrandColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _InfoRow(label: 'Supplier', value: po.supplierName ?? 'Supplier #${po.supplierId}'),
                      _InfoRow(label: 'Warehouse', value: po.warehouseName ?? 'Warehouse #${po.warehouseId}'),
                      _InfoRow(label: 'Order Date', value: '${po.purchaseDate.day}/${po.purchaseDate.month}/${po.purchaseDate.year}'),
                      _InfoRow(label: 'Total Amount', value: '₹${po.totalAmount.toStringAsFixed(2)}'),
                      _InfoRow(label: 'Paid Amount', value: '₹${po.paidAmount.toStringAsFixed(2)}'),
                      _InfoRow(label: 'Balance Due', value: '₹${po.outstandingBalance.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // Action Buttons Row
                Row(
                  children: [
                    if (po.status == PurchaseStatus.pending || po.status == PurchaseStatus.draft)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await ref.read(purchaseRepositoryProvider).updateStatus(po.id, PurchaseStatus.approved);
                            if (ok.isSuccess) {
                              ref.invalidate(purchaseDetailProvider(po.id));
                              ref.invalidate(purchasesListProvider);
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve PO'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                        ),
                      ),
                    if (po.status == PurchaseStatus.approved || po.status == PurchaseStatus.partiallyReceived) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/purchases/${po.id}/grn'),
                          icon: const Icon(Icons.inventory),
                          label: const Text('Confirm GRN'),
                          style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (!po.isFullyPaid)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/purchases/${po.id}/pay'),
                          icon: const Icon(Icons.payment),
                          label: const Text('Pay Vendor'),
                          style: OutlinedButton.styleFrom(foregroundColor: BrandColors.primary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // Line Items
                const Text('Raw Material Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: Spacing.sm),
                ...po.items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: Spacing.sm),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        title: Text(item.productName ?? 'Product #${item.productId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Qty: ${item.quantity} • Rate: ₹${item.unitCost.toStringAsFixed(2)} • Recv: ${item.receivedQuantity}'),
                        trailing: Text('₹${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
