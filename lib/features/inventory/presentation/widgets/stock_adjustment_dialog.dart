import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/inventory/data/models/stock_adjustment_request.dart';
import 'package:durvaeco/features/inventory/application/controllers/stock_adjustment_controller.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  const StockAdjustmentDialog({
    super.key,
    this.initialProductId,
    this.initialWarehouseId,
  });

  final int? initialProductId;
  final int? initialWarehouseId;

  static Future<void> show(
    BuildContext context, {
    int? initialProductId,
    int? initialWarehouseId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => StockAdjustmentDialog(
        initialProductId: initialProductId,
        initialWarehouseId: initialWarehouseId,
      ),
    );
  }

  @override
  ConsumerState<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedProductId;
  int? _selectedWarehouseId;
  AdjustmentMode _selectedMode = AdjustmentMode.increase;
  late TextEditingController _qtyCtrl;
  late TextEditingController _reasonCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _costCtrl;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
    _selectedWarehouseId = widget.initialWarehouseId;
    _qtyCtrl = TextEditingController(text: '1');
    _reasonCtrl = TextEditingController(text: 'Physical Inventory Audit');
    _notesCtrl = TextEditingController();
    _costCtrl = TextEditingController(text: '0.0');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final adjustmentState = ref.watch(stockAdjustmentControllerProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune, color: BrandColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Stock Adjustment / Audit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Dropdown
                productsAsync.when(
                  data: (products) => DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedProductId,
                    decoration: const InputDecoration(labelText: 'Select Product / Material *', border: OutlineInputBorder()),
                    items: products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.code})', overflow: TextOverflow.ellipsis))).toList(),
                    validator: (v) => (v == null || v <= 0) ? 'Product is required' : null,
                    onChanged: (val) {
                      setState(() {
                        _selectedProductId = val;
                        final prod = products.where((p) => p.id == val).firstOrNull;
                        if (prod != null) {
                          _costCtrl.text = prod.purchasePrice.toString();
                        }
                      });
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading products'),
                ),
                const SizedBox(height: Spacing.md),

                // Warehouse Dropdown
                warehousesAsync.when(
                  data: (warehouses) => DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedWarehouseId,
                    decoration: const InputDecoration(labelText: 'Select Warehouse *', border: OutlineInputBorder()),
                    items: warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                    validator: (v) => (v == null || v <= 0) ? 'Warehouse is required' : null,
                    onChanged: (val) => setState(() => _selectedWarehouseId = val),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading warehouses'),
                ),
                const SizedBox(height: Spacing.md),

                // Adjustment Mode Segmented Buttons
                const Text('Adjustment Mode *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                SegmentedButton<AdjustmentMode>(
                  segments: const [
                    ButtonSegment(value: AdjustmentMode.increase, label: Text('+ Add', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: AdjustmentMode.decrease, label: Text('- Reduce', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: AdjustmentMode.recount, label: Text('Recount', style: TextStyle(fontSize: 12))),
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (set) => setState(() => _selectedMode = set.first),
                ),
                const SizedBox(height: Spacing.md),

                // Quantity & Unit Cost
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Quantity *', border: OutlineInputBorder()),
                        validator: (v) {
                          final qty = double.tryParse(v ?? '');
                          if (qty == null || qty <= 0) return 'Quantity must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Avg Unit Cost (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // Reason Field
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Adjustment *',
                    hintText: 'e.g. Physical inventory audit recount, scrap write-off',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
                ),
                const SizedBox(height: Spacing.sm),

                // Notes Field
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes / Batch Info',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: adjustmentState.isLoading
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final req = StockAdjustmentRequest(
                      productId: _selectedProductId!,
                      warehouseId: _selectedWarehouseId!,
                      mode: _selectedMode,
                      quantity: double.tryParse(_qtyCtrl.text) ?? 0.0,
                      reason: _reasonCtrl.text.trim(),
                      unitCost: double.tryParse(_costCtrl.text) ?? 0.0,
                      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                    );

                    final ok = await ref.read(stockAdjustmentControllerProvider.notifier).submitAdjustment(req);
                    if (ok && context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stock adjusted & logged to audit ledger successfully!'),
                          backgroundColor: BrandColors.primary,
                        ),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
          child: adjustmentState.isLoading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Adjustment', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
