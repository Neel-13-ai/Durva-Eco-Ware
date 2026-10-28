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
    bool isActive = unit?.isActive ?? true;
    String? nameError;
    String? symbolError;
    String? dialogError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(unit == null ? 'Add Unit' : 'Edit Unit'),
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
                    labelText: 'Unit Name *',
                    hintText: 'e.g. Kilogram, Piece, Bundle',
                    border: const OutlineInputBorder(),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) setState(() => nameError = null);
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: symbolCtrl,
                  decoration: InputDecoration(
                    labelText: 'Symbol *',
                    hintText: 'e.g. Kg, Pcs, Bdl',
                    border: const OutlineInputBorder(),
                    errorText: symbolError,
                  ),
                  onChanged: (_) {
                    if (symbolError != null) setState(() => symbolError = null);
                  },
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
            Consumer(
              builder: (ctx, cRef, _) {
                final saving = cRef.watch(unitFormControllerProvider).isLoading;
                return ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final symbol = symbolCtrl.text.trim();
                          bool hasError = false;

                          if (name.isEmpty) {
                            setState(() => nameError = 'Unit name is required');
                            hasError = true;
                          }
                          if (symbol.isEmpty) {
                            setState(() => symbolError = 'Symbol is required');
                            hasError = true;
                          }
                          if (hasError) return;

                          setState(() => dialogError = null);

                          final dto = UnitDto(
                            id: unit?.id ?? 0,
                            name: name,
                            symbol: symbol,
                            isActive: isActive,
                          );

                          final ok = await cRef
                              .read(unitFormControllerProvider.notifier)
                              .save(dto, isEditing: unit != null);

                          if (!ctx.mounted) return;
                          if (ok) {
                            Navigator.of(dialogCtx).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(unit == null
                                      ? 'Unit created successfully!'
                                      : 'Unit updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            final err = cRef.read(unitFormControllerProvider).error;
                            setState(() {
                              dialogError = err?.toString() ?? 'Failed to save unit';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, UnitDto unit) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to delete unit "${unit.name}" (${unit.symbol})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref.read(unitFormControllerProvider.notifier).delete(unit.id);
              if (context.mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unit "${unit.name}" deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final err = ref.read(unitFormControllerProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete unit: $err'),
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
    final unitsAsync = ref.watch(unitsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Units of Measure'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showUnitDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.refresh(unitsListProvider),
        child: unitsAsync.when(
          data: (units) {
            if (units.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: Text('No units found. Tap + to create one.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                          tooltip: 'Edit Unit',
                          onPressed: () => _showUnitDialog(context, ref, unit: u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          tooltip: 'Delete Unit',
                          onPressed: () => _confirmDelete(context, ref, u),
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
