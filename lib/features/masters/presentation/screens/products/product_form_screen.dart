import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/product_form_controller.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final int? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _sellingPriceCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _maxStockCtrl;
  late final TextEditingController _descriptionCtrl;
  bool _loadingInitial = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _skuCtrl = TextEditingController();
    _barcodeCtrl = TextEditingController();
    _purchasePriceCtrl = TextEditingController();
    _sellingPriceCtrl = TextEditingController();
    _minStockCtrl = TextEditingController();
    _maxStockCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();

    if (widget.productId != null) {
      _loadingInitial = true;
      Future.microtask(() async {
        try {
          final product = await ref.read(productDetailProvider(widget.productId!).future);
          if (!mounted) return;
          ref.read(productFormControllerProvider.notifier).initialize(product);
          _populateFields(product);
        } finally {
          if (mounted) setState(() => _loadingInitial = false);
        }
      });
    } else {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(productFormControllerProvider.notifier).initialize(null);
      });
    }
  }

  void _populateFields(ProductDto p) {
    _nameCtrl.text = p.name;
    _codeCtrl.text = p.code;
    _skuCtrl.text = p.sku ?? '';
    _barcodeCtrl.text = p.barcode ?? '';
    _purchasePriceCtrl.text = p.purchasePrice > 0 ? p.purchasePrice.toString() : '';
    _sellingPriceCtrl.text = p.sellingPrice > 0 ? p.sellingPrice.toString() : '';
    _minStockCtrl.text = p.minStockLevel > 0 ? p.minStockLevel.toString() : '';
    _maxStockCtrl.text = (p.maxStockLevel ?? 0) > 0 ? p.maxStockLevel!.toString() : '';
    _descriptionCtrl.text = p.description ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _minStockCtrl.dispose();
    _maxStockCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixText: suffixText,
      errorMaxLines: 2,
      filled: true,
      fillColor: SemanticColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: SemanticColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: SemanticColors.border),
      ),
    );
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
              : 'Add ${isRaw ? "Raw Material" : "Item"}',
        ),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.onPrimary,
        elevation: 0,
      ),
      backgroundColor: SemanticColors.background,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: SemanticColors.surface,
          border: Border(top: BorderSide(color: SemanticColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (_loadingInitial || formState.status == FormStatus.submitting)
                    ? null
                    : () async {
                        if (!_hasSubmitted) {
                          setState(() => _hasSubmitted = true);
                        }
                        if (_formKey.currentState?.validate() ?? false) {
                          final success = await formNotifier.submit();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Item updated successfully.'
                                      : 'Item created successfully.',
                                ),
                                backgroundColor: SemanticColors.success,
                              ),
                            );
                            context.pop();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: BrandColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                child: formState.status == FormStatus.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: BrandColors.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Save Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: FontSizes.body,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
      body: _loadingInitial
          ? const ShimmerList(itemCount: 6, cardHeight: 64)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.md,
                Spacing.md,
                Spacing.xl,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: _hasSubmitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (formState.failure != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: Spacing.md),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SemanticColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(
                            color: SemanticColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: SemanticColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                formState.failure!.message,
                                style: const TextStyle(
                                  color: SemanticColors.danger,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const _SectionHeader('Item Type'),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeOption(
                            label: 'Finished',
                            icon: Icons.dinner_dining_outlined,
                            selected: formState.productType == ProductType.finishedGood,
                            onTap: () => formNotifier.setProductType(ProductType.finishedGood),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: _TypeOption(
                            label: 'Raw Material',
                            icon: Icons.layers_outlined,
                            selected: formState.productType == ProductType.rawMaterial,
                            onTap: () => formNotifier.setProductType(ProductType.rawMaterial),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: _TypeOption(
                            label: 'Packaging',
                            icon: Icons.all_inbox_outlined,
                            selected: formState.productType == ProductType.packaging,
                            onTap: () => formNotifier.setProductType(ProductType.packaging),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),

                    const _SectionHeader('Basic Information'),
                    const SizedBox(height: Spacing.sm),
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        'Item Name *',
                        hint: 'e.g., 10 Inch Round Plate',
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Item name is required' : null,
                      onChanged: formNotifier.setName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _skuCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        'SKU *',
                        hint: 'e.g., FG-PL001',
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'SKU is required' : null,
                      onChanged: formNotifier.setSku,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              'Item Code *',
                              hint: 'e.g., RM-001',
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'Code is required' : null,
                            onChanged: formNotifier.setCode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              'Barcode',
                              hint: '8906123450012',
                            ),
                            onChanged: formNotifier.setBarcode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),

                    const _SectionHeader('Classification'),
                    const SizedBox(height: Spacing.sm),
                    categoriesAsync.when(
                      data: (cats) {
                        final validCat = cats.any((c) => c.id == formState.categoryId)
                            ? formState.categoryId
                            : null;
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: validCat,
                          decoration: _inputDecoration('Category *'),
                          items: cats
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          validator: (val) =>
                              (val == null || val == 0) ? 'Category is required' : null,
                          onChanged: (val) {
                            if (val != null) formNotifier.setCategoryId(val);
                          },
                        );
                      },
                      loading: () => const ShimmerDropdown(labelText: 'Category *'),
                      error: (_, __) => OutlinedButton.icon(
                        onPressed: () => ref.invalidate(activeCategoriesProvider),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Categories'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    unitsAsync.when(
                      data: (units) {
                        final validUnit = units.any((u) => u.id == formState.unitId)
                            ? formState.unitId
                            : null;
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: validUnit,
                          decoration: _inputDecoration('Unit *'),
                          items: units
                              .map((u) => DropdownMenuItem(
                                    value: u.id,
                                    child: Text(
                                      '${u.name} (${u.symbol})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          validator: (val) =>
                              (val == null || val == 0) ? 'Unit is required' : null,
                          onChanged: (val) {
                            if (val != null) formNotifier.setUnitId(val);
                          },
                        );
                      },
                      loading: () => const ShimmerDropdown(labelText: 'Unit *'),
                      error: (_, __) => OutlinedButton.icon(
                        onPressed: () => ref.invalidate(activeUnitsProvider),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Units'),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),

                    const _SectionHeader('Pricing & Stock'),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration('Purchase Rate', prefixText: '₹ '),
                            onChanged: (val) =>
                                formNotifier.setPurchasePrice(double.tryParse(val) ?? 0.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration('Selling Price', prefixText: '₹ '),
                            onChanged: (val) =>
                                formNotifier.setSellingPrice(double.tryParse(val) ?? 0.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minStockCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration('Min Stock Level'),
                            onChanged: (val) =>
                                formNotifier.setMinStockLevel(double.tryParse(val) ?? 0.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxStockCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration('Max Stock Level'),
                            onChanged: (val) =>
                                formNotifier.setMaxStockLevel(double.tryParse(val)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),

                    const _SectionHeader('Details & Status'),
                    const SizedBox(height: Spacing.sm),
                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 3,
                      minLines: 2,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(
                        'Description',
                        hint: 'Optional notes about this item',
                      ),
                      onChanged: formNotifier.setDescription,
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: SemanticColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        side: const BorderSide(color: SemanticColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SwitchListTile(
                        title: const Text(
                          'Active',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Allow this item in POs and production',
                          style: TextStyle(fontSize: 12, color: SemanticColors.textMuted),
                        ),
                        value: formState.isActive,
                        activeThumbColor: BrandColors.primary,
                        onChanged: formNotifier.setIsActive,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SemanticColors.textMuted,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? BrandColors.primary.withValues(alpha: 0.1)
          : SemanticColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: selected ? BrandColors.primary : SemanticColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? BrandColors.primary : SemanticColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? BrandColors.primary : SemanticColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
