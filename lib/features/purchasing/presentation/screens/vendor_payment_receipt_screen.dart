import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/purchasing/data/models/vendor_payment_dto.dart';

class VendorPaymentReceiptScreen extends ConsumerWidget {
  final int paymentId;

  const VendorPaymentReceiptScreen({super.key, required this.paymentId});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, VendorPaymentDto payment) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vendor Payout Record?'),
        content: Text(
          'Payout voucher "${payment.paymentNumber}" for ₹${payment.amount.toStringAsFixed(2)} will be permanently deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Deleting payout record...')),
              );

              final result = await ref.read(vendorPaymentRepositoryProvider).delete(payment.id);
              result.when(
                success: (_) {
                  ref.invalidate(vendorPaymentsListProvider(payment.purchaseId));
                  ref.invalidate(purchaseDetailProvider(payment.purchaseId));
                  ref.invalidate(vendorPaymentDetailProvider(payment.id));
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Vendor payout record deleted successfully'),
                      backgroundColor: BrandColors.primary,
                    ),
                  );
                  if (context.mounted) {
                    context.pop();
                  }
                },
                failure: (err) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: ${err.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(vendorPaymentDetailProvider(paymentId));
    final suppliers = ref.watch(activeSuppliersProvider).valueOrNull;
    final paymentMethods = ref.watch(activePaymentMethodsProvider).valueOrNull;
    final purchases = ref.watch(purchasesListProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payment Voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (paymentAsync.valueOrNull?.paymentNumber.isNotEmpty == true)
              Text(
                paymentAsync.valueOrNull!.paymentNumber,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async {
          ref.invalidate(vendorPaymentDetailProvider(paymentId));
          try {
            await ref.read(vendorPaymentDetailProvider(paymentId).future);
          } catch (_) {}
        },
        child: paymentAsync.when(
          data: (payment) {
            final resolvedSupplier = (payment.supplierName != null && !payment.supplierName!.startsWith('Supplier #'))
                ? payment.supplierName!
                : (suppliers?.where((s) => s.id == payment.supplierId).firstOrNull?.supplierName ?? 'Supplier #${payment.supplierId}');
            final resolvedMethod = (payment.paymentMethodName != null && payment.paymentMethodName!.isNotEmpty)
                ? payment.paymentMethodName!
                : (paymentMethods?.where((m) => m.id == payment.paymentMethodId).firstOrNull?.methodName ?? 'Direct Payout');
            final resolvedPONumber = (payment.purchaseNumber != null && payment.purchaseNumber!.isNotEmpty)
                ? payment.purchaseNumber!
                : (purchases?.where((po) => po.id == payment.purchaseId).firstOrNull?.purchaseNumber ?? 'PO #${payment.purchaseId}');

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Receipt Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(Icons.payments_outlined, color: Color(0xFF673AB7), size: 36),
                        ),
                        const SizedBox(height: Spacing.sm),
                        const Text(
                          'Vendor Payout Sent',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voucher: ${payment.paymentNumber}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // Details Card
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
                        const Text('Payout Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Divider(height: 20),
                        _buildRow('Supplier / Vendor', resolvedSupplier),
                        const SizedBox(height: 10),
                        _buildRow('Purchase Order', resolvedPONumber),
                        const SizedBox(height: 10),
                        _buildRow('Payment Mode', resolvedMethod),
                        const SizedBox(height: 10),
                        _buildRow(
                          'Payment Date',
                          '${payment.paymentDate.day.toString().padLeft(2, '0')}/${payment.paymentDate.month.toString().padLeft(2, '0')}/${payment.paymentDate.year}',
                        ),
                      if (payment.referenceNo != null && payment.referenceNo!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildRow('UTR / Reference #', payment.referenceNo!),
                      ],
                      if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildRow('Remarks', payment.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Delete Action Button
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete Payout Record', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                ),
                onPressed: () => _showDeleteConfirmation(context, ref, payment),
              ),
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
            child: Center(child: Text('Error loading payout: $err')),
          ),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }
}
