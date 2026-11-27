import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/product_form_controller.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  final int productId;
  final ProductDto? initialProduct;

  void _confirmDelete(BuildContext context, WidgetRef ref, ProductDto product) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "${product.name}" (${product.code})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SemanticColors.danger,
              foregroundColor: BrandColors.onPrimary,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref.read(productFormControllerProvider.notifier).delete(product.id);
              if (!context.mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Item "${product.name}" deleted.'),
                    backgroundColor: SemanticColors.success,
                  ),
                );
                context.pop();
              } else {
                final err = ref.read(productFormControllerProvider).failure?.message ??
                    'Failed to delete item';
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: SemanticColors.danger,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final product = productAsync.valueOrNull ?? initialProduct;
    final categories = ref.watch(activeCategoriesProvider).valueOrNull ?? const [];
    final units = ref.watch(activeUnitsProvider).valueOrNull ?? const [];

    String? resolveCategory(ProductDto p) {
      if (p.categoryName != null && p.categoryName!.isNotEmpty) return p.categoryName;
      for (final c in categories) {
        if (c.id == p.categoryId) return c.name;
      }
      return null;
    }

    String? resolveUnit(ProductDto p) {
      if (p.unitName != null && p.unitName!.isNotEmpty) return p.unitName;
      for (final u in units) {
        if (u.id == p.unitId) return '${u.name} (${u.symbol})';
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Item',
            onPressed: () => context.push('/masters/products/$productId/edit'),
          ),
        ],
      ),
      backgroundColor: SemanticColors.background,
      body: product != null
          ? RefreshIndicator(
              color: BrandColors.primary,
              onRefresh: () => ref.refresh(productDetailProvider(productId).future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.md,
                  Spacing.xl,
                ),
                child: _buildDetails(
                  context,
                  ref,
                  product,
                  categoryName: resolveCategory(product),
                  unitName: resolveUnit(product),
                ),
              ),
            )
          : productAsync.when(
              data: (p) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.md,
                  Spacing.xl,
                ),
                child: _buildDetails(
                  context,
                  ref,
                  p,
                  categoryName: resolveCategory(p),
                  unitName: resolveUnit(p),
                ),
              ),
              loading: () => const ShimmerDetailCard(),
              error: (err, _) {
                final cleanMessage = err.toString().replaceFirst('Exception: ', '');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 44,
                          color: SemanticColors.danger,
                        ),
                        const SizedBox(height: Spacing.md),
                        const Text(
                          'Could not load item details',
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
                          onPressed: () => ref.invalidate(productDetailProvider(productId)),
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
                );
              },
            ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    WidgetRef ref,
    ProductDto p, {
    String? categoryName,
    String? unitName,
  }) {
    final isRaw = p.productType == ProductType.rawMaterial;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card
        _SurfaceCard(
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
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (p.isActive ? SemanticColors.success : SemanticColors.danger)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Text(
                      p.isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: p.isActive ? SemanticColors.success : SemanticColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: SemanticColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Code: ${p.code}${p.barcode != null && p.barcode!.isNotEmpty ? ' • Barcode: ${p.barcode}' : ''}',
                style: const TextStyle(fontSize: 13, color: SemanticColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),

        // Stock & Pricing Overview
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Current Stock',
                value:
                    '${p.currentStock.toStringAsFixed(0)}${p.unitName != null && p.unitName!.isNotEmpty ? ' ${p.unitName}' : ''}',
                color: p.isLowStock ? SemanticColors.danger : BrandColors.primary,
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: isRaw ? 'Purchase Rate' : 'Selling Price',
                value:
                    '₹${(isRaw ? p.purchasePrice : p.sellingPrice).toStringAsFixed(2)}',
                color: SemanticColors.text,
                icon: Icons.currency_rupee,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),

        // Specification Details Card
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specifications',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: SemanticColors.text,
                ),
              ),
              const Divider(height: 24, color: SemanticColors.border),
              _DetailRow(label: 'Category', value: categoryName ?? 'Unassigned'),
              _DetailRow(label: 'Unit of Measure', value: unitName ?? '-'),
              _DetailRow(label: 'Min Stock Level', value: p.minStockLevel.toStringAsFixed(0)),
              if (p.maxStockLevel != null && p.maxStockLevel! > 0)
                _DetailRow(label: 'Max Stock Level', value: p.maxStockLevel!.toStringAsFixed(0)),
              if (p.description != null && p.description!.isNotEmpty)
                _DetailRow(label: 'Description', value: p.description!),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, ref, p),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text(
              'Delete Item',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: SemanticColors.danger,
              side: BorderSide(
                color: SemanticColors.danger.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: SemanticColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SemanticColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SemanticColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: SemanticColors.textMuted, fontSize: 13),
          ),
          const SizedBox(width: Spacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: SemanticColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
