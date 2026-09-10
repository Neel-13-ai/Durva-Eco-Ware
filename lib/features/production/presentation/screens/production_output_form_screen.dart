import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/production/data/models/production_output_dto.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';
import 'package:durvaeco/features/production/application/controllers/production_execution_controller.dart';

class ProductionOutputFormScreen extends ConsumerStatefulWidget {
  const ProductionOutputFormScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ProductionOutputFormScreen> createState() =>
      _ProductionOutputFormScreenState();
}

class _ProductionOutputFormScreenState extends ConsumerState<ProductionOutputFormScreen> {
  final _producedQtyCtrl = TextEditingController(text: '1000');
  final _goodQtyCtrl = TextEditingController(text: '950');
  final _rejectQtyCtrl = TextEditingController(text: '50');
  final _batchNoCtrl = TextEditingController(text: 'FG-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}');
  final _unitCostCtrl = TextEditingController(text: '3.50');

  @override
  void dispose() {
    _producedQtyCtrl.dispose();
    _goodQtyCtrl.dispose();
    _rejectQtyCtrl.dispose();
    _batchNoCtrl.dispose();
    _unitCostCtrl.dispose();
    super.dispose();
  }

  bool get _isBalanced {
    final produced = double.tryParse(_producedQtyCtrl.text) ?? 0.0;
    final good = double.tryParse(_goodQtyCtrl.text) ?? 0.0;
    final reject = double.tryParse(_rejectQtyCtrl.text) ?? 0.0;
    return good + reject == produced;
  }

