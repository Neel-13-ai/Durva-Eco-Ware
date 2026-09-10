import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/purchasing/data/models/purchase_dto.dart';

class PurchaseListScreen extends ConsumerWidget {
  const PurchaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesListProvider);
    final selectedStatus = ref.watch(purchaseFilterStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(purchasesListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
        onPressed: () => context.push('/purchases/new'),
      ),
      body: Column(
        children: [
          // Status Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: selectedStatus == null,
                    selectedColor: BrandColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: BrandColors.primary,
                    onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: selectedStatus == PurchaseStatus.pending,
                    selectedColor: Colors.orange.withValues(alpha: 0.2),
                    checkmarkColor: Colors.orange.shade800,
                    onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = PurchaseStatus.pending,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Approved'),
                    selected: selectedStatus == PurchaseStatus.approved,
                    selectedColor: Colors.blue.withValues(alpha: 0.2),
                    checkmarkColor: Colors.blue.shade800,
                    onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = PurchaseStatus.approved,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Received'),
                    selected: selectedStatus == PurchaseStatus.received,
                    selectedColor: Colors.green.withValues(alpha: 0.2),
                    checkmarkColor: Colors.green.shade800,
                    onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = PurchaseStatus.received,
                  ),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: purchasesAsync.when(
              data: (purchases) {
                if (purchases.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFF94A3B8)),
                        SizedBox(height: Spacing.md),
                        Text('No purchase orders found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Tap + New PO to generate your raw material purchase order', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(Spacing.md),
                  itemCount: purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                  itemBuilder: (context, index) {
                    final po = purchases[index];
                    return _PurchaseCard(purchase: po);
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

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.purchase});

  final PurchaseDto purchase;

  Color _statusColor(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.draft:
        return const Color(0xFF64748B);
      case PurchaseStatus.pending:
        return const Color(0xFFE65100);
      case PurchaseStatus.approved:
        return const Color(0xFF1565C0);
      case PurchaseStatus.partiallyReceived:
        return const Color(0xFF00796B);
      case PurchaseStatus.received:
        return const Color(0xFF2E7D32);
      case PurchaseStatus.cancelled:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(purchase.status);

    return InkWell(
      onTap: () => context.push('/purchases/${purchase.id}'),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
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
                  purchase.purchaseNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Text(
                    purchase.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              purchase.supplierName ?? 'Supplier #${purchase.supplierId}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                Text(
                  '₹${purchase.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
