import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';

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
    final selectedCategory = ref.watch(productSelectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedType == ProductType.rawMaterial
              ? 'Raw Materials Master'
              : selectedType == ProductType.finishedGood
                  ? 'Finished Goods Master'
                  : 'Items & Products Master',
        ),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productsListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        onPressed: () => context.push('/masters/products/new'),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, code or barcode...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(productSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    ref.read(productSearchQueryProvider.notifier).state = val;
                  },
                ),
                const SizedBox(height: Spacing.sm),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Types'),
                        selected: selectedType == null,
                        selectedColor: BrandColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: BrandColors.primary,
                        onSelected: (_) {
                          ref.read(productSelectedTypeProvider.notifier).state = null;
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Finished Goods'),
                        selected: selectedType == ProductType.finishedGood,
                        selectedColor: BrandColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: BrandColors.primary,
                        onSelected: (_) {
                          ref.read(productSelectedTypeProvider.notifier).state =
                              ProductType.finishedGood;
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Raw Materials'),
                        selected: selectedType == ProductType.rawMaterial,
                        selectedColor: BrandColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: BrandColors.primary,
                        onSelected: (_) {
                          ref.read(productSelectedTypeProvider.notifier).state =
                              ProductType.rawMaterial;
                        },
                      ),
                      const SizedBox(width: 8),
                      categoriesAsync.maybeWhen(
                        data: (cats) => DropdownButton<int?>(
                          value: selectedCategory,
                          hint: const Text('Category', style: TextStyle(fontSize: 13)),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...cats.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            ref.read(productSelectedCategoryProvider.notifier).state = val;
                          },
                        ),
                        orElse: () => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Product List
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF94A3B8)),
                        SizedBox(height: Spacing.md),
                        Text(
                          'No items found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        SizedBox(height: Spacing.xs),
                        Text(
                          'Tap + Add Item to create a new product or material',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(productsListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        onTap: () => context.push('/masters/products/${product.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: Spacing.sm),
                      Text('Error: $err', textAlign: TextAlign.center),
                      const SizedBox(height: Spacing.md),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(productsListProvider),
                        style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductDto product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRaw = product.productType == ProductType.rawMaterial;
    final isLowStock = product.isLowStock;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: isLowStock ? Colors.orange.shade300 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRaw ? const Color(0xFFE0F2F1) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Text(
                    isRaw ? 'RAW MATERIAL' : 'FINISHED GOOD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isRaw ? const Color(0xFF00695C) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Code: ${product.code}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 2),
                        Text(
                          'Low Stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unit: ${product.unitName ?? "-"}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                Text(
                  isRaw
                      ? 'Purchase: ₹${product.purchasePrice.toStringAsFixed(2)}'
                      : 'Selling: ₹${product.sellingPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Stock: ${product.currentStock.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isLowStock ? Colors.red.shade700 : const Color(0xFF2E7D32),
                  ),
                ),
                if (product.minStockLevel > 0)
                  Text(
                    'Min Stock: ${product.minStockLevel.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