  String get _balanceMessage {
    final produced = double.tryParse(_producedQtyCtrl.text) ?? 0.0;
    final good = double.tryParse(_goodQtyCtrl.text) ?? 0.0;
    final reject = double.tryParse(_rejectQtyCtrl.text) ?? 0.0;
    final diff = produced - (good + reject);
    if (diff.abs() < 0.001) return '';
    return diff > 0 ? 'Good + Reject is ${diff.toStringAsFixed(2)} less than Produced' : 'Good + Reject is ${diff.abs().toStringAsFixed(2)} more than Produced';
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(productionOrderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFF1B4332)),
        title: const Text('Record Output', style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
            onPressed: () => ref.invalidate(productionOrderDetailProvider(widget.orderId)),
          ),
        ],
      ),
      body: SafeArea(
        child: orderAsync.when(
          data: (order) {
            if (order == null) {
              return const Center(child: Text('Production order not found.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fact_check, color: Color(0xFF2E7D32), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.productionNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A202C))),
                              const SizedBox(height: 4),
                              Text(order.finishedProductName ?? 'Finished Product',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF2D3748))),
                              if (order.finishedProductCode != null)
                                Text(order.finishedProductCode!,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.eco, size: 16, color: Color(0xFF2E7D32)),
                              SizedBox(width: 6),
                              Text('Production Output', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Output Form Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Row(
                          children: [
                            Icon(Icons.format_list_numbered, size: 18, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text('Finished Goods Output', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A202C))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFEDF2F7)),
                        const SizedBox(height: 12),

                        // Produced Qty
                        TextField(
                          controller: _producedQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Total Produced Quantity *',
                            hintText: 'e.g., 1000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
                            suffixIcon: Icon(Icons.format_list_bulleted, size: 16, color: Color(0xFF718096)),
                            filled: true,
                            fillColor: Color(0xFFFAFBFC),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Good Qty
                        TextField(
                          controller: _goodQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Good Quantity (Accepted) *',
                            hintText: 'e.g., 950',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF2E7D32)),
                            filled: true,
                            fillColor: Color(0xFFFAFBFC),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Reject Qty
                        TextField(
                          controller: _rejectQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Rejected / Scrap Quantity *',
                            hintText: 'e.g., 50',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.remove_circle_outline, size: 18, color: Color(0xFFE53935)),
                            filled: true,
                            fillColor: Color(0xFFFAFBFC),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),

                        // Balance Check
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isBalanced ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _isBalanced ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isBalanced ? Icons.check_circle : Icons.warning_amber,
                                size: 18,
                                color: _isBalanced ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBalanced ? 'Balanced: Good + Reject = Produced' : _balanceMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _isBalanced ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Divider(color: Color(0xFFEDF2F7)),
                        const SizedBox(height: 12),

                        // Batch No
                        TextField(
                          controller: _batchNoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Batch Number *',
                            hintText: 'e.g., FG-2026-001',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label_outline, size: 18),
                            filled: true,
                            fillColor: Color(0xFFFAFBFC),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Unit Cost
                        TextField(
                          controller: _unitCostCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Unit Cost (₹) *',
                            hintText: 'e.g., 3.50',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money, size: 18, color: Color(0xFF1565C0)),
                            suffixIcon: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('INR', style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
                            ),
                            filled: true,
                            fillColor: Color(0xFFFAFBFC),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Output Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF718096)),
                          title: Text(
                            DateFormat('dd MMM yyyy').format(DateTime.now()),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF2D3748)),
                          ),
                          subtitle: const Text('Output date',
                            style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
                        ),
                        const SizedBox(height: 4),

                        const Divider(color: Color(0xFFEDF2F7)),
                        const SizedBox(height: 12),

                        // Cost Summary
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFB7E4C7)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Output Value', style: TextStyle(fontSize: 12, color: Color(0xFF718096))),
                                  Text(
                                    '₹${((double.tryParse(_unitCostCtrl.text) ?? 0.0) * (double.tryParse(_producedQtyCtrl.text) ?? 0.0)).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Good Units: ${(double.tryParse(_goodQtyCtrl.text) ?? 0.0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                                  Text('Reject: ${(double.tryParse(_rejectQtyCtrl.text) ?? 0.0).toStringAsFixed(0)} (${((double.tryParse(_rejectQtyCtrl.text) ?? 0.0) / ((double.tryParse(_producedQtyCtrl.text) ?? 1.0)) * 100).toStringAsFixed(1)}%)',
                                    style: TextStyle(fontSize: 11, color: (double.tryParse(_rejectQtyCtrl.text) ?? 0.0) > 0 ? const Color(0xFFE65100) : const Color(0xFF718096))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBalanced
                          ? () async {
                              final produced = double.tryParse(_producedQtyCtrl.text) ?? 0.0;
                              final good = double.tryParse(_goodQtyCtrl.text) ?? 0.0;
                              final reject = double.tryParse(_rejectQtyCtrl.text) ?? 0.0;
                              final unitCost = double.tryParse(_unitCostCtrl.text) ?? 0.0;
                              final batchNo = _batchNoCtrl.text.trim();

                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);

                              if (produced <= 0 || good <= 0 || batchNo.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Please fill all required fields correctly.'), backgroundColor: Colors.redAccent),
                                );
                                return;
                              }

                              final output = ProductionOutputDto(
                                id: 0,
                                productionOrderId: widget.orderId,
                                productId: order.finishedProductId,
                                producedQty: produced,
                                goodQty: good,
                                rejectQty: reject,
                                batchNo: batchNo,
                                unitCost: unitCost,
                                outputDate: DateTime.now(),
                              );

                              final ok = await ref.read(productionExecutionControllerProvider.notifier).recordOutput(output);
                              if (ok && mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Output recorded! ${good.toStringAsFixed(0)} good units added to FG stock.'),
                                      ],
                                    ),
                                    backgroundColor: BrandColors.primary,
                                  ),
                                );
                                ref.invalidate(productionOrderDetailProvider(widget.orderId));
                                router.pop();
                              } else if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Failed to record output. Check connectivity.'), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 18),
                            SizedBox(width: 8),
                            Text('Confirm Output', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
          error: (err, _) => Center(child: Text('Failed to load order: $err', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }
}
