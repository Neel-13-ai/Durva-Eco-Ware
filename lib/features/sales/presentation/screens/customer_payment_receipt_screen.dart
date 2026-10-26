import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';

class CustomerPaymentReceiptScreen extends ConsumerWidget {
  final int paymentId;

  const CustomerPaymentReceiptScreen({super.key, required this.paymentId});

  void _showEditDialog(BuildContext context, WidgetRef ref, CustomerPaymentDto payment) {
    final receiptCtrl = TextEditingController(text: payment.receiptNumber);
    final amountCtrl = TextEditingController(text: payment.amount.toStringAsFixed(2));
    final refCtrl = TextEditingController(text: payment.referenceNo ?? '');
    final notesCtrl = TextEditingController(text: payment.notes ?? '');
    DateTime paymentDate = payment.paymentDate;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Payment Receipt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: receiptCtrl,
                decoration: const InputDecoration(labelText: 'Receipt Number *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: Spacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Payment Date'),
                subtitle: Text('${paymentDate.day}/${paymentDate.month}/${paymentDate.year}'),
                leading: const Icon(Icons.calendar_today, color: BrandColors.primary),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null && ctx.mounted) {
                      paymentDate = picked;
                      (ctx as Element).markNeedsBuild();
                    }
                  },
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Bank Reference #', border: OutlineInputBorder()),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final receipt = receiptCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (receipt.isEmpty || amount <= 0) return;
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(const SnackBar(content: Text('Updating payment...')));

              final updated = CustomerPaymentDto(
                id: payment.id,
                receiptNumber: receipt,
                customerId: payment.customerId,
                saleId: payment.saleId,
                paymentDate: paymentDate,
                amount: amount,
                paymentMethodId: payment.paymentMethodId,
                referenceNo: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              );

              final result = await ref.read(customerPaymentRepositoryProvider).updateCustomerPayment(payment.id, updated);
              if (!context.mounted) return;
              result.when(
                success: (_) {
                  ref.invalidate(allCustomerPaymentsProvider);
                  ref.invalidate(salePaymentsProvider(payment.saleId));
                  ref.invalidate(saleDetailProvider(payment.saleId));
                  ref.invalidate(customerPaymentDetailProvider(payment.id));
                  messenger.showSnackBar(const SnackBar(content: Text('Payment updated successfully'), backgroundColor: BrandColors.primary));
                  ref.invalidate(customerPaymentDetailProvider(payment.id));
                },
                failure: (err) => messenger.showSnackBar(SnackBar(content: Text('Failed to update: ${err.message}'), backgroundColor: Colors.red)),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showVoidConfirmation(BuildContext context, WidgetRef ref, CustomerPaymentDto payment) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Customer Payment?'),
        content: Text(
          'Receipt "${payment.receiptNumber}" (₹${payment.amount.toStringAsFixed(2)}) will be voided. The linked invoice outstanding balance will increase by this amount.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Voiding payment receipt...')),
              );

              final result = await ref.read(customerPaymentRepositoryProvider).deleteCustomerPayment(payment.id);
              result.when(
                success: (_) {
                  ref.invalidate(allCustomerPaymentsProvider);
                  ref.invalidate(salePaymentsProvider(payment.saleId));
                  ref.invalidate(saleDetailProvider(payment.saleId));
                  ref.invalidate(customerPaymentDetailProvider(payment.id));
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Payment voided successfully. Invoice balance restored.'),
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
                      content: Text('Failed to void payment: ${err.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
            child: const Text('Void Payment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(customerPaymentDetailProvider(paymentId));
    final customers = ref.watch(activeCustomersProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Receipt #$paymentId'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final payment = ref.read(customerPaymentDetailProvider(paymentId)).value;
              if (payment != null) _showEditDialog(context, ref, payment);
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.invalidate(customerPaymentDetailProvider(paymentId)),
        child: paymentAsync.when(
          data: (payment) {
            final customerDisplay = (payment.customerName != null && payment.customerName!.isNotEmpty && !payment.customerName!.startsWith('Customer #'))
                ? payment.customerName!
                : (customers?.where((c) => c.id == payment.customerId).firstOrNull?.customerName ?? 'Customer #${payment.customerId}');

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
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 36),
                      ),
                      const SizedBox(height: Spacing.sm),
                      const Text(
                        'Payment Received',
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
                        'Receipt: ${payment.receiptNumber}',
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
                      const Text('Transaction Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Divider(height: 20),
                      _buildRow('Customer', customerDisplay),
                      const SizedBox(height: 10),
                      _buildRow('Linked Invoice', payment.invoiceNumber ?? 'Invoice #${payment.saleId}'),
                      const SizedBox(height: 10),
                      _buildRow('Payment Mode', payment.paymentMethodName ?? 'Direct Transfer'),
                      const SizedBox(height: 10),
                      _buildRow(
                        'Payment Date',
                        '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
                      ),
                      if (payment.referenceNo != null && payment.referenceNo!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildRow('Bank Reference #', payment.referenceNo!),
                      ],
                      if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildRow('Notes', payment.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Void Action Button
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Void / Reverse Payment Receipt', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                ),
                onPressed: () => _showVoidConfirmation(context, ref, payment),
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
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(child: Text('Error loading receipt: $err')),
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
