import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/master_form_controllers.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';

class WarehouseScreen extends ConsumerWidget {
  const WarehouseScreen({super.key});

  void _showWarehouseDialog(BuildContext context, WidgetRef ref, {WarehouseDto? warehouse}) {
    final nameCtrl = TextEditingController(text: warehouse?.name ?? '');
    final codeCtrl = TextEditingController(text: warehouse?.code ?? '');
    final addressCtrl = TextEditingController(text: warehouse?.address ?? '');
    final cityCtrl = TextEditingController(text: warehouse?.city ?? '');
    final stateCtrl = TextEditingController(text: warehouse?.state ?? '');
    final managerCtrl = TextEditingController(text: warehouse?.managerName ?? '');
    final phoneCtrl = TextEditingController(text: warehouse?.contactPhone ?? '');
    bool isActive = warehouse?.isActive ?? true;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(warehouse == null ? 'Add Warehouse' : 'Edit Warehouse'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Warehouse Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code * (e.g. WH-001)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: stateCtrl,
                        decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: managerCtrl,
                  decoration: const InputDecoration(labelText: 'Manager Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
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
                if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
                final dto = WarehouseDto(
                  id: warehouse?.id ?? 0,
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim(),
                  address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                  city: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
                  state: stateCtrl.text.trim().isEmpty ? null : stateCtrl.text.trim(),
                  managerName: managerCtrl.text.trim().isEmpty ? null : managerCtrl.text.trim(),
                  contactPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  isActive: isActive,
                );
                final ok = await ref
                    .read(warehouseFormControllerProvider.notifier)
                    .save(dto, isEditing: warehouse != null);
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
    final warehousesAsync = ref.watch(warehousesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses & Locations'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(warehousesListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showWarehouseDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: warehousesAsync.when(
        data: (warehouses) {
          if (warehouses.isEmpty) {
            return const Center(child: Text('No warehouses configured. Tap + to add one.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(warehousesListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: warehouses.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final wh = warehouses[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4527A0).withValues(alpha: 0.1),
                      child: const Icon(Icons.warehouse, color: Color(0xFF4527A0), size: 20),
                    ),
                    title: Text(wh.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Code: ${wh.code}${wh.managerName != null ? ' • Mgr: ${wh.managerName}' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showWarehouseDialog(context, ref, warehouse: wh),
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
