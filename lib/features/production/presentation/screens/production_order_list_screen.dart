import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';

class ProductionOrderListScreen extends ConsumerWidget {
  const ProductionOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(productionOrdersListProvider);
    final statusFilter = ref.watch(productionStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production & Manufacturing'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productionOrdersListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/production/new'),
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Production Run', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Runs',
                    isSelected: statusFilter == null,
                    onSelected: () => ref.read(productionStatusFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Planned',
                    isSelected: statusFilter == ProductionStatus.planned,
                    onSelected: () => ref.read(productionStatusFilterProvider.notifier).state = ProductionStatus.planned,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'In Progress',
                    isSelected: statusFilter == ProductionStatus.inProgress,
                    onSelected: () => ref.read(productionStatusFilterProvider.notifier).state = ProductionStatus.inProgress,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completed',
                    isSelected: statusFilter == ProductionStatus.completed,
                    onSelected: () => ref.read(productionStatusFilterProvider.notifier).state = ProductionStatus.completed,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Orders List
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.precision_manufacturing_outlined, size: 48, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text('No production orders found', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(Spacing.md),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                  itemBuilder: (ctx, index) {
                    final order = orders[index];
                    return _ProductionOrderCard(order: order);
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: BrandColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? BrandColors.primary : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}

class _ProductionOrderCard extends StatelessWidget {
  const _ProductionOrderCard({required this.order});

  final ProductionOrderDto order;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    final statusLabel = order.status.name.toUpperCase();

    switch (order.status) {
      case ProductionStatus.completed:
        statusColor = const Color(0xFF2E7D32);
        statusBg = const Color(0xFFE8F5E9);
        break;
      case ProductionStatus.inProgress:
        statusColor = const Color(0xFF1565C0);
        statusBg = const Color(0xFFE3F2FD);
        break;
      case ProductionStatus.planned:
        statusColor = const Color(0xFFE65100);
        statusBg = const Color(0xFFFFF3E0);
        break;
      case ProductionStatus.cancelled:
        statusColor = Colors.red;
        statusBg = Colors.red.shade50;
        break;
      case ProductionStatus.draft:
        statusColor = const Color(0xFF64748B);
        statusBg = const Color(0xFFF1F5F9);
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => context.push('/production/${order.id}/track'),
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
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(Radii.sm)),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Text(order.shiftName, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const Spacer(),
                  Text(
                    order.productionNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.finishedProductName ?? 'Product #${order.finishedProductId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Planned: ${order.plannedQty.toStringAsFixed(0)} ${order.finishedProductUnit ?? "Units"}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const Spacer(),
                  Text(
                    'Good Output: ${order.totalGoodOutput.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BrandColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: order.stageProgress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    order.status == ProductionStatus.completed ? const Color(0xFF2E7D32) : BrandColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stages Progress: ${(order.stageProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const Text('Track Stages →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BrandColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
