import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/purchasing/application/controllers/grn_form_controller.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';

class GoodsReceiptFormScreen extends ConsumerStatefulWidget {
  const GoodsReceiptFormScreen({super.key, required this.purchaseId});

  final int purchaseId;

  @override
  ConsumerState<GoodsReceiptFormScreen> createState() => _GoodsReceiptFormScreenState();
}

class _GoodsReceiptFormScreenState extends ConsumerState<GoodsReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _challanCtrl;
  late TextEditingController _vehicleCtrl;
  late TextEditingController _receivedByCtrl;

  @override
  void initState() {
    super.initState();
    _challanCtrl = TextEditingController();
    _vehicleCtrl = TextEditingController();
    _receivedByCtrl = TextEditingController();

    Future.microtask(() async {
      try {
        final po = await ref.read(purchaseDetailProvider(widget.purchaseId).future);
        if (!mounted) return;
        ref.read(grnFormControllerProvider.notifier).initializeFromPurchase(po);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _challanCtrl.dispose();
    _vehicleCtrl.dispose();
    _receivedByCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grnState = ref.watch(grnFormControllerProvider);
    final grnNotifier = ref.read(grnFormControllerProvider.notifier);
    final products = ref.watch(productsListProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm GRN'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: grnState.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        grnNotifier.setChallanNumber(_challanCtrl.text.trim());
                        grnNotifier.setVehicleNumber(_vehicleCtrl.text.trim());
                        grnNotifier.setReceivedBy(_receivedByCtrl.text.trim());

                        final ok = await grnNotifier.submit();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('GRN Confirmed & Stock Balance Updated!'),
                              backgroundColor: BrandColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          context.pop();
                        } else if (!ok && context.mounted) {
                          final errMsg = grnState.failure?.message ?? 'Failed to confirm GRN. Please check quantities.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errMsg),
                              backgroundColor: SemanticColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
              ),
              child: grnState.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('CONFIRM & INWARD STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _challanCtrl,
                      decoration: const InputDecoration(labelText: 'Delivery Challan / Invoice No. *', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Challan number is required' : null,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _vehicleCtrl,
                            decoration: const InputDecoration(labelText: 'Vehicle No.', hintText: 'MP09AB1234', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _receivedByCtrl,
                            decoration: const InputDecoration(labelText: 'Received By', hintText: 'Store Incharge', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              const Text('Inward Inspection Quantities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: Spacing.sm),

              if (grnState.items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No pending items to inward for this purchase order.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                )
              else
                ...grnState.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: Spacing.sm),
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
                        Text(
                          item.productName ?? products?.where((p) => p.id == item.productId).firstOrNull?.name ?? 'Item #${item.productId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text('Ordered Qty: ${item.orderedQuantity} ${item.unitName ?? "Units"}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: item.receivedQuantity.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Received Qty *', border: OutlineInputBorder()),
                                onChanged: (v) => grnNotifier.updateLineQty(idx, received: double.tryParse(v)),
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: TextFormField(
                                initialValue: item.rejectedQuantity.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Rejected Qty', border: OutlineInputBorder()),
                                onChanged: (v) => grnNotifier.updateLineQty(idx, rejected: double.tryParse(v)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
