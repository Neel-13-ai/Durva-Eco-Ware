import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/masters/products/$productId/edit'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: productAsync.when(
        data: (p) => SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.productType == ProductType.rawMaterial
                                ? const Color(0xFFE0F2F1)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Text(
                            p.productType == ProductType.rawMaterial
                                ? 'RAW MATERIAL'
                                : 'FINISHED GOOD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: p.productType == ProductType.rawMaterial
                                  ? const Color(0xFF00695C)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.isActive ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Text(
                            p.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: p.isActive ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      p.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text('Code: ${p.code}${p.barcode != null ? ' • Barcode: ${p.barcode}' : ''}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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
                      value: '${p.currentStock.toStringAsFixed(0)} ${p.unitName ?? ""}',
                      color: p.isLowStock ? Colors.red : BrandColors.primary,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _MetricCard(
                      title: p.productType == ProductType.rawMaterial ? 'Purchase Rate' : 'Selling Price',
                      value: '₹${(p.productType == ProductType.rawMaterial ? p.purchasePrice : p.sellingPrice).toStringAsFixed(2)}',
                      color: const Color(0xFF0F172A),
                      icon: Icons.currency_rupee,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Specification Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Master Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(height: 24),
                    _DetailRow(label: 'Category', value: p.categoryName ?? 'Unassigned'),
                    _DetailRow(label: 'Unit of Measure', value: p.unitName ?? '-'),
                    _DetailRow(label: 'Min Stock Threshold', value: p.minStockLevel.toStringAsFixed(0)),
                    _DetailRow(label: 'Reorder Level', value: p.reorderLevel.toStringAsFixed(0)),
                    _DetailRow(label: 'HSN / SAC Code', value: p.hsnCode ?? '-'),
                    _DetailRow(label: 'GST Tax Rate', value: '${p.taxRate.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
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
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
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
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
