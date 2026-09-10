import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/purchasing/application/controllers/vendor_payment_controller.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/purchasing/data/models/vendor_payment_dto.dart';

class VendorPaymentFormScreen extends ConsumerStatefulWidget {
  const VendorPaymentFormScreen({super.key, required this.purchaseId});

  final int purchaseId;

  @override
  ConsumerState<VendorPaymentFormScreen> createState() => _VendorPaymentFormScreenState();
}

class _VendorPaymentFormScreenState extends ConsumerState<VendorPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountCtrl;
  late TextEditingController _refCtrl;
  late TextEditingController _notesCtrl;
  int? _selectedMethodId;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _refCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    Future.microtask(() async {
      final po = await ref.read(purchaseDetailProvider(widget.purchaseId).future);
      _amountCtrl.text = po.outstandingBalance.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(vendorPaymentControllerProvider);
    final poAsync = ref.watch(purchaseDetailProvider(widget.purchaseId));
    final paymentMethodsAsync = ref.watch(activePaymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Vendor Payment'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: paymentState.isLoading
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final po = poAsync.value;
                      if (po == null || _selectedMethodId == null) return;

                      final payment = VendorPaymentDto(
                        id: 0,
                        paymentNumber: 'VP/${DateTime.now().millisecondsSinceEpoch % 10000}',
                        supplierId: po.supplierId,
                        supplierName: po.supplierName,
                        purchaseId: po.id,
                        purchaseNumber: po.purchaseNumber,
                        paymentDate: DateTime.now(),
                        amount: double.tryParse(_amountCtrl.text) ?? 0.0,
                        paymentMethodId: _selectedMethodId!,
                        referenceNo: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
                        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                      );

                      final ok = await ref.read(vendorPaymentControllerProvider.notifier).submitPayment(payment);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment recorded successfully!'),
                            backgroundColor: BrandColors.primary,
                          ),
                        );
                        context.pop();
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
            ),
            child: paymentState.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('CONFIRM PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              poAsync.when(
                data: (po) {
                  return Container(
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
                        Text('PO Number: ${po.purchaseNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Vendor: ${po.supplierName ?? "Supplier"}', style: const TextStyle(color: Color(0xFF64748B))),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Bill:', style: TextStyle(color: Color(0xFF64748B))),
                            Text('₹${po.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Outstanding Balance:', style: TextStyle(color: Color(0xFF64748B))),
                            Text('₹${po.outstandingBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (₹) *',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final amt = double.tryParse(v ?? '');
                  if (amt == null || amt <= 0) return 'Valid amount is required';
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),

              paymentMethodsAsync.when(
                data: (methods) => DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Payment Mode *', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                  items: methods.map((m) => DropdownMenuItem(value: m.id, child: Text(m.methodName, overflow: TextOverflow.ellipsis))).toList(),
                  validator: (v) => (v == null || v <= 0) ? 'Payment mode is required' : null,
                  onChanged: (val) => setState(() => _selectedMethodId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading payment methods'),
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Transaction Reference / UTR / Cheque No.',
                  hintText: 'UPI-12345678 or Cheque #8812',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes / Remarks',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
