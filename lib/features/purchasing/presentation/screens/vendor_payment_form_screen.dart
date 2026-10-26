import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/payment_method_dto.dart';
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
  DateTime _paymentDate = DateTime.now();

  static const List<PaymentMethodDto> _fallbackMethods = [
    PaymentMethodDto(id: 1, methodName: 'Bank Transfer', isActive: true),
    PaymentMethodDto(id: 2, methodName: 'Cash', isActive: true),
    PaymentMethodDto(id: 3, methodName: 'UPI', isActive: true),
    PaymentMethodDto(id: 4, methodName: 'Cheque', isActive: true),
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _refCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
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
    final suppliers = ref.watch(activeSuppliersProvider).valueOrNull;
    final recordedPayments = ref.watch(vendorPaymentsListProvider(widget.purchaseId)).valueOrNull ?? [];

    final po = poAsync.valueOrNull;
    final computedPaidAmount = (recordedPayments.isNotEmpty)
        ? recordedPayments.fold<double>(0.0, (sum, p) => sum + p.amount)
        : (po?.paidAmount ?? 0.0);
    final effectivePaidAmount = (po != null && computedPaidAmount > po.paidAmount) ? computedPaidAmount : (po?.paidAmount ?? 0.0);
    final effectiveBalance = po != null ? (po.totalAmount - effectivePaidAmount).clamp(0.0, double.infinity) : 0.0;

    // Pre-fill amount field if still empty
    if (_amountCtrl.text.isEmpty && po != null) {
      _amountCtrl.text = effectiveBalance.toStringAsFixed(2);
    }

    final availableMethods = paymentMethodsAsync.valueOrNull?.isNotEmpty == true
        ? paymentMethodsAsync.valueOrNull!
        : _fallbackMethods;
    final effectiveSelectedMethodId = (_selectedMethodId != null && availableMethods.any((m) => m.id == _selectedMethodId))
        ? _selectedMethodId!
        : availableMethods.first.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Vendor Payment'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
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
                        if (po == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Purchase order not loaded'),
                              backgroundColor: SemanticColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        final vendorDisplay = (po.supplierName != null && !po.supplierName!.startsWith('Supplier #'))
                            ? po.supplierName!
                            : (suppliers?.where((s) => s.id == po.supplierId).firstOrNull?.supplierName ?? 'Supplier #${po.supplierId}');

                        final payment = VendorPaymentDto(
                          id: 0,
                          paymentNumber: 'VP/${DateTime.now().millisecondsSinceEpoch % 10000}',
                          supplierId: po.supplierId,
                          supplierName: vendorDisplay,
                          purchaseId: po.id,
                          purchaseNumber: po.purchaseNumber,
                          paymentDate: _paymentDate,
                          amount: double.tryParse(_amountCtrl.text) ?? 0.0,
                          paymentMethodId: _selectedMethodId ?? effectiveSelectedMethodId,
                          referenceNo: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
                          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                        );

                        final ok = await ref.read(vendorPaymentControllerProvider.notifier).submitPayment(payment);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment recorded successfully!'),
                              backgroundColor: BrandColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          context.pop();
                        } else if (!ok && context.mounted) {
                          final errMsg = paymentState.error?.toString() ?? 'Failed to record payment. Please try again.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errMsg),
                              backgroundColor: SemanticColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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
                  final vendorDisplay = (po.supplierName != null && !po.supplierName!.startsWith('Supplier #'))
                      ? po.supplierName!
                      : (suppliers?.where((s) => s.id == po.supplierId).firstOrNull?.supplierName ?? 'Supplier #${po.supplierId}');
                  return Container(
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
                        Text('PO Number: ${po.purchaseNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text('Vendor: $vendorDisplay', style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                          ],
                        ),
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
                            const Text('Paid Till Date:', style: TextStyle(color: Color(0xFF64748B))),
                            Text('₹${effectivePaidAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Outstanding Balance:', style: TextStyle(color: Color(0xFF64748B))),
                            Text(
                              '₹${effectiveBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: effectiveBalance > 0 ? Colors.red : BrandColors.primary,
                              ),
                            ),
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
                  if (effectiveBalance > 0 && amt > effectiveBalance + 0.01) {
                    return 'Cannot exceed balance ₹${effectiveBalance.toStringAsFixed(2)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),

              // Payment Date Selector
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _paymentDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(Radii.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Date *',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 20, color: Color(0xFF64748B)),
                  ),
                  child: Text(
                    '${_paymentDate.day.toString().padLeft(2, '0')}/${_paymentDate.month.toString().padLeft(2, '0')}/${_paymentDate.year}',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Payment Mode Dropdown with Fallback
              paymentMethodsAsync.when(
                data: (methods) {
                  final availableMethods = methods.isNotEmpty ? methods : _fallbackMethods;
                  final effectiveSelected = (_selectedMethodId != null && availableMethods.any((m) => m.id == _selectedMethodId))
                      ? _selectedMethodId
                      : availableMethods.first.id;

                  return DropdownButtonFormField<int>(
                    key: ValueKey('pay_method_$effectiveSelected'),
                    isExpanded: true,
                    initialValue: effectiveSelected,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode *',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    items: availableMethods
                        .map((m) => DropdownMenuItem(value: m.id, child: Text(m.methodName, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    validator: (v) => (v == null || v <= 0) ? 'Payment mode is required' : null,
                    onChanged: (val) => setState(() => _selectedMethodId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) {
                  return DropdownButtonFormField<int>(
                    key: const ValueKey('pay_method_fallback'),
                    isExpanded: true,
                    initialValue: _selectedMethodId ?? _fallbackMethods.first.id,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode *',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    items: _fallbackMethods
                        .map((m) => DropdownMenuItem(value: m.id, child: Text(m.methodName, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedMethodId = val),
                  );
                },
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
