import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/waste/application/providers/waste_providers.dart';
import 'package:durvaeco/features/waste/data/models/waste_reason_dto.dart';

class WasteReasonScreen extends ConsumerStatefulWidget {
  const WasteReasonScreen({super.key});

  @override
  ConsumerState<WasteReasonScreen> createState() => _WasteReasonScreenState();
}

class _WasteReasonScreenState extends ConsumerState<WasteReasonScreen> {
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? nameError;
    String? errorMsg;
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Waste / Scrap Reason'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(errorMsg!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reason Name *',
                    hintText: 'e.g. Mold Overheat Scorching',
                    border: const OutlineInputBorder(),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) setDialogState(() => nameError = null);
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => nameError = 'Reason name is required');
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          errorMsg = null;
                        });

                        final reason = WasteReasonDto(
                          id: 0,
                          reasonName: name,
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        );

                        final repo = ref.read(wasteRepositoryProvider);
                        final result = await repo.createReason(reason);
                        if (result.isSuccess && ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ref.invalidate(activeWasteReasonsProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Waste reason added successfully!'), backgroundColor: BrandColors.primary),
                            );
                          }
                        } else {
                          final err = result.failureOrNull?.message ?? 'Failed to save waste reason';
                          if (ctx.mounted) {
                            setDialogState(() {
                              isSaving = false;
                              errorMsg = err;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Reason'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(WasteReasonDto reason) {
    final nameCtrl = TextEditingController(text: reason.reasonName);
    final descCtrl = TextEditingController(text: reason.description ?? '');
    String? nameError;
    String? errorMsg;
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Waste / Scrap Reason'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(errorMsg!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reason Name *',
                    border: const OutlineInputBorder(),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) setDialogState(() => nameError = null);
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => nameError = 'Reason name is required');
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          errorMsg = null;
                        });

                        final updated = WasteReasonDto(
                          id: reason.id,
                          reasonName: name,
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          isActive: reason.isActive,
                        );

                        final repo = ref.read(wasteRepositoryProvider);
                        final result = await repo.updateReason(reason.id, updated);
                        if (result.isSuccess && ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ref.invalidate(activeWasteReasonsProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Waste reason updated successfully!'), backgroundColor: BrandColors.primary),
                            );
                          }
                        } else {
                          final err = result.failureOrNull?.message ?? 'Failed to update waste reason';
                          if (ctx.mounted) {
                            setDialogState(() {
                              isSaving = false;
                              errorMsg = err;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(WasteReasonDto reason) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Waste Reason?'),
        content: Text('Reason "${reason.reasonName}" will be deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Deleting waste reason...')),
              );
              final repo = ref.read(wasteRepositoryProvider);
              final result = await repo.deleteReason(reason.id);
              result.when(
                success: (_) {
                  ref.invalidate(activeWasteReasonsProvider);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Waste reason deleted successfully!'), backgroundColor: BrandColors.primary),
                  );
                },
                failure: (err) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete: ${err.message}'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final reasonsAsync = ref.watch(activeWasteReasonsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste & Scrap Reasons'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _showAddDialog,
        backgroundColor: BrandColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.invalidate(activeWasteReasonsProvider),
        child: reasonsAsync.when(
          data: (reasons) {
            if (reasons.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: Text('No waste reasons defined')),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: reasons.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (ctx, index) {
                final reason = reasons[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0),
                      foregroundColor: Color(0xFFE65100),
                      child: Icon(Icons.warning_amber_rounded, size: 20),
                    ),
                    title: Text(reason.reasonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: reason.description != null ? Text(reason.description!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: BrandColors.primary),
                          tooltip: 'Edit',
                          onPressed: () => _showEditDialog(reason),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _showDeleteDialog(reason),
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
