import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/expenses/application/expense_form_controller.dart';
import 'package:durvaeco/features/expenses/application/expense_providers.dart';
import 'package:durvaeco/features/expenses/data/models/expense_category_dto.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/payment_method_dto.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final ExpenseDto? existingExpense;

  const ExpenseFormScreen({super.key, this.existingExpense});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _expenseNoCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(expenseFormControllerProvider.notifier);
      if (widget.existingExpense != null) {
        controller.initForEdit(widget.existingExpense!);
        _expenseNoCtrl.text = widget.existingExpense!.expenseNumber;
        _amountCtrl.text = widget.existingExpense!.amount.toString();
        _vendorCtrl.text = widget.existingExpense!.vendorName ?? '';
        _refCtrl.text = widget.existingExpense!.referenceNo ?? '';
        _descCtrl.text = widget.existingExpense!.description ?? '';
      } else {
        controller.initForCreate();
        _expenseNoCtrl.text = 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        controller.updateExpenseNumber(_expenseNoCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _expenseNoCtrl.dispose();
    _amountCtrl.dispose();
    _vendorCtrl.dispose();
    _refCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(expenseFormControllerProvider);
    final formNotifier = ref.read(expenseFormControllerProvider.notifier);

    final categoriesAsync = ref.watch(activeExpenseCategoriesProvider);
    final warehousesAsync = ref.watch(warehousesListProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingExpense != null ? 'Edit Expense Voucher' : 'New Expense Voucher'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
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
                    const Text('Voucher Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _expenseNoCtrl,
                      decoration: const InputDecoration(labelText: 'Voucher Number *', border: OutlineInputBorder()),
                      onChanged: formNotifier.updateExpenseNumber,
                    ),
                    const SizedBox(height: Spacing.md),
                    categoriesAsync.when(
                      data: (List<ExpenseCategoryDto> categories) => DropdownButtonFormField<int>(
                        initialValue: formState.expenseCategoryId > 0 ? formState.expenseCategoryId : null,
                        decoration: const InputDecoration(labelText: 'Expense Head / Category *', border: OutlineInputBorder()),
                        items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName))).toList(),
                        onChanged: (val) {
                          if (val != null) formNotifier.updateCategory(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading categories: $err'),
                    ),
                    const SizedBox(height: Spacing.md),
                    warehousesAsync.when(
                      data: (List<WarehouseDto> warehouses) => DropdownButtonFormField<int>(
                        initialValue: formState.warehouseId,
                        decoration: const InputDecoration(labelText: 'Warehouse / Location (Optional)', border: OutlineInputBorder()),
                        items: warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                        onChanged: (val) => formNotifier.updateWarehouse(val),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading warehouses: $err'),
                    ),
                    const SizedBox(height: Spacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Expense Date'),
                      subtitle: Text('${formState.expenseDate?.day ?? 1}/${formState.expenseDate?.month ?? 1}/${formState.expenseDate?.year ?? 2026}'),
                      leading: const Icon(Icons.calendar_today, color: BrandColors.primary),
                      trailing: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: formState.expenseDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) formNotifier.updateDate(picked);
                        },
                        child: const Text('Change Date'),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Expense Amount (₹) *',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => formNotifier.updateAmount(double.tryParse(v) ?? 0.0),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Wrap(
                      spacing: 6,
                      children: [500.0, 1000.0, 2500.0, 5000.0, 10000.0].map((amt) {
                        return ActionChip(
                          label: Text('₹${amt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            _amountCtrl.text = amt.toStringAsFixed(0);
                            formNotifier.updateAmount(amt);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: Spacing.md),
                    paymentMethodsAsync.when(
                      data: (List<PaymentMethodDto> methods) => DropdownButtonFormField<int>(
                        initialValue: formState.paymentMethodId > 0 ? formState.paymentMethodId : null,
                        decoration: const InputDecoration(labelText: 'Paid Via / Payment Method *', border: OutlineInputBorder()),
                        items: methods.map((m) => DropdownMenuItem(value: m.id, child: Text(m.methodName))).toList(),
                        onChanged: (val) {
                          if (val != null) formNotifier.updatePaymentMethod(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading payment methods: $err'),
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _vendorCtrl,
                      decoration: const InputDecoration(labelText: 'Vendor / Payee Name', border: OutlineInputBorder()),
                      onChanged: formNotifier.updateVendorName,
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _refCtrl,
                      decoration: const InputDecoration(labelText: 'Bill / Receipt / Ref No', border: OutlineInputBorder()),
                      onChanged: formNotifier.updateReferenceNo,
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description / Purpose', border: OutlineInputBorder()),
                      onChanged: formNotifier.updateDescription,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            ElevatedButton(
              onPressed: formState.formStatus == ExpenseFormStatus.submitting
                  ? null
                  : () async {
                      final success = await formNotifier.submit();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.existingExpense != null ? 'Expense updated!' : 'Expense voucher logged!'),
                            backgroundColor: BrandColors.primary,
                          ),
                        );
                        Navigator.of(context).pop();
                      } else if (formState.failure != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${formState.failure!.message}'), backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
              ),
              child: formState.formStatus == ExpenseFormStatus.submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Expense Voucher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
