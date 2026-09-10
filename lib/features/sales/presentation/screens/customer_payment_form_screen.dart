import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/customer_dto.dart';
import 'package:durvaeco/features/partners/data/models/payment_method_dto.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';

class CustomerPaymentFormScreen extends ConsumerStatefulWidget {
  final SaleDto? prefilledSale;
  final int? prefilledCustomerId;

  const CustomerPaymentFormScreen({
    super.key,
    this.prefilledSale,
    this.prefilledCustomerId,
  });

  @override
  ConsumerState<CustomerPaymentFormScreen> createState() => _CustomerPaymentFormScreenState();
}

class _CustomerPaymentFormScreenState extends ConsumerState<CustomerPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiptCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int? _selectedCustomerId;
  int? _selectedSaleId;
  int? _selectedPaymentMethodId;
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledSale != null) {
      _selectedSaleId = widget.prefilledSale!.id;
      _selectedCustomerId = widget.prefilledSale!.customerId;
      _amountCtrl.text = widget.prefilledSale!.outstandingBalance.toStringAsFixed(2);
    } else if (widget.prefilledCustomerId != null) {
      _selectedCustomerId = widget.prefilledCustomerId;
    }
    _receiptCtrl.text = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _receiptCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null || _selectedSaleId == null || _selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Customer, Invoice, and Payment Method')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final payment = CustomerPaymentDto(
      id: 0,
      receiptNumber: _receiptCtrl.text.trim(),
      customerId: _selectedCustomerId!,
      saleId: _selectedSaleId!,
      paymentDate: _paymentDate,
      amount: amount,
      paymentMethodId: _selectedPaymentMethodId!,
      referenceNo: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    final repo = ref.read(customerPaymentRepositoryProvider);
    final result = await repo.createPayment(payment);

    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ref.invalidate(salesListProvider);
        ref.invalidate(saleDetailProvider(_selectedSaleId!));
        ref.invalidate(salePaymentsProvider(_selectedSaleId!));
        ref.invalidate(customerPaymentsProvider(_selectedCustomerId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer payment recorded successfully!'),
              backgroundColor: BrandColors.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
      failure: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${err.message}'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersListProvider);
    final salesAsync = ref.watch(salesListProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Customer Payment'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      const Text(
                        'Payment Receipt Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary),
                      ),
                      const SizedBox(height: Spacing.md),
                      TextFormField(
                        controller: _receiptCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Number *',
                          prefixIcon: Icon(Icons.receipt_long),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'Receipt number is required' : null,
                      ),
                      const SizedBox(height: Spacing.md),
                      customersAsync.when(
                        data: (List<CustomerDto> customers) => DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _selectedCustomerId,
                          decoration: const InputDecoration(
                            labelText: 'Customer *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.customerName, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: widget.prefilledSale != null
                              ? null
                              : (val) => setState(() => _selectedCustomerId = val),
                          validator: (v) => v == null ? 'Please select a customer' : null,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('Error loading customers: $err'),
                      ),
                      const SizedBox(height: Spacing.md),
                      salesAsync.when(
                        data: (List<SaleDto> sales) {
                          final filteredSales = _selectedCustomerId != null
                              ? sales.where((s) => s.customerId == _selectedCustomerId).toList()
                              : sales;
                          return DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _selectedSaleId,
                            decoration: const InputDecoration(
                              labelText: 'Sales Invoice *',
                              prefixIcon: Icon(Icons.inventory_2),
                              border: OutlineInputBorder(),
                            ),
                            items: filteredSales
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text('${s.invoiceNumber} - ₹${s.totalAmount.toStringAsFixed(0)}', overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: widget.prefilledSale != null
                                ? null
                                : (val) => setState(() => _selectedSaleId = val),
                            validator: (v) => v == null ? 'Please select an invoice' : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('Error loading sales: $err'),
                      ),
                      const SizedBox(height: Spacing.md),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Payment Amount (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final num = double.tryParse(v ?? '');
                          if (num == null || num <= 0) return 'Enter valid amount > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: Spacing.md),
                      paymentMethodsAsync.when(
                        data: (List<PaymentMethodDto> methods) => DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _selectedPaymentMethodId,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method *',
                            prefixIcon: Icon(Icons.payment),
                            border: OutlineInputBorder(),
                          ),
                          items: methods.map((m) => DropdownMenuItem(value: m.id, child: Text(m.methodName, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _selectedPaymentMethodId = val),
                          validator: (v) => v == null ? 'Select payment method' : null,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('Error loading methods: $err'),
                      ),
                      const SizedBox(height: Spacing.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Payment Date'),
                        subtitle: Text('${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
                        leading: const Icon(Icons.calendar_today, color: BrandColors.primary),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _paymentDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _paymentDate = picked);
                          },
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      TextFormField(
                        controller: _refCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reference / Transaction No',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Record Payment Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
