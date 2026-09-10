import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/master_form_controllers.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/document_sequence_dto.dart';

class SequenceScreen extends ConsumerWidget {
  const SequenceScreen({super.key});

  void _showSequenceDialog(BuildContext context, WidgetRef ref, DocumentSequenceDto seq) {
    final prefixCtrl = TextEditingController(text: seq.prefix);
    final nextNumCtrl = TextEditingController(text: seq.nextNumber.toString());
    final paddingCtrl = TextEditingController(text: seq.padding.toString());
    final suffixCtrl = TextEditingController(text: seq.suffix ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Edit Sequence: ${seq.moduleName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prefixCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prefix * (e.g. PO/, INV/, GRN/)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: nextNumCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Next Number *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: paddingCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Zero Padding Digits (e.g. 4 for 0001)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: suffixCtrl,
                decoration: const InputDecoration(
                  labelText: 'Suffix (Optional, e.g. /24-25)',
                  border: OutlineInputBorder(),
                ),
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
              final dto = seq.copyWith(
                prefix: prefixCtrl.text.trim(),
                nextNumber: int.tryParse(nextNumCtrl.text) ?? seq.nextNumber,
                padding: int.tryParse(paddingCtrl.text) ?? seq.padding,
                suffix: suffixCtrl.text.trim().isEmpty ? null : suffixCtrl.text.trim(),
              );
              final ok = await ref.read(sequenceFormControllerProvider.notifier).save(dto);
              if (ok && dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sequencesAsync = ref.watch(sequencesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Sequences'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(sequencesListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: sequencesAsync.when(
        data: (sequences) {
          if (sequences.isEmpty) {
            return const Center(child: Text('No sequences found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: sequences.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) {
              final seq = sequences[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4E342E).withValues(alpha: 0.1),
                    child: const Icon(Icons.numbers, color: Color(0xFF4E342E), size: 20),
                  ),
                  title: Text(seq.moduleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Sample Code: ${seq.sampleGeneratedCode}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showSequenceDialog(context, ref, seq),
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
