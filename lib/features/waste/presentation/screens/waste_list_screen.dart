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
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.invalidate(wasteEntriesListProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              children: [
                const Expanded(
                  child: Text(
                    'Scrap & Waste Entries',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/waste/reasons'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
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

class _WasteEntryCard extends ConsumerWidget {
  const _WasteEntryCard({required this.entry});

  final WasteEntryDto entry;

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scrap Entry?'),
        content: Text(
          'Scrap log for "${entry.productName ?? "Item #${entry.productId}"}" (${entry.quantity} ${entry.unitName ?? "Units"}) will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Deleting scrap entry...')),
              );
              final result = await ref.read(wasteRepositoryProvider).deleteEntry(entry.id);
              result.when(
                success: (_) {
                  ref.invalidate(wasteEntriesListProvider);
                  ref.invalidate(wasteMetricsProvider);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Scrap entry deleted successfully'),
                      backgroundColor: BrandColors.primary,
                    ),
                  );
                },
                failure: (err) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: ${err.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final qtyCtrl = TextEditingController(text: entry.quantity.toString());
    final notesCtrl = TextEditingController(text: entry.notes ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Scrap Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${entry.productName ?? "Product #${entry.productId}"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity (${entry.unitName ?? "Units"}) *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes / Root Cause',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.primary),
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
              if (qty <= 0) return;
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Updating scrap entry...'), duration: Duration(seconds: 1)),
              );

              final updated = entry.copyWith(
                quantity: qty,
                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              );

              final result = await ref.read(wasteRepositoryProvider).updateEntry(entry.id, updated);
              result.when(
                success: (_) {
                  ref.invalidate(wasteEntriesListProvider);
                  ref.invalidate(wasteMetricsProvider);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Scrap entry updated successfully'),
                      backgroundColor: BrandColors.primary,
                    ),
                  );
                },
                failure: (err) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update: ${err.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(Radii.sm)),
                  child: Text(
                    entry.disposalMethod.name.toUpperCase(),
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${entry.wasteDate.day}/${entry.wasteDate.month}/${entry.wasteDate.year}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: BrandColors.primary),
                  tooltip: 'Edit Entry',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditDialog(context, ref),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  tooltip: 'Delete Entry',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDeleteConfirmation(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.productName ?? 'Item #${entry.productId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Reason: ${entry.wasteReasonName ?? "Scrap"} • Quantity: ${entry.quantity} ${entry.unitName ?? "Units"}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loss: ₹${entry.totalLossAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                ),
              ],
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
