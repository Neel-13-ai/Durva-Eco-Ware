import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/waste/data/models/waste_entry_dto.dart';
import 'package:durvaeco/features/waste/application/providers/waste_providers.dart';

class WasteListScreen extends ConsumerWidget {
  const WasteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(wasteEntriesListProvider);
    final metrics = ref.watch(wasteMetricsProvider);
    final selectedDisposal = ref.watch(wasteDisposalFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste & Scrap Management'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Waste Reasons Setup',
            onPressed: () => context.push('/waste/reasons'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(wasteEntriesListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push('/waste/new'),
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Scrap Incident', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _KpiMetricCard(
                    title: 'Total Scrap Loss',
                    value: '₹${metrics.totalLossAmount.toStringAsFixed(0)}',
                    icon: Icons.trending_down,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _KpiMetricCard(
                    title: 'Recycling / Repulp %',
                    value: '${metrics.recycledPercent.toStringAsFixed(1)}%',
                    icon: Icons.recycling,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: _KpiMetricCard(
                    title: 'Total Scrap Units',
                    value: '${metrics.totalWasteQuantity.toStringAsFixed(0)} Units',
                    icon: Icons.delete_sweep_outlined,
                    color: const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _KpiMetricCard(
                    title: 'Incidents Logged',
                    value: '${metrics.entriesCount}',
                    icon: Icons.receipt_long,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Disposal Method Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All Disposal',
                      isSelected: selectedDisposal == null,
                      onSelected: () => ref.read(wasteDisposalFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Recycled',
                      isSelected: selectedDisposal == DisposalMethod.recycled,
                      onSelected: () => ref.read(wasteDisposalFilterProvider.notifier).state = DisposalMethod.recycled,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Repulped',
                      isSelected: selectedDisposal == DisposalMethod.repulped,
                      onSelected: () => ref.read(wasteDisposalFilterProvider.notifier).state = DisposalMethod.repulped,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Sold as Scrap',
                      isSelected: selectedDisposal == DisposalMethod.soldAsScrap,
                      onSelected: () => ref.read(wasteDisposalFilterProvider.notifier).state = DisposalMethod.soldAsScrap,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Discarded',
                      isSelected: selectedDisposal == DisposalMethod.discarded,
                      onSelected: () => ref.read(wasteDisposalFilterProvider.notifier).state = DisposalMethod.discarded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scrap & Waste Entries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                TextButton(
                  onPressed: () => context.push('/waste/reasons'),
                  child: const Text('Waste Reasons →'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),

            // Entries List
            entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.xl),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.recycling_outlined, size: 40, color: Color(0xFF94A3B8)),
                          SizedBox(height: 8),
                          Text('No scrap incidents logged', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                  itemBuilder: (ctx, index) {
                    final entry = entries[index];
                    return _WasteEntryCard(entry: entry);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
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

class _WasteEntryCard extends StatelessWidget {
  const _WasteEntryCard({required this.entry});

  final WasteEntryDto entry;

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeBg;

    switch (entry.disposalMethod) {
      case DisposalMethod.recycled:
      case DisposalMethod.repulped:
        badgeColor = const Color(0xFF2E7D32);
        badgeBg = const Color(0xFFE8F5E9);
        break;
      case DisposalMethod.soldAsScrap:
        badgeColor = const Color(0xFFE65100);
        badgeBg = const Color(0xFFFFF3E0);
        break;
      case DisposalMethod.discarded:
        badgeColor = Colors.red;
        badgeBg = Colors.red.shade50;
        break;
    }

    return Card(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(Radii.sm)),
                  child: Text(
                    entry.disposalMethod.name.toUpperCase(),
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.wasteDate.day}/${entry.wasteDate.month}/${entry.wasteDate.year}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const Spacer(),
                Text(
                  'Loss: ₹${entry.totalLossAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.productName ?? 'Item #${entry.productId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Reason: ${entry.wasteReasonName ?? "Scrap"} • Quantity: ${entry.quantity} ${entry.unitName ?? "Units"}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${entry.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
            ],
          ],
        ),
      ),
    );
  }
}
