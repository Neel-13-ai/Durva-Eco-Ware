import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/features/waste/data/models/waste_entry_dto.dart';
import 'package:durvaeco/features/waste/application/providers/waste_providers.dart';
import 'package:durvaeco/features/waste/application/controllers/waste_entry_form_controller.dart';

class WasteEntryFormScreen extends ConsumerStatefulWidget {
  const WasteEntryFormScreen({super.key});

  @override
  ConsumerState<WasteEntryFormScreen> createState() => _WasteEntryFormScreenState();
}

class _WasteEntryFormScreenState extends ConsumerState<WasteEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _qtyCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _batchCtrl;
  late TextEditingController _notesCtrl;
  DisposalMethod _selectedDisposal = DisposalMethod.recycled;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '10');
    _costCtrl = TextEditingController(text: '0.0');
    _batchCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    Future.microtask(() {
      ref.read(wasteEntryFormControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _batchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(wasteEntryFormControllerProvider);
    final formNotifier = ref.read(wasteEntryFormControllerProvider.notifier);
    final productsAsync = ref.watch(productsListProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final reasonsAsync = ref.watch(activeWasteReasonsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Scrap / Waste Incident'),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Scrap Loss', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    '₹${formState.totalLossAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: formState.formStatus == WasteFormStatus.submitting
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        formNotifier.setDisposalMethod(_selectedDisposal);
                        formNotifier.setBatchNo(_batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim());
                        formNotifier.setNotes(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim());

                        final ok = await formNotifier.submit();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Waste incident logged & inventory updated!'),
                              backgroundColor: BrandColors.primary,
                            ),
                          );
                          context.pop();
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
              ),
              child: formState.formStatus == WasteFormStatus.submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('CONFIRM SCRAP LOG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Product
                    productsAsync.when(
                      data: (products) => DropdownButtonFormField<ProductDto>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Select Product / Material *', border: OutlineInputBorder()),
                        items: products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.code})', overflow: TextOverflow.ellipsis))).toList(),
                        validator: (v) => v == null ? 'Product is required' : null,
                        onChanged: (val) {
                          if (val != null) {
                            _costCtrl.text = val.purchasePrice.toString();
                            formNotifier.setProduct(val.id, val.name, val.purchasePrice);
                          }
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading products'),
                    ),
                    const SizedBox(height: Spacing.md),

                    // Warehouse
                    warehousesAsync.when(
                      data: (warehouses) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Origin Warehouse *', border: OutlineInputBorder()),
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

                    // Waste Reason
                    reasonsAsync.when(
                      data: (reasons) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Defect / Waste Reason *', border: OutlineInputBorder()),
                        items: reasons.map((r) => DropdownMenuItem(value: r.id, child: Text(r.reasonName, overflow: TextOverflow.ellipsis))).toList(),
                        validator: (v) => (v == null || v <= 0) ? 'Reason is required' : null,
                        onChanged: (val) {
                          if (val != null) formNotifier.setWasteReasonId(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading reasons'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Disposal Method Segment
              const Text('Disposal / Recovery Method *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<DisposalMethod>(
                  segments: const [
                    ButtonSegment(value: DisposalMethod.recycled, label: Text('Recycled')),
                    ButtonSegment(value: DisposalMethod.repulped, label: Text('Repulped')),
                    ButtonSegment(value: DisposalMethod.soldAsScrap, label: Text('Scrap Sale')),
                    ButtonSegment(value: DisposalMethod.discarded, label: Text('Discarded')),
                  ],
                  selected: {_selectedDisposal},
                  onSelectionChanged: (set) => setState(() => _selectedDisposal = set.first),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Quantity and Cost Row
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Scrap Quantity *', border: OutlineInputBorder()),
                            validator: (v) {
                              final qty = double.tryParse(v ?? '');
                              if (qty == null || qty <= 0) return 'Quantity must be > 0';
                              return null;
                            },
                            onChanged: (v) {
                              final qty = double.tryParse(v) ?? 0.0;
                              formNotifier.setQuantity(qty);
                            },
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Unit Cost (₹) *', prefixText: '₹ ', border: OutlineInputBorder()),
                            validator: (v) {
                              final cost = double.tryParse(v ?? '');
                              if (cost == null || cost < 0) return 'Valid cost required';
                              return null;
                            },
                            onChanged: (v) {
                              final cost = double.tryParse(v) ?? 0.0;
                              formNotifier.setUnitCost(cost);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _batchCtrl,
                      decoration: const InputDecoration(labelText: 'Batch No. / Lot ID', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Incident Notes & Observations', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
