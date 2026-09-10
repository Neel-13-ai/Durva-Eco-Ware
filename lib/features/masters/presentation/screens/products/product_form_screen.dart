import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/product_form_controller.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final int? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _purchasePriceCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _reorderCtrl;
  late TextEditingController _hsnCtrl;
  late TextEditingController _taxCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _barcodeCtrl = TextEditingController();
    _purchasePriceCtrl = TextEditingController();
    _sellingPriceCtrl = TextEditingController();
    _minStockCtrl = TextEditingController();
    _reorderCtrl = TextEditingController();
    _hsnCtrl = TextEditingController();
    _taxCtrl = TextEditingController();

    if (widget.productId != null) {
      Future.microtask(() async {
        final product = await ref.read(productDetailProvider(widget.productId!).future);
        ref.read(productFormControllerProvider.notifier).initialize(product);
        if (mounted) {
          _populateFields(product);
        }
      });
    } else {
      Future.microtask(() {
        ref.read(productFormControllerProvider.notifier).initialize(null);
      });
    }
  }

  void _populateFields(ProductDto p) {
    _nameCtrl.text = p.name;
    _codeCtrl.text = p.code;
    _barcodeCtrl.text = p.barcode ?? '';
    _purchasePriceCtrl.text = p.purchasePrice > 0 ? p.purchasePrice.toString() : '';
    _sellingPriceCtrl.text = p.sellingPrice > 0 ? p.sellingPrice.toString() : '';
    _minStockCtrl.text = p.minStockLevel > 0 ? p.minStockLevel.toString() : '';
    _reorderCtrl.text = p.reorderLevel > 0 ? p.reorderLevel.toString() : '';
    _hsnCtrl.text = p.hsnCode ?? '';
    _taxCtrl.text = p.taxRate > 0 ? p.taxRate.toString() : '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _minStockCtrl.dispose();
    _reorderCtrl.dispose();
    _hsnCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormControllerProvider);
    final formNotifier = ref.read(productFormControllerProvider.notifier);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final unitsAsync = ref.watch(activeUnitsProvider);

    final isRaw = formState.productType == ProductType.rawMaterial;
    final isEditing = widget.productId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit ${isRaw ? "Raw Material" : "Item"}'
              : 'New ${isRaw ? "Raw Material" : "Item"}',
        ),
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
            onPressed: formState.status == FormStatus.submitting
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final success = await formNotifier.submit();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Item updated successfully'
                                  : 'Item created successfully',
                            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
            child: formState.status == FormStatus.submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    isEditing ? 'UPDATE ITEM' : 'SAVE ITEM',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              // Error banner if any
              if (formState.failure != null) ...[
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formState.failure!.message,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
              ],

              // Item Type Segmented Selector
              const Text('Item Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<ProductType>(
                  segments: const [
                    ButtonSegment(
                      value: ProductType.finishedGood,
                      label: Text('Finished Good'),
                      icon: Icon(Icons.dinner_dining_outlined),
                    ),
                    ButtonSegment(
                      value: ProductType.rawMaterial,
                      label: Text('Raw Material'),
                      icon: Icon(Icons.layers_outlined),
                    ),
                    ButtonSegment(
                      value: ProductType.packaging,
                      label: Text('Packaging'),
                      icon: Icon(Icons.all_inbox_outlined),
                    ),
                  ],
                  selected: {formState.productType},
                  onSelectionChanged: (set) {
                    formNotifier.setProductType(set.first);
                  },
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Item Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., 10 Inch Round Plate, Areca Palm Leaf Sheet',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Item name is required' : null,
                onChanged: formNotifier.setName,
              ),
              const SizedBox(height: Spacing.md),

              // Item Code & Barcode
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Item Code *',
                        hintText: 'e.g., FG-PL01, RM-APL001',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Code is required' : null,
                      onChanged: formNotifier.setCode,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                        hintText: '8906123450012',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: formNotifier.setBarcode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Category & Unit Selectors
              Row(
                children: [
                  Expanded(
                    child: categoriesAsync.when(
                      data: (cats) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: formState.categoryId > 0 ? formState.categoryId : null,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        items: cats
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        validator: (val) => (val == null || val == 0) ? 'Category is required' : null,
                        onChanged: (val) {
                          if (val != null) formNotifier.setCategoryId(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading categories'),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: unitsAsync.when(
                      data: (units) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: formState.unitId > 0 ? formState.unitId : null,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        items: units
                            .map((u) => DropdownMenuItem(
                                  value: u.id,
                                  child: Text('${u.name} (${u.symbol})', overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        validator: (val) => (val == null || val == 0) ? 'Unit is required' : null,
                        onChanged: (val) {
                          if (val != null) formNotifier.setUnitId(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading units'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Pricing
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Purchase Rate (₹)',
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          formNotifier.setPurchasePrice(double.tryParse(val) ?? 0.0),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (₹)',
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          formNotifier.setSellingPrice(double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Stock Thresholds
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Min Stock Level',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          formNotifier.setMinStockLevel(double.tryParse(val) ?? 0.0),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          formNotifier.setReorderLevel(double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Tax & Compliance
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hsnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'HSN Code',
                        hintText: '482369',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: formNotifier.setHsnCode,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _taxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'GST Tax Rate (%)',
                        suffixText: '%',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          formNotifier.setTaxRate(double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Active Switch
              SwitchListTile(
                title: const Text('Active Status'),
                subtitle: const Text('Allow this item to be selected in POs and production'),
                value: formState.isActive,
                activeThumbColor: BrandColors.primary,
                onChanged: formNotifier.setIsActive,
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
