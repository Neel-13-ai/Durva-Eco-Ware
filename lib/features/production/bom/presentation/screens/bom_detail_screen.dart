import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/production/bom/application/providers/bom_providers.dart';

class BomDetailScreen extends ConsumerWidget {
  const BomDetailScreen({super.key, required this.bomId});

  final int bomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bomAsync = ref.watch(bomDetailProvider(bomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('BOM Recipe Details'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/bom/$bomId/edit'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: bomAsync.when(
        data: (bom) {
          if (bom == null) {
            return const Center(child: Text('BOM recipe not found'));
          }

          final isEffective = bom.isEffectiveNow;

          return SingleChildScrollView(
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
                          Text(
                            bom.bomCode,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isEffective ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Text(
                              isEffective ? 'ACTIVE RECIPE' : 'INACTIVE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isEffective ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _InfoRow(label: 'Output Product', value: bom.finishedProductName ?? 'Product #${bom.finishedProductId}'),
                      _InfoRow(label: 'Recipe Version', value: 'v${bom.versionNo}'),
                      _InfoRow(label: 'Standard Batch Size', value: '${bom.batchSize.toStringAsFixed(0)} ${bom.finishedProductUnit ?? "Units"}'),
                      _InfoRow(label: 'Effective Date Range', value: '${bom.effectiveFrom.day}/${bom.effectiveFrom.month}/${bom.effectiveFrom.year} - ${bom.effectiveTo != null ? "${bom.effectiveTo!.day}/${bom.effectiveTo!.month}/${bom.effectiveTo!.year}" : "Present"}'),
                      _InfoRow(label: 'Total Batch Cost', value: '₹${bom.totalBatchCost.toStringAsFixed(2)}'),
                      _InfoRow(label: 'Estimated Cost / Unit', value: '₹${bom.costPerUnit.toStringAsFixed(3)}'),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // Component List Section
                Text(
                  'Bill of Materials Items (${bom.items.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: Spacing.sm),

                if (bom.items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.xl),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text('No component details recorded for this BOM.', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  )
                else
                  ...bom.items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: Spacing.sm),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.rawMaterialName ?? 'Material #${item.rawMaterialId}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  Text(
                                    '₹${item.itemCost.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Base: ${item.quantityRequired} ${item.unitName ?? "Units"} • Scrap: ${item.scrapPercent}%',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  Text(
                                    'Eff Qty: ${item.effectiveQuantity.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
