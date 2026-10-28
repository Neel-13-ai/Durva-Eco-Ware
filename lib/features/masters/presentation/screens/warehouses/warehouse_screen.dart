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
    String? nameError;
    String? codeError;
    String? dialogError;
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(warehouse == null ? 'Add Warehouse' : 'Edit Warehouse'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogError!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Warehouse Name *',
                    border: const OutlineInputBorder(),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) setState(() => nameError = null);
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Code * (e.g. WH-001)',
                    border: const OutlineInputBorder(),
                    errorText: codeError,
                  ),
                  onChanged: (_) {
                    if (codeError != null) setState(() => codeError = null);
                  },
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
              onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final code = codeCtrl.text.trim();
                      bool hasError = false;

                      if (name.isEmpty) {
                        setState(() => nameError = 'Warehouse name is required');
                        hasError = true;
                      }
                      if (code.isEmpty) {
                        setState(() => codeError = 'Warehouse code is required');
                        hasError = true;
                      }
                      if (hasError) return;

                      setState(() {
                        isSaving = true;
                        dialogError = null;
                      });

                      final dto = WarehouseDto(
                        id: warehouse?.id ?? 0,
                        name: name,
                        code: code,
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(warehouse == null
                                  ? 'Warehouse created successfully!'
                                  : 'Warehouse updated successfully!'),
                              backgroundColor: BrandColors.primary,
                            ),
                          );
                        }
                      } else {
                        final err = ref.read(warehouseFormControllerProvider).error?.toString() ??
                            'Failed to save warehouse. Please check backend connection.';
                        if (dialogCtx.mounted) {
                          setState(() {
                            isSaving = false;
                            dialogError = err;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, WarehouseDto wh) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Warehouse'),
        content: Text('Are you sure you want to delete warehouse "${wh.name}" (${wh.code})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref.read(warehouseFormControllerProvider.notifier).delete(wh.id);
              if (context.mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Warehouse "${wh.name}" deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final err = ref.read(warehouseFormControllerProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete warehouse: $err'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
    final warehousesAsync = ref.watch(warehousesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses & Locations'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showWarehouseDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.refresh(warehousesListProvider),
        child: warehousesAsync.when(
          data: (warehouses) {
            if (warehouses.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: Text('No warehouses configured. Tap + to add one.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                          tooltip: 'Edit Warehouse',
                          onPressed: () => _showWarehouseDialog(context, ref, warehouse: wh),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          tooltip: 'Delete Warehouse',
                          onPressed: () => _confirmDelete(context, ref, wh),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
