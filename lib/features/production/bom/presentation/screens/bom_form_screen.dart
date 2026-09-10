import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/features/production/bom/data/models/bom_detail_dto.dart';
import 'package:durvaeco/features/production/bom/application/controllers/bom_form_controller.dart';
import 'package:durvaeco/features/production/bom/application/providers/bom_providers.dart';

class BomFormScreen extends ConsumerStatefulWidget {
  const BomFormScreen({super.key, this.bomId});

  final int? bomId;

  @override
  ConsumerState<BomFormScreen> createState() => _BomFormScreenState();
}

class _BomFormScreenState extends ConsumerState<BomFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _verCtrl;
  late TextEditingController _batchSizeCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController();
    _verCtrl = TextEditingController(text: '1.0');
    _batchSizeCtrl = TextEditingController(text: '1000');
    _notesCtrl = TextEditingController();

    Future.microtask(() async {
      if (widget.bomId != null && widget.bomId! > 0) {
        final existing = await ref.read(bomDetailProvider(widget.bomId!).future);
        if (existing != null) {
          _codeCtrl.text = existing.bomCode;
          _verCtrl.text = existing.versionNo;
          _batchSizeCtrl.text = existing.batchSize.toString();
          _notesCtrl.text = existing.notes ?? '';
          ref.read(bomFormControllerProvider.notifier).initialize(existing);
        }
      } else {
        _codeCtrl.text = 'BOM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}';
        ref.read(bomFormControllerProvider.notifier).initialize(null);
      }
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _verCtrl.dispose();
    _batchSizeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showAddComponentDialog(BuildContext context) {
    ProductDto? selectedMaterial;
    final qtyCtrl = TextEditingController(text: '10');
    final scrapCtrl = TextEditingController(text: '2.0');
    final costCtrl = TextEditingController(text: '0.0');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final productsAsync = ref.watch(productsListProvider);

          return AlertDialog(
            title: const Text('Add Raw Material Component'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  productsAsync.when(
                    data: (products) {
                      // Filter to Raw Materials
                      final materials = products.where((p) => p.isRawMaterial).toList();
                      return DropdownButtonFormField<ProductDto>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Select Raw Material *', border: OutlineInputBorder()),
                        items: (materials.isNotEmpty ? materials : products)
                            .map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.code})', overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedMaterial = val;
                              costCtrl.text = val.purchasePrice.toString();
                            });
                          }
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading materials'),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Base Qty *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: TextField(
                          controller: scrapCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Scrap %', suffixText: '%', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit Cost (₹) *', prefixText: '₹ ', border: OutlineInputBorder()),
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
                  if (selectedMaterial == null) return;
                  final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                  final scrap = double.tryParse(scrapCtrl.text) ?? 0.0;
                  final cost = double.tryParse(costCtrl.text) ?? 0.0;
                  if (qty <= 0) return;

                  final item = BomDetailDto(
                    id: 0,
                    bomId: widget.bomId ?? 0,
                    rawMaterialId: selectedMaterial!.id,
                    rawMaterialName: selectedMaterial!.name,
                    rawMaterialCode: selectedMaterial!.code,
                    unitName: selectedMaterial!.unitName,
                    quantityRequired: qty,
                    scrapPercent: scrap,
                    unitCost: cost,
                  );

                  ref.read(bomFormControllerProvider.notifier).addItem(item);
                  Navigator.of(dialogCtx).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
                child: const Text('Add Component', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(bomFormControllerProvider);
    final formNotifier = ref.read(bomFormControllerProvider.notifier);
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(formState.isEdit ? 'Edit BOM Recipe' : 'Create BOM Recipe'),
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
                  Text(
                    'Batch Cost: ₹${formState.totalBatchCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Unit Cost: ₹${formState.costPerUnit.toStringAsFixed(3)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BrandColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: formState.formStatus == BomFormStatus.submitting
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        formNotifier.setBomCode(_codeCtrl.text.trim());
                        formNotifier.setVersionNo(_verCtrl.text.trim());
                        formNotifier.setBatchSize(double.tryParse(_batchSizeCtrl.text) ?? 1000.0);
                        formNotifier.setNotes(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim());

                        final ok = await formNotifier.submit();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('BOM Recipe saved successfully!'),
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
              child: formState.formStatus == BomFormStatus.submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE RECIPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              // Header Config Card
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Finished Product Picker
                    productsAsync.when(
                      data: (products) {
                        final fgProducts = products.where((p) => p.isFinishedGood).toList();
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: formState.finishedProductId > 0 ? formState.finishedProductId : null,
                          decoration: const InputDecoration(labelText: 'Finished Product (Output) *', border: OutlineInputBorder()),
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
                      error: (_, __) => const Text('Error loading finished products'),
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeCtrl,
                            decoration: const InputDecoration(labelText: 'BOM Code *', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'BOM code is required' : null,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _verCtrl,
                            decoration: const InputDecoration(labelText: 'Version No.', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _batchSizeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Standard Batch Size (Units) *',
                        hintText: 'e.g. 1000',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final size = double.tryParse(v ?? '');
                        if (size == null || size <= 0) return 'Batch size must be > 0';
                        return null;
                      },
                      onChanged: (v) => formNotifier.setBatchSize(double.tryParse(v) ?? 1000.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Components Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Raw Material Components (${formState.items.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showAddComponentDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Material'),
                    style: OutlinedButton.styleFrom(foregroundColor: BrandColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // Component List
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
                    child: Text('No raw materials added yet. Tap "+ Add Material" above.', style: TextStyle(color: Color(0xFF94A3B8))),
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
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.rawMaterialName ?? 'Material #${item.rawMaterialId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  'Base: ${item.quantityRequired} ${item.unitName ?? "Units"} • Scrap: ${item.scrapPercent}% • Eff: ${item.effectiveQuantity.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${item.itemCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('@ ₹${item.unitCost.toStringAsFixed(2)}/unit', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
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
            ],
          ),
        ),
      ),
    );
  }
}
