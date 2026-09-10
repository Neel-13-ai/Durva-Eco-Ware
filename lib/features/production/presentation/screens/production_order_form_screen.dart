import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/production/application/controllers/production_order_form_controller.dart';

class ProductionOrderFormScreen extends ConsumerStatefulWidget {
  const ProductionOrderFormScreen({super.key});

  @override
  ConsumerState<ProductionOrderFormScreen> createState() => _ProductionOrderFormScreenState();
}

class _ProductionOrderFormScreenState extends ConsumerState<ProductionOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _orderNumCtrl;
  late TextEditingController _plannedQtyCtrl;
  late TextEditingController _notesCtrl;
  String _selectedShift = 'General Shift (08:00 - 16:00)';

  @override
  void initState() {
    super.initState();
    _orderNumCtrl = TextEditingController(
      text: 'PRD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    _plannedQtyCtrl = TextEditingController(text: '1000');
    _notesCtrl = TextEditingController();

    Future.microtask(() {
      ref.read(productionOrderFormControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _orderNumCtrl.dispose();
    _plannedQtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productionOrderFormControllerProvider);
    final formNotifier = ref.read(productionOrderFormControllerProvider.notifier);
    final productsAsync = ref.watch(productsListProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan New Production Run'),
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
            onPressed: formState.formStatus == ProductionFormStatus.submitting
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      formNotifier.setShiftName(_selectedShift);
                      formNotifier.setNotes(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim());

                      final ok = await formNotifier.submit();
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Production order created & scheduled!'),
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
            child: formState.formStatus == ProductionFormStatus.submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('CREATE & SCHEDULE RUN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              // Config Card
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Output Finished Good
                    productsAsync.when(
                      data: (products) {
                        final fgProducts = products.where((p) => p.isFinishedGood).toList();
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Output Finished Product *', border: OutlineInputBorder()),
                          items: (fgProducts.isNotEmpty ? fgProducts : products)
                              .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.code})', overflow: TextOverflow.ellipsis)))
                              .toList(),
                          validator: (v) => (v == null || v <= 0) ? 'Finished product is required' : null,
                          onChanged: (val) {
                            if (val != null) {
                              final p = products.where((item) => item.id == val).firstOrNull;
                              formNotifier.setFinishedProduct(val, p?.name ?? '', p?.unitName);
                            }
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading products'),
                    ),
                    const SizedBox(height: Spacing.md),

                    // Warehouse
                    warehousesAsync.when(
                      data: (warehouses) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Production Plant / Warehouse *', border: OutlineInputBorder()),
                        items: warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                        validator: (v) => (v == null || v <= 0) ? 'Warehouse is required' : null,
                        onChanged: (val) {
                          if (val != null) formNotifier.setWarehouseId(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading warehouses'),
                    ),
                    const SizedBox(height: Spacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _plannedQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Planned Target Qty *', border: OutlineInputBorder()),
                            validator: (v) {
                              final qty = double.tryParse(v ?? '');
                              if (qty == null || qty <= 0) return 'Quantity must be > 0';
                              return null;
                            },
                            onChanged: (v) {
                              final qty = double.tryParse(v) ?? 0.0;
                              formNotifier.setPlannedQty(qty);
                            },
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedShift,
                            decoration: const InputDecoration(labelText: 'Shift *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'General Shift (08:00 - 16:00)', child: Text('General Shift', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'Morning Shift (06:00 - 14:00)', child: Text('Morning Shift', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'Evening Shift (14:00 - 22:00)', child: Text('Evening Shift', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'Night Shift (22:00 - 06:00)', child: Text('Night Shift', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedShift = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Materials Requisition Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Required Raw Materials (${formState.materials.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  if (formState.bomCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: BrandColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(
                        'BOM: ${formState.bomCode}',
                        style: const TextStyle(color: BrandColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              if (formState.materials.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'Select an output product with an active BOM to auto-calculate raw materials.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                )
              else
                ...formState.materials.map((m) => Card(
                      margin: const EdgeInsets.only(bottom: Spacing.sm),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        title: Text(m.productName ?? 'Material #${m.productId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Required: ${m.requiredQty.toStringAsFixed(2)} ${m.unitName ?? "Units"}'),
                        trailing: Text(
                          '₹${(m.requiredQty * m.unitCost).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
