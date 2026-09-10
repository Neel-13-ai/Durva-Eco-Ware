import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/waste/data/models/waste_reason_dto.dart';
import 'package:durvaeco/features/waste/application/providers/waste_providers.dart';

class WasteReasonScreen extends ConsumerStatefulWidget {
  const WasteReasonScreen({super.key});

  @override
  ConsumerState<WasteReasonScreen> createState() => _WasteReasonScreenState();
}

class _WasteReasonScreenState extends ConsumerState<WasteReasonScreen> {
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Waste / Scrap Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Reason Name *', hintText: 'e.g. Mold Overheat Scorching', border: OutlineInputBorder()),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Reason'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeWasteReasonsProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _showAddDialog,
        backgroundColor: BrandColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: reasonsAsync.when(
        data: (reasons) {
          if (reasons.isEmpty) {
            return const Center(child: Text('No waste reasons defined'));
          }

          return ListView.separated(
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
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                    child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
