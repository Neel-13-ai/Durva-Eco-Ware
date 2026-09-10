import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/controllers/partner_controllers.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/payment_method_dto.dart';

class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({super.key});

  void _showMethodDialog(BuildContext context, WidgetRef ref, {PaymentMethodDto? method}) {
    final nameCtrl = TextEditingController(text: method?.methodName ?? '');
    final descCtrl = TextEditingController(text: method?.description ?? '');
    bool isActive = method?.isActive ?? true;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(method == null ? 'Add Payment Method' : 'Edit Payment Method'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Method Name * (e.g. Bank Transfer, UPI, Cash, Cheque)', border: OutlineInputBorder()),
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
                if (nameCtrl.text.trim().isEmpty) return;
                final dto = PaymentMethodDto(
                  id: method?.id ?? 0,
                  methodName: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  isActive: isActive,
                );
                final ok = await ref
                    .read(paymentMethodFormControllerProvider.notifier)
                    .save(dto, isEditing: method != null);
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
    final methodsAsync = ref.watch(paymentMethodsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods Master'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(paymentMethodsListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showMethodDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return const Center(child: Text('No payment methods configured. Tap + to create one.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: methods.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) {
              final m = methods[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: BrandColors.secondary.withValues(alpha: 0.1),
                    child: const Icon(Icons.payments_outlined, color: BrandColors.secondary, size: 20),
                  ),
                  title: Text(m.methodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(m.description ?? (m.isActive ? 'Active' : 'Inactive')),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showMethodDialog(context, ref, method: m),
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
