import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/purchasing/application/controllers/purchase_form_controller.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/purchasing/data/models/purchase_detail_dto.dart';

class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  const PurchaseOrderFormScreen({super.key, this.purchaseId});

  final int? purchaseId;

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends ConsumerState<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _poNumberCtrl;
  late TextEditingController _refCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _poNumberCtrl = TextEditingController(text: 'PO/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch % 10000}');
    _refCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    Future.microtask(() async {
      if (widget.purchaseId != null && widget.purchaseId! > 0) {
        final po = await ref.read(purchaseDetailProvider(widget.purchaseId!).future);
        if (mounted) {
          _poNumberCtrl.text = po.purchaseNumber;
          _refCtrl.text = po.referenceNo ?? '';
          _notesCtrl.text = po.notes ?? '';
          ref.read(purchaseFormControllerProvider.notifier).initialize(po);
        }
      } else {
        ref.read(purchaseFormControllerProvider.notifier).initialize(null);
      }
    });
  }

  @override
  void dispose() {
    _poNumberCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showAddItemDialog(BuildContext context) {
    int? selectedProductId;
    ProductDto? selectedProduct;
    final qtyCtrl = TextEditingController(text: '100');
    final rateCtrl = TextEditingController(text: '0.0');
    String? itemError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Consumer(
            builder: (consumerCtx, ref, _) {
              final productsAsync = ref.watch(productsListProvider);

              return AlertDialog(
                title: const Text('Add Raw Material Item'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      productsAsync.when(
                        data: (products) => DropdownButtonFormField<int>(
                          key: ValueKey('dialog_prod_$selectedProductId'),
                          isExpanded: true,
                          initialValue: selectedProductId,
                          decoration: InputDecoration(
                            labelText: 'Select Material / Product *',
                            border: const OutlineInputBorder(),
                            errorText: itemError,
                          ),
                          items: products
                              .map((p) => DropdownMenuItem<int>(
                                    value: p.id,
                                    child: Text('${p.name} (${p.code})', overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (id) {
                            if (id != null) {
                              final p = products.firstWhere((prod) => prod.id == id);
                              setDialogState(() {
                                selectedProductId = id;
                                selectedProduct = p;
                                rateCtrl.text = p.purchasePrice.toString();
                                itemError = null;
                              });
                            }
                          },
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: Spacing.md),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Text('Error loading products: $err', style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: Spacing.md),
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Quantity *', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: Spacing.md),
                      TextField(
                        controller: rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Unit Rate (₹) *', prefixText: '₹ ', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedProduct == null) {
                        setDialogState(() {
                          itemError = 'Please select a material / product';
                        });
                        return;
                      }
                      final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                      final rate = double.tryParse(rateCtrl.text) ?? 0.0;
                      if (qty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quantity must be greater than 0'),
                            backgroundColor: SemanticColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final item = PurchaseDetailDto(
                        id: 0,
                        purchaseId: 0,
                        productId: selectedProduct!.id,
                        productName: selectedProduct!.name,
                        productCode: selectedProduct!.code,
                        unitName: selectedProduct!.unitName,
                        quantity: qty,
                        unitCost: rate,
                      );

                      ref.read(purchaseFormControllerProvider.notifier).addItem(item);
                      Navigator.of(dialogCtx).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
                    child: const Text('Add to PO', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(purchaseFormControllerProvider);
    final formNotifier = ref.read(purchaseFormControllerProvider.notifier);
    final suppliersAsync = ref.watch(activeSuppliersProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final products = ref.watch(productsListProvider).valueOrNull;

    final isEdit = widget.purchaseId != null && widget.purchaseId! > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Purchase Order' : 'Create Purchase Order'),
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
          child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grand Total', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text(
                  '₹${formState.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BrandColors.primary),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: formState.formStatus == PurchaseFormStatus.submitting
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      if (formState.items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please add at least one raw material item'),
                            backgroundColor: SemanticColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final ok = await formNotifier.submit();
                      if (ok && context.mounted) {
                        if (isEdit && widget.purchaseId != null) {
                          ref.invalidate(purchaseDetailProvider(widget.purchaseId!));
                        }
                        ref.invalidate(purchasesListProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? 'Purchase Order updated successfully' : 'Purchase Order created successfully'),
                            backgroundColor: BrandColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        context.pop();
                      } else if (!ok && context.mounted) {
                        final errMsg = ref.read(purchaseFormControllerProvider).failure?.message ?? (isEdit ? 'Failed to update purchase order' : 'Failed to create purchase order');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errMsg),
                            backgroundColor: SemanticColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
              ),
              child: formState.formStatus == PurchaseFormStatus.submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'UPDATE PO' : 'CONFIRM PO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
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
              // Header Card
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    suppliersAsync.when(
                      data: (suppliers) => DropdownButtonFormField<int>(
                        key: ValueKey('supplier_${formState.supplierId}'),
                        isExpanded: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        initialValue: (formState.supplierId > 0 && suppliers.any((s) => s.id == formState.supplierId))
                            ? formState.supplierId
                            : null,
                        decoration: const InputDecoration(labelText: 'Supplier *', border: OutlineInputBorder()),
                        items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.supplierName, overflow: TextOverflow.ellipsis))).toList(),
                        validator: (v) => (v == null || v <= 0) ? 'Supplier is required' : null,
                        onChanged: (val) {
                          if (val != null) formNotifier.setSupplierId(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading suppliers'),
                    ),
                    const SizedBox(height: Spacing.md),
                    warehousesAsync.when(
                      data: (warehouses) => DropdownButtonFormField<int>(
                        key: ValueKey('warehouse_${formState.warehouseId}'),
                        isExpanded: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        initialValue: (formState.warehouseId > 0 && warehouses.any((w) => w.id == formState.warehouseId))
                            ? formState.warehouseId
                            : null,
                        decoration: const InputDecoration(labelText: 'Receiving Warehouse *', border: OutlineInputBorder()),
                        items: warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                        validator: (v) => (v == null || v <= 0) ? 'Warehouse is required' : null,
                        onChanged: (val) {
                          if (val != null) formNotifier.setWarehouseId(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading warehouses'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Items Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Items (${formState.items.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showAddItemDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    style: OutlinedButton.styleFrom(foregroundColor: BrandColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // Items List
              if (formState.items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text('No items added yet. Tap "+ Add Item" above.', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              else
                ...formState.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      title: Text(
                        (item.productName != null && !item.productName!.startsWith('Item #') && !item.productName!.startsWith('Product #'))
                            ? item.productName!
                            : (products?.where((p) => p.id == item.productId).firstOrNull?.name ?? 'Item #${item.productId}'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${item.quantity} ${(item.unitName != null && item.unitName!.isNotEmpty) ? item.unitName! : "Units"} × ₹${item.unitCost.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${item.lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => formNotifier.removeItem(idx),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: Spacing.md),

              // Optional Details Card (Reference & Remarks)
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Additional Details (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: Spacing.sm),
                    TextFormField(
                      controller: _refCtrl,
                      decoration: const InputDecoration(labelText: 'Reference / Quotation No.', border: OutlineInputBorder()),
                      onChanged: formNotifier.setReferenceNo,
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes / Special Instructions', border: OutlineInputBorder()),
                      onChanged: formNotifier.setNotes,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
