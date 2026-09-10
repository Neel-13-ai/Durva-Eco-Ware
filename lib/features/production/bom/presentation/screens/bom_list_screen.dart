import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/production/bom/data/models/bom_header_dto.dart';
import 'package:durvaeco/features/production/bom/application/providers/bom_providers.dart';

class BomListScreen extends ConsumerStatefulWidget {
  const BomListScreen({super.key});

  @override
  ConsumerState<BomListScreen> createState() => _BomListScreenState();
}

class _BomListScreenState extends ConsumerState<BomListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bomsAsync = ref.watch(bomsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill of Materials (BOM) & Recipes'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(bomsListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push('/bom/new'),
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create BOM Recipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by BOM code, product name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          const Divider(height: 1),

          // List of BOMs
          Expanded(
            child: bomsAsync.when(
              data: (boms) {
                final filtered = boms.where((b) {
                  if (_searchQuery.isEmpty) return true;
                  final code = b.bomCode.toLowerCase();
                  final name = (b.finishedProductName ?? '').toLowerCase();
                  return code.contains(_searchQuery) || name.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.science_outlined, size: 48, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text('No BOM recipes found', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(Spacing.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                  itemBuilder: (ctx, index) {
                    final bom = filtered[index];
                    return _BomCard(bom: bom);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _BomCard extends StatelessWidget {
  const _BomCard({required this.bom});

  final BomHeaderDto bom;

  @override
  Widget build(BuildContext context) {
    final isEffective = bom.isEffectiveNow;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => context.push('/bom/${bom.id}'),
        borderRadius: BorderRadius.circular(Radii.md),
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
                      color: isEffective ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Text(
                      isEffective ? 'ACTIVE RECIPE' : 'INACTIVE / DRAFT',
                      style: TextStyle(
                        color: isEffective ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrandColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Text(
                      'v${bom.versionNo}',
                      style: const TextStyle(color: BrandColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    bom.bomCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bom.finishedProductName ?? 'Finished Good #${bom.finishedProductId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(
                'Batch Size: ${bom.batchSize.toStringAsFixed(0)} ${bom.finishedProductUnit ?? "Units"} • Components: ${bom.componentCount}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Batch Cost', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('₹${bom.totalBatchCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cost / Unit', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        '₹${bom.costPerUnit.toStringAsFixed(3)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: BrandColors.primary),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
