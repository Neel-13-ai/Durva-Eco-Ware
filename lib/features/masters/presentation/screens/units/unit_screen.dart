import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/master_form_controllers.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/unit_dto.dart';

class UnitScreen extends ConsumerWidget {
  const UnitScreen({super.key});

  void _showUnitDialog(BuildContext context, WidgetRef ref, {UnitDto? unit}) {
    final nameCtrl = TextEditingController(text: unit?.name ?? '');
    final symbolCtrl = TextEditingController(text: unit?.symbol ?? '');
    final descCtrl = TextEditingController(text: unit?.description ?? '');
    bool isActive = unit?.isActive ?? true;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(unit == null ? 'Add Unit' : 'Edit Unit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Unit Name *',
                    hintText: 'e.g. Kilogram, Piece, Bundle',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: symbolCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Symbol *',
                    hintText: 'e.g. Kg, Pcs, Bdl',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  activeThumbColor: BrandColors.primary,
                  onChanged: (v) => setState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || symbolCtrl.text.trim().isEmpty) return;
                final dto = UnitDto(
                  id: unit?.id ?? 0,
                  name: nameCtrl.text.trim(),
                  symbol: symbolCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  isActive: isActive,
                );
                final ok = await ref
                    .read(unitFormControllerProvider.notifier)
                    .save(dto, isEditing: unit != null);
                if (ok && dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Units of Measure'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(unitsListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showUnitDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: unitsAsync.when(
        data: (units) {
          if (units.isEmpty) {
            return const Center(child: Text('No units found. Tap + to create one.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(unitsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: units.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final u = units[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: BrandColors.secondary.withValues(alpha: 0.1),
                      child: Text(
                        u.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: BrandColors.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Symbol: ${u.symbol}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showUnitDialog(context, ref, unit: u),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
