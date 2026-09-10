import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/customer_dto.dart';
import 'package:durvaeco/features/sales/application/sales_form_controller.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';

class SalesFormScreen extends ConsumerStatefulWidget {
  final SaleDto? existingSale;

  const SalesFormScreen({super.key, this.existingSale});

  @override
  ConsumerState<SalesFormScreen> createState() => _SalesFormScreenState();
}

class _SalesFormScreenState extends ConsumerState<SalesFormScreen> {
  final _invoiceCtrl = TextEditingController();
  final _transportCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(salesFormControllerProvider.notifier);
      if (widget.existingSale != null) {
        controller.initForEdit(widget.existingSale!);
        _invoiceCtrl.text = widget.existingSale!.invoiceNumber;
        _transportCtrl.text = widget.existingSale!.transportCharge.toString();
        _notesCtrl.text = widget.existingSale!.notes ?? '';
      } else {
        controller.initForCreate();
        _invoiceCtrl.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        controller.updateInvoiceNumber(_invoiceCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _transportCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showAddItemDialog(List<ProductDto> products) {
    int? selectedProductId;
    final qtyCtrl = TextEditingController(text: '100');
    final priceCtrl = TextEditingController(text: '10.0');
    final discountCtrl = TextEditingController(text: '0.0');
    final taxCtrl = TextEditingController(text: '0.0');

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final chosenProduct = products.where((p) => p.id == selectedProductId).firstOrNull;

          return AlertDialog(
            title: const Text('Add Sales Line Item', style: TextStyle(color: BrandColors.primary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedProductId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Finished Good / Product *', border: OutlineInputBorder()),
                    items: products
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (${p.code})'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedProductId = val;
                        final prod = products.where((p) => p.id == val).firstOrNull;
                        if (prod != null) {
                          priceCtrl.text = prod.sellingPrice.toString();
                          taxCtrl.text = (prod.sellingPrice * (prod.taxRate / 100)).toStringAsFixed(2);
                        }
                      });
                    },
                  ),
                  if (chosenProduct != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Category: ${chosenProduct.categoryName ?? "General"} | Price: ₹${chosenProduct.sellingPrice}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.sm),
                  TextFormField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit Price (₹) *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: discountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Discount (₹)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: taxCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Tax (₹)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (selectedProductId == null) return;
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                  final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                  final discount = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
                  final tax = double.tryParse(taxCtrl.text.trim()) ?? 0.0;
                  if (qty <= 0 || price <= 0) return;

                  final item = SaleDetailDto(
                    id: 0,
                    saleId: widget.existingSale?.id ?? 0,
                    productId: selectedProductId!,
                    productName: chosenProduct?.name,
                    quantity: qty,
                    unitPrice: price,
                    discount: discount,
                    tax: tax,
                  );

                  ref.read(salesFormControllerProvider.notifier).addItem(item);
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
                child: const Text('Add Item'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(salesFormControllerProvider);
    final formNotifier = ref.read(salesFormControllerProvider.notifier);

    final customersAsync = ref.watch(customersListProvider);
    final warehousesAsync = ref.watch(warehousesListProvider);
    final productsAsync = ref.watch(productsListProvider);

    final customers = customersAsync.value ?? <CustomerDto>[];
    final selectedCustomer = customers.where((c) => c.id == formState.customerId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSale != null ? 'Edit Sales Invoice' : 'New Sales Invoice'),
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
            // Header Info Card
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
                    const Text('Invoice Header', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _invoiceCtrl,
                      decoration: const InputDecoration(labelText: 'Invoice Number *', border: OutlineInputBorder()),
                      onChanged: formNotifier.updateInvoiceNumber,
                    ),
                    const SizedBox(height: Spacing.md),
                    customersAsync.when(
                      data: (List<CustomerDto> custList) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: formState.customerId > 0 ? formState.customerId : null,
                        decoration: const InputDecoration(labelText: 'Customer *', border: OutlineInputBorder()),
                        items: custList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.customerName, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) formNotifier.updateCustomer(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),
                    if (selectedCustomer != null) ...[
                      const SizedBox(height: Spacing.xs),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.credit_card, size: 16, color: Color(0xFF1976D2)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Credit: ₹${selectedCustomer.creditLimit.toStringAsFixed(0)} | Op. Bal: ₹${selectedCustomer.openingBalance.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.md),
                    warehousesAsync.when(
                      data: (List<WarehouseDto> whList) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: formState.warehouseId > 0 ? formState.warehouseId : null,
                        decoration: const InputDecoration(labelText: 'Dispatch Warehouse *', border: OutlineInputBorder()),
                        items: whList.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) formNotifier.updateWarehouse(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: formState.saleDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) formNotifier.updateSaleDate(picked);
                            },
                            borderRadius: BorderRadius.circular(Radii.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(Radii.sm),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sale Date', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: BrandColors.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${formState.saleDate?.day ?? 1}/${formState.saleDate?.month ?? 1}/${formState.saleDate?.year ?? 2026}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: formState.dueDate ?? DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) formNotifier.updateDueDate(picked);
                            },
                            borderRadius: BorderRadius.circular(Radii.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(Radii.sm),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Due Date', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.event, size: 14, color: BrandColors.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          formState.dueDate != null ? '${formState.dueDate!.day}/${formState.dueDate!.month}/${formState.dueDate!.year}' : 'Not set',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Line Items Card
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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ordered Products',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddItemDialog(productsAsync.value ?? <ProductDto>[]),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Product', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    if (formState.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: Text('No products added yet. Click "+ Add Product".', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: formState.items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, index) {
                          final item = formState.items[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.productName ?? 'Product #${item.productId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Qty: ${item.quantity} | Rate: ₹${item.unitPrice} | Tax: ₹${item.tax} | Disc: ₹${item.discount}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('₹${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => formNotifier.removeItem(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Pricing Summary Card
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
                    const Text('Summary & Charges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _transportCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Transport Charge (₹)', border: OutlineInputBorder()),
                      onChanged: (val) => formNotifier.updateTransportCharge(double.tryParse(val) ?? 0.0),
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Order Notes & Terms', border: OutlineInputBorder()),
                      onChanged: formNotifier.updateNotes,
                    ),
                    const SizedBox(height: Spacing.md),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items Subtotal:', style: TextStyle(color: Colors.grey)),
                        Text('₹${formState.itemsSubtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Tax:', style: TextStyle(color: Colors.grey)),
                        Text('+ ₹${formState.itemsTax.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transport:', style: TextStyle(color: Colors.grey)),
                        Text('+ ₹${formState.transportCharge.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(
                          '₹${formState.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: BrandColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            ElevatedButton(
              onPressed: formState.formStatus == SalesFormStatus.submitting
                  ? null
                  : () async {
                      final success = await formNotifier.submit();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.existingSale != null ? 'Invoice updated!' : 'Invoice created successfully!'),
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
              child: formState.formStatus == SalesFormStatus.submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.existingSale != null ? 'Save Changes' : 'Confirm Sales Order / Invoice',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
