import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/inventory/application/controllers/stock_adjustment_controller.dart';
import 'package:durvaeco/features/inventory/data/models/stock_adjustment_request.dart';
import 'package:durvaeco/features/inventory/data/models/stock_balance_dto.dart';
import 'package:durvaeco/features/inventory/presentation/widgets/stock_impact_preview.dart';

/// Quick row-level bottom sheet for adjusting a specific product + warehouse balance.
class StockAdjustmentBottomSheet extends ConsumerStatefulWidget {
  const StockAdjustmentBottomSheet({
    super.key,
    required this.balance,
  });

  final StockBalanceDto balance;

  static Future<void> show(
    BuildContext context, {
    required StockBalanceDto balance,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StockAdjustmentBottomSheet(balance: balance),
    );
  }

  @override
  ConsumerState<StockAdjustmentBottomSheet> createState() =>
      _StockAdjustmentBottomSheetState();
}

class _StockAdjustmentBottomSheetState
    extends ConsumerState<StockAdjustmentBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  AdjustmentMode _selectedMode = AdjustmentMode.increase;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _costCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
    _reasonCtrl = TextEditingController(text: 'Quick Stock Correction');
    _notesCtrl = TextEditingController();
    _costCtrl = TextEditingController(
      text: widget.balance.averageCost.toString(),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adjustmentState = ref.watch(stockAdjustmentControllerProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final currentOnHand = widget.balance.quantity;
    final productLabel =
        widget.balance.productName ?? 'Product #${widget.balance.productId}';
    final warehouseLabel =
        widget.balance.warehouseName ?? 'Warehouse #${widget.balance.warehouseId}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.md + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: Spacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.tune, color: BrandColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          warehouseLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              StockImpactPreviewCard(
                currentOnHand: currentOnHand,
                mode: _selectedMode,
                enteredQty: double.tryParse(_qtyCtrl.text.trim()),
              ),
              if (adjustmentState.hasError) ...[
                const SizedBox(height: Spacing.sm),
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    adjustmentState.error.toString(),
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: Spacing.md),
              SegmentedButton<AdjustmentMode>(
                segments: const [
                  ButtonSegment(
                    value: AdjustmentMode.increase,
                    label: Text('+ Add', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: AdjustmentMode.decrease,
                    label: Text('- Reduce', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: AdjustmentMode.recount,
                    label: Text('Recount', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_selectedMode},
                onSelectionChanged: (set) =>
                    setState(() => _selectedMode = set.first),
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _selectedMode == AdjustmentMode.recount
                            ? 'Actual Counted Qty *'
                            : 'Quantity *',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final qty = double.tryParse(v?.trim() ?? '');
                        if (qty == null) return 'Enter a valid number';
                        if (_selectedMode == AdjustmentMode.recount) {
                          if (qty < 0) return 'Count cannot be < 0';
                          if (qty == currentOnHand) {
                            return 'Matches current stock';
                          }
                        } else {
                          if (qty <= 0) return 'Quantity must be > 0';
                          if (_selectedMode == AdjustmentMode.decrease &&
                              qty > currentOnHand) {
                            return 'Exceeds stock ($currentOnHand)';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _costCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Avg Unit Cost (₹)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final cost = double.tryParse(v?.trim() ?? '');
                        if (cost == null || cost < 0) {
                          return 'Cost must be >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason for Adjustment *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Reason is required'
                    : null,
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes / Batch Info',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: Spacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: adjustmentState.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: Spacing.sm),
                  FilledButton(
                    onPressed: adjustmentState.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              final req = StockAdjustmentRequest(
                                productId: widget.balance.productId,
                                warehouseId: widget.balance.warehouseId,
                                mode: _selectedMode,
                                quantity:
                                    double.tryParse(_qtyCtrl.text.trim()) ?? 0.0,
                                reason: _reasonCtrl.text.trim(),
                                unitCost:
                                    double.tryParse(_costCtrl.text.trim()) ?? 0.0,
                                notes: _notesCtrl.text.trim().isEmpty
                                    ? null
                                    : _notesCtrl.text.trim(),
                                currentOnHand: currentOnHand,
                              );
                              final ok = await ref
                                  .read(stockAdjustmentControllerProvider
                                      .notifier)
                                  .submitAdjustment(req);
                              if (ok && context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Stock adjusted & logged to audit ledger successfully!'),
                                    backgroundColor: BrandColors.primary,
                                  ),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.primary,
                    ),
                    child: adjustmentState.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save Adjustment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible wrapper delegating row-level adjustments to [StockAdjustmentBottomSheet].
class StockAdjustmentDialog {
  static Future<void> show(
    BuildContext context, {
    int? initialProductId,
    int? initialWarehouseId,
    double initialQuantity = 0.0,
    double initialAverageCost = 0.0,
    String? productName,
    String? warehouseName,
  }) {
    return StockAdjustmentBottomSheet.show(
      context,
      balance: StockBalanceDto(
        id: 0,
        productId: initialProductId ?? 0,
        warehouseId: initialWarehouseId ?? 0,
        quantity: initialQuantity,
        averageCost: initialAverageCost,
        productName: productName,
        warehouseName: warehouseName,
      ),
    );
  }
}
