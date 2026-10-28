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
    String? nameError;
    String? dialogError;
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(method == null ? 'Add Payment Method' : 'Edit Payment Method'),
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
                    labelText: 'Method Name * (e.g. Bank Transfer, UPI, Cash, Cheque)',
                    border: const OutlineInputBorder(),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) setState(() => nameError = null);
                  },
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
              onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        setState(() => nameError = 'Payment method name is required');
                        return;
                      }

                      setState(() {
                        isSaving = true;
                        dialogError = null;
                      });

                      final dto = PaymentMethodDto(
                        id: method?.id ?? 0,
                        methodName: name,
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        isActive: isActive,
                      );

                      final ok = await ref
                          .read(paymentMethodFormControllerProvider.notifier)
                          .save(dto, isEditing: method != null);

                      if (ok && dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(method == null
                                  ? 'Payment method added successfully!'
                                  : 'Payment method updated successfully!'),
                              backgroundColor: BrandColors.primary,
                            ),
                          );
                        }
                      } else {
                        final err = ref.read(paymentMethodFormControllerProvider).error?.toString() ??
                            'Failed to save payment method. Please check backend connection.';
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

  void _confirmDelete(BuildContext context, WidgetRef ref, PaymentMethodDto method) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete payment method "${method.methodName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref.read(paymentMethodFormControllerProvider.notifier).delete(method.id);
              if (context.mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment method "${method.methodName}" deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final err = ref.read(paymentMethodFormControllerProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete payment method: $err'),
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
    final methodsAsync = ref.watch(paymentMethodsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods Master'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showMethodDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.invalidate(paymentMethodsListProvider),
        child: methodsAsync.when(
          data: (methods) {
            if (methods.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: Text('No payment methods configured. Tap + to create one.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                          tooltip: 'Edit Payment Method',
                          onPressed: () => _showMethodDialog(context, ref, method: m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          tooltip: 'Delete Payment Method',
                          onPressed: () => _confirmDelete(context, ref, m),
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
