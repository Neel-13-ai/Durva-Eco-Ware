import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';

class CustomerPaymentListScreen extends ConsumerStatefulWidget {
  const CustomerPaymentListScreen({super.key});

  @override
  ConsumerState<CustomerPaymentListScreen> createState() => _CustomerPaymentListScreenState();
}

class _CustomerPaymentListScreenState extends ConsumerState<CustomerPaymentListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(allCustomerPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Payments'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push('/sales/payments/new'),
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Record Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search receipt #, customer, or invoice...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),

          // Payments List
          Expanded(
            child: RefreshIndicator(
              color: BrandColors.primary,
              onRefresh: () async => ref.invalidate(allCustomerPaymentsProvider),
              child: paymentsAsync.when(
                data: (payments) {
                  final filtered = payments.where((p) {
                    if (_search.isEmpty) return true;
                    final matchReceipt = p.receiptNumber.toLowerCase().contains(_search);
                    final matchCustomer = p.customerName?.toLowerCase().contains(_search) ?? false;
                    final matchInvoice = p.invoiceNumber?.toLowerCase().contains(_search) ?? false;
                    return matchReceipt || matchCustomer || matchInvoice;
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text('No customer payment records found.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                    itemBuilder: (ctx, index) {
                      final payment = filtered[index];
                      return _PaymentCard(payment: payment);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
                error: (err, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(child: Text('Error loading payments: $err')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends ConsumerWidget {
  const _PaymentCard({required this.payment});
  final CustomerPaymentDto payment;

  void _showEditDialog(BuildContext context, WidgetRef ref) {
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

  void _showVoidConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Customer Payment?'),
        content: Text('Receipt "${payment.receiptNumber}" (₹${payment.amount.toStringAsFixed(2)}) will be voided. The linked invoice outstanding balance will increase by this amount.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(const SnackBar(content: Text('Voiding payment...')));

              final result = await ref.read(customerPaymentRepositoryProvider).deleteCustomerPayment(payment.id);
              if (!context.mounted) return;
              result.when(
                success: (_) {
                  ref.invalidate(allCustomerPaymentsProvider);
                  ref.invalidate(salePaymentsProvider(payment.saleId));
                  ref.invalidate(saleDetailProvider(payment.saleId));
                  ref.invalidate(customerPaymentDetailProvider(payment.id));
                  messenger.showSnackBar(const SnackBar(content: Text('Payment voided successfully. Invoice balance restored.'), backgroundColor: BrandColors.primary));
                },
                failure: (err) => messenger.showSnackBar(SnackBar(content: Text('Failed to void: ${err.message}'), backgroundColor: Colors.red)),
              );
            },
            child: const Text('Void Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(activeCustomersProvider).valueOrNull;
    final customerDisplay = (payment.customerName != null && payment.customerName!.isNotEmpty && !payment.customerName!.startsWith('Customer #'))
        ? payment.customerName!
        : (customers?.where((c) => c.id == payment.customerId).firstOrNull?.customerName ?? 'Customer #${payment.customerId}');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => context.push('/sales/payments/${payment.id}'),
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payment.receiptNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF94A3B8)),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditDialog(context, ref);
                      } else if (val == 'void') {
                        _showVoidConfirmation(context, ref);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: BrandColors.primary), SizedBox(width: 8), Text('Edit Payment')]),
                      ),
                      const PopupMenuItem(
                        value: 'void',
                        child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Void Payment', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                customerDisplay,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice: ${payment.invoiceNumber ?? "#${payment.saleId}"}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  Text(
                    '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year} • ${payment.paymentMethodName ?? "Paid"}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
