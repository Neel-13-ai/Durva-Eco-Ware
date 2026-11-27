import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/inventory/application/controllers/stock_adjustment_controller.dart';
import 'package:durvaeco/features/inventory/application/providers/inventory_providers.dart';
import 'package:durvaeco/features/inventory/data/models/stock_adjustment_request.dart';
import 'package:durvaeco/features/inventory/data/models/stock_balance_dto.dart';
import 'package:durvaeco/features/inventory/presentation/widgets/stock_impact_preview.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/shared/widgets/shimmer_loading.dart';

class _QueuedAdjustment {
  const _QueuedAdjustment({
    required this.request,
    required this.productLabel,
    required this.warehouseLabel,
  });

  final StockAdjustmentRequest request;
  final String productLabel;
  final String warehouseLabel;
}

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  const StockAdjustmentScreen({
    super.key,
    this.initialProductId,
    this.initialWarehouseId,
  });

  final int? initialProductId;
  final int? initialWarehouseId;

  @override
  ConsumerState<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedProductId;
  int? _selectedWarehouseId;
  AdjustmentMode _selectedMode = AdjustmentMode.increase;

  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _notesCtrl;

  final List<_QueuedAdjustment> _batch = [];

  static const _reasonPresets = [
    'Physical Inventory Audit',
    'Damaged / Scrap Write-off',
    'Found Unrecorded Stock',
    'Opening Balance Correction',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
    _selectedWarehouseId = widget.initialWarehouseId;
    _qtyCtrl = TextEditingController(text: '1');
    _costCtrl = TextEditingController(text: '0.0');
    _reasonCtrl = TextEditingController(text: _reasonPresets.first);
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  StockBalanceDto? _findCurrentBalance(List<StockBalanceDto> balances) {
    if (_selectedProductId == null || _selectedWarehouseId == null) return null;
    for (final b in balances) {
      if (b.productId == _selectedProductId &&
          b.warehouseId == _selectedWarehouseId) {
        return b;
      }
    }
    return null;
  }

  StockAdjustmentRequest? _buildValidatedRequest(double? currentOnHand) {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    if (_selectedProductId == null || _selectedWarehouseId == null) return null;

    return StockAdjustmentRequest(
      productId: _selectedProductId!,
      warehouseId: _selectedWarehouseId!,
      mode: _selectedMode,
      quantity: double.tryParse(_qtyCtrl.text.trim()) ?? 0.0,
      reason: _reasonCtrl.text.trim(),
      unitCost: double.tryParse(_costCtrl.text.trim()) ?? 0.0,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      currentOnHand: currentOnHand,
    );
  }

  void _addToBatch({
    required double? currentOnHand,
    required String productLabel,
    required String warehouseLabel,
  }) {
    final req = _buildValidatedRequest(currentOnHand);
    if (req == null) return;

    setState(() {
      _batch.add(_QueuedAdjustment(
        request: req,
        productLabel: productLabel,
        warehouseLabel: warehouseLabel,
      ));
      _selectedProductId = null;
      _qtyCtrl.text = '1';
      _notesCtrl.clear();
    });
    ref.read(stockAdjustmentControllerProvider.notifier).clearError();
  }

  Future<void> _submit(double? currentOnHand) async {
    final notifier = ref.read(stockAdjustmentControllerProvider.notifier);

    if (_batch.isEmpty) {
      final req = _buildValidatedRequest(currentOnHand);
      if (req == null) return;
      final ok = await notifier.submitAdjustment(req);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock adjusted & logged to audit ledger successfully!'),
            backgroundColor: BrandColors.primary,
          ),
        );
        if (GoRouter.maybeOf(context) != null && context.canPop()) {
          context.pop();
        }
      }
      return;
    }

    final requests = _batch.map((item) => item.request).toList();
    final total = requests.length;
    final succeeded = await notifier.submitBatchAdjustments(requests);
    if (!mounted) return;

    if (succeeded == total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$succeeded stock adjustments saved successfully!'),
          backgroundColor: BrandColors.primary,
        ),
      );
      if (GoRouter.maybeOf(context) != null && context.canPop()) {
        context.pop();
      }
    } else if (succeeded > 0) {
      setState(() {
        _batch.removeRange(0, succeeded);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final balancesAsync = ref.watch(stockBalancesListProvider);
    final adjustmentState = ref.watch(stockAdjustmentControllerProvider);

    final balances = balancesAsync.valueOrNull ?? const <StockBalanceDto>[];
    final currentBalance = _findCurrentBalance(balances);
    final currentOnHand = currentBalance?.quantity ?? 0.0;
    final hasSelection =
        _selectedProductId != null && _selectedWarehouseId != null;

    final products = productsAsync.valueOrNull ?? const [];
    final warehouses = warehousesAsync.valueOrNull ?? const [];
    final selectedProduct = products
        .where((p) => p.id == _selectedProductId)
        .firstOrNull;
    final selectedWarehouse = warehouses
        .where((w) => w.id == _selectedWarehouseId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adjust Stock / Audit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (adjustmentState.hasError) ...[
                      Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        margin: const EdgeInsets.only(bottom: Spacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                adjustmentState.error.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          productsAsync.when(
                            data: (items) => DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: items.any((p) => p.id == _selectedProductId)
                                  ? _selectedProductId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Select Product / Material *',
                                border: OutlineInputBorder(),
                              ),
                              items: items
                                  .map((p) => DropdownMenuItem(
                                        value: p.id,
                                        child: Text(
                                          '${p.name} (${p.code})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              validator: (v) =>
                                  (v == null || v <= 0) ? 'Product is required' : null,
                              onChanged: (val) {
                                setState(() {
                                  _selectedProductId = val;
                                  final prod = items.where((p) => p.id == val).firstOrNull;
                                  if (prod != null) {
                                    _costCtrl.text = prod.purchasePrice.toString();
                                  }
                                });
                              },
                            ),
                            loading: () => const ShimmerDropdown(
                              labelText: 'Select Product *',
                            ),
                            error: (_, __) => const Text('Error loading products'),
                          ),
                          const SizedBox(height: Spacing.md),
                          warehousesAsync.when(
                            data: (items) => DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: items.any((w) => w.id == _selectedWarehouseId)
                                  ? _selectedWarehouseId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Select Warehouse *',
                                border: OutlineInputBorder(),
                              ),
                              items: items
                                  .map((w) => DropdownMenuItem(
                                        value: w.id,
                                        child: Text(
                                          w.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              validator: (v) =>
                                  (v == null || v <= 0) ? 'Warehouse is required' : null,
                              onChanged: (val) =>
                                  setState(() => _selectedWarehouseId = val),
                            ),
                            loading: () => const ShimmerDropdown(
                              labelText: 'Select Warehouse *',
                            ),
                            error: (_, __) => const Text('Error loading warehouses'),
                          ),
                          if (hasSelection) ...[
                            const SizedBox(height: Spacing.md),
                            StockImpactPreviewCard(
                              currentOnHand: currentOnHand,
                              mode: _selectedMode,
                              enteredQty: double.tryParse(_qtyCtrl.text.trim()),
                            ),
                          ],
                          const SizedBox(height: Spacing.md),
                          const Text(
                            'Adjustment Mode *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SegmentedButton<AdjustmentMode>(
                            segments: const [
                              ButtonSegment(
                                value: AdjustmentMode.increase,
                                label: Text('+ Add'),
                              ),
                              ButtonSegment(
                                value: AdjustmentMode.decrease,
                                label: Text('- Reduce'),
                              ),
                              ButtonSegment(
                                value: AdjustmentMode.recount,
                                label: Text('Recount'),
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
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
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
                                      if (hasSelection && qty == currentOnHand) {
                                        return 'Matches current stock';
                                      }
                                    } else {
                                      if (qty <= 0) return 'Quantity must be > 0';
                                      if (_selectedMode == AdjustmentMode.decrease &&
                                          hasSelection &&
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
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Avg Unit Cost (₹)',
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    final cost = double.tryParse(v?.trim() ?? '');
                                    if (cost == null || cost < 0) {
                                      return 'Enter valid cost >= 0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.md),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _reasonPresets
                                .map(
                                  (preset) => ActionChip(
                                    label: Text(preset,
                                        style: const TextStyle(fontSize: 11)),
                                    onPressed: () =>
                                        setState(() => _reasonCtrl.text = preset),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: Spacing.sm),
                          TextFormField(
                            controller: _reasonCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reason for Adjustment *',
                              hintText: 'e.g. Physical inventory audit recount',
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
                          OutlinedButton.icon(
                            onPressed: adjustmentState.isLoading
                                ? null
                                : () => _addToBatch(
                                      currentOnHand:
                                          hasSelection ? currentOnHand : null,
                                      productLabel: selectedProduct?.name ??
                                          'Product #$_selectedProductId',
                                      warehouseLabel: selectedWarehouse?.name ??
                                          'Warehouse #$_selectedWarehouseId',
                                    ),
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('Add Line to Audit Batch'),
                          ),
                        ],
                      ),
                    ),
                    if (_batch.isNotEmpty) ...[
                      const SizedBox(height: Spacing.md),
                      Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Queued Audit Lines (${_batch.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: Spacing.sm),
                            ...List.generate(_batch.length, (index) {
                              final item = _batch[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.productLabel,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${item.warehouseLabel} • ${item.request.mode.toApiValue()} ${item.request.quantity}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: adjustmentState.isLoading
                                      ? null
                                      : () => setState(() => _batch.removeAt(index)),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.lg),
                    FilledButton(
                      onPressed: adjustmentState.isLoading
                          ? null
                          : () => _submit(hasSelection ? currentOnHand : null),
                      style: FilledButton.styleFrom(
                        backgroundColor: BrandColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          : Text(
                              _batch.isEmpty
                                  ? 'Save Adjustment'
                                  : 'Submit ${_batch.length} Adjustments',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
