import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, this.initialType});

  final String? initialType;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialType != null) {
        if (widget.initialType == 'RAW_MATERIAL') {
          ref.read(productSelectedTypeProvider.notifier).state = ProductType.rawMaterial;
        } else if (widget.initialType == 'FINISHED_GOOD') {
          ref.read(productSelectedTypeProvider.notifier).state = ProductType.finishedGood;
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final selectedType = ref.watch(productSelectedTypeProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final unitsAsync = ref.watch(activeUnitsProvider);
    final selectedCategory = ref.watch(productSelectedCategoryProvider);

    final units = unitsAsync.valueOrNull;
    final unitLabelMap = <int, String>{
      if (units != null)
        for (final u in units) u.id: u.symbol,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedType == ProductType.rawMaterial
              ? 'Raw Materials Master'
              : selectedType == ProductType.finishedGood
                  ? 'Finished Goods Master'
                  : 'Items & Products',
        ),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.onPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.xs),
            child: IconButton(
              onPressed: () => context.push('/masters/products/new'),
              tooltip: 'Add Item',
              icon: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: BrandColors.onPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: BrandColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: SemanticColors.background,
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              12,
            ),
            decoration: const BoxDecoration(
              color: SemanticColors.surface,
              border: Border(
                bottom: BorderSide(color: SemanticColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search name, code, or barcode',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: SemanticColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: SemanticColors.textMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: SemanticColors.textMuted,
                            ),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              ref.read(productSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: SemanticColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: const BorderSide(color: SemanticColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: const BorderSide(color: SemanticColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    ref.read(productSearchQueryProvider.notifier).state = val;
                  },
                ),
                const SizedBox(height: 12),
                // Type Filter Tabs (fits cleanly without clipping)
                Row(
                  children: [
                    _TypeTab(
                      label: 'All',
                      selected: selectedType == null,
                      onTap: () => ref.read(productSelectedTypeProvider.notifier).state = null,
                    ),
                    const SizedBox(width: Spacing.sm),
                    _TypeTab(
                      label: 'Raw Materials',
                      selected: selectedType == ProductType.rawMaterial,
                      onTap: () => ref.read(productSelectedTypeProvider.notifier).state =
                          ProductType.rawMaterial,
                    ),
                    const SizedBox(width: Spacing.sm),
                    _TypeTab(
                      label: 'Finished Goods',
                      selected: selectedType == ProductType.finishedGood,
                      onTap: () => ref.read(productSelectedTypeProvider.notifier).state =
                          ProductType.finishedGood,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Category Filter + Item Count
                Row(
                  children: [
                    Expanded(
                      child: categoriesAsync.maybeWhen(
                        data: (cats) => Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: SemanticColors.background,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border.all(color: SemanticColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: cats.any((c) => c.id == selectedCategory)
                                  ? selectedCategory
                                  : null,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: SemanticColors.textMuted,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: SemanticColors.text,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('All Categories'),
                                ),
                                ...cats.map(
                                  (c) => DropdownMenuItem<int?>(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                ref.read(productSelectedCategoryProvider.notifier).state = val;
                              },
                            ),
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Text(
                      productsAsync.maybeWhen(
                        data: (list) => '${list.length} ${list.length == 1 ? 'item' : 'items'}',
                        orElse: () => '',
                      ),
                      style: const TextStyle(
                        fontSize: FontSizes.caption,
                        fontWeight: FontWeight.w600,
                        color: SemanticColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Product List
          Expanded(
            child: RefreshIndicator(
              color: BrandColors.primary,
              onRefresh: () => ref.refresh(productsListProvider.future),
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.lg,
                            vertical: Spacing.xxl,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: BrandColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(Radii.lg),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 28,
                                  color: BrandColors.primary,
                                ),
                              ),
                              const SizedBox(height: Spacing.md),
                              const Text(
                                'No items found',
                                style: TextStyle(
                                  fontSize: FontSizes.subtitle,
                                  fontWeight: FontWeight.w600,
                                  color: SemanticColors.text,
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              const Text(
                                'Try adjusting your filters or add a new item.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: SemanticColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: Spacing.lg),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/masters/products/new'),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BrandColors.primary,
                                  foregroundColor: BrandColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Radii.md),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.md,
                      Spacing.md,
                      Spacing.md,
                      Spacing.xl,
                    ),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final resolvedUnit = (product.unitName != null && product.unitName!.isNotEmpty)
                          ? product.unitName
                          : unitLabelMap[product.unitId];
                      return _ProductCard(
                        product: product,
                        resolvedUnitName: resolvedUnit,
                        onTap: () => context.push('/masters/products/${product.id}', extra: product),
                      );
                    },
                  );
                },
                loading: () => const ShimmerList(itemCount: 8, cardHeight: 96),
                error: (err, _) {
                  final cleanMessage = err.toString().replaceFirst('Exception: ', '');
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                          vertical: Spacing.xxl,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_off_outlined,
                              size: 44,
                              color: SemanticColors.danger,
                            ),
                            const SizedBox(height: Spacing.md),
                            const Text(
                              'Could not load items',
                              style: TextStyle(
                                fontSize: FontSizes.subtitle,
                                fontWeight: FontWeight.w600,
                                color: SemanticColors.text,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              cleanMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: SemanticColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            ElevatedButton.icon(
                              onPressed: () => ref.invalidate(productsListProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BrandColors.primary,
                                foregroundColor: BrandColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? BrandColors.primary.withValues(alpha: 0.12)
          : SemanticColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: selected ? BrandColors.primary : SemanticColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? BrandColors.primary : SemanticColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    this.resolvedUnitName,
  });

  final ProductDto product;
  final String? resolvedUnitName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRaw = product.productType == ProductType.rawMaterial;
    final isLowStock = product.isLowStock;
    final hasUnit = resolvedUnitName != null && resolvedUnitName!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: SemanticColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SemanticColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRaw
                            ? BrandColors.secondary.withValues(alpha: 0.1)
                            : BrandColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(
                        isRaw ? 'RAW MATERIAL' : 'FINISHED GOOD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isRaw ? BrandColors.secondary : BrandColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        hasUnit ? '${product.code} • $resolvedUnitName' : product.code,
                        style: const TextStyle(
                          fontSize: FontSizes.caption,
                          fontWeight: FontWeight.w500,
                          color: SemanticColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLowStock) ...[
                      const SizedBox(width: Spacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: SemanticColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: SemanticColors.danger,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Low Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SemanticColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SemanticColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: SemanticColors.border),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Stock: ${product.currentStock.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isLowStock
                                    ? SemanticColors.danger
                                    : SemanticColors.success,
                              ),
                            ),
                            if (product.minStockLevel > 0)
                              TextSpan(
                                text: '  (Min ${product.minStockLevel.toStringAsFixed(0)})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: SemanticColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      isRaw ? 'Purchase ' : 'Selling ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SemanticColors.textMuted,
                      ),
                    ),
                    Text(
                      '₹${(isRaw ? product.purchasePrice : product.sellingPrice).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SemanticColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
