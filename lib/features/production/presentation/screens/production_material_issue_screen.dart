import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/production/data/models/production_material_issue_dto.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';
import 'package:durvaeco/features/production/application/controllers/production_execution_controller.dart';

class ProductionMaterialIssueScreen extends ConsumerStatefulWidget {
  const ProductionMaterialIssueScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ProductionMaterialIssueScreen> createState() =>
      _ProductionMaterialIssueScreenState();
}

class _ProductionMaterialIssueScreenState
    extends ConsumerState<ProductionMaterialIssueScreen> {
  final _batchNoController = TextEditingController(text: 'RM-BATCH-${DateTime.now().millisecondsSinceEpoch % 10000}');
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _batchNoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showIssueDialog(BuildContext context, WidgetRef ref, ProductionMaterialIssueDto mat) {
    final qtyCtrl = TextEditingController(text: (mat.requiredQty - mat.issuedQty).toString());

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Issue Raw Material: ${mat.productName ?? 'Product'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Required: ${NumberFormat('#,##0.##').format(mat.requiredQty)} ${mat.unitName ?? 'units'}', style: const TextStyle(color: Color(0xFF718096), fontSize: 12)),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity to Issue *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _batchNoController,
              decoration: const InputDecoration(
                labelText: 'Material Batch No.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF718096))),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
              if (qty <= 0) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Quantity must be greater than zero.'), backgroundColor: Colors.redAccent),
                  );
                }
                return;
              }

              // Check not exceeding required
              final remaining = mat.requiredQty - mat.issuedQty;
              final issueQty = qty.clamp(0.0, remaining);

              final issue = mat.copyWith(
                issuedQty: mat.issuedQty + issueQty,
                batchNo: _batchNoController.text.trim().isEmpty
                    ? 'RM-BATCH-${DateTime.now().millisecondsSinceEpoch % 10000}'
                    : _batchNoController.text.trim(),
              );

              final ok = await ref.read(productionExecutionControllerProvider.notifier).issueMaterial(issue);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Issued ${NumberFormat('#,##0.##').format(issueQty)} ${mat.unitName ?? "units"} of ${mat.productName}.'),
                    backgroundColor: BrandColors.primary,
                  ),
                );
                ref.invalidate(productionOrderDetailProvider(widget.orderId));
              } else if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Failed to issue materials. Check connectivity.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm Issue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(productionOrderDetailProvider(widget.orderId));
    final materialsAsync = ref.watch(productionMaterialsListProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFF1B4332)),
        title: const Text('Issue Materials', style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
            onPressed: () {
              ref.invalidate(productionOrderDetailProvider(widget.orderId));
              ref.invalidate(productionMaterialsListProvider(widget.orderId));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: orderAsync.when(
          data: (order) {
            if (order == null) {
              return const Center(child: Text('Production order not found.'));
            }

            return Column(
              children: [
                // Header Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
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
                        child: const Icon(Icons.precision_manufacturing, color: Color(0xFF2E7D32), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.productionNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A202C))),
                            const SizedBox(height: 4),
                            Text(
                              order.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: order.status == ProductionStatus.inProgress
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFFE65100)),
                            SizedBox(width: 6),
                            Text('Material Issue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Materials List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Raw Materials Required', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A202C))),
                      TextButton.icon(
                        onPressed: () {
                          ref.invalidate(productionMaterialsListProvider(widget.orderId));
                        },
                        icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF2E7D32)),
                        label: const Text('Refresh', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Materials List
                Expanded(
                  child: materialsAsync.when(
                    data: (materials) {
                      if (materials.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No raw materials required for this order.', style: TextStyle(color: Color(0xFF718096), fontSize: 13)),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: const Text('Go Back', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          final mat = materials[index];
                          final isPending = mat.issuedQty < mat.requiredQty || (mat.requiredQty == 0 && mat.issuedQty == 0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isPending ? Colors.white : const Color(0xFFF0FFF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPending ? const Color(0xFFE2E8F0) : const Color(0xFFB7E4C7),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isPending ? Icons.inventory_2_outlined : Icons.check_circle_outline,
                                  color: isPending ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                mat.productName ?? 'Product #${mat.productId}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text('${mat.unitName ?? 'unit'} | Batch: ${mat.batchNo ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Required: ${NumberFormat('#,##0.##').format(mat.requiredQty)}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isPending ? const Color(0xFFFFE0B2) : const Color(0xFFA5D6A7),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Issued: ${NumberFormat('#,##0.##').format(mat.issuedQty)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isPending ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isPending
                                  ? IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.add_circle_outline, color: Color(0xFFE65100), size: 20),
                                      ),
                                      onPressed: () => _showIssueDialog(context, ref, mat),
                                    )
                                  : const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                          const SizedBox(height: 8),
                          Text('Failed to load materials: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              ref.invalidate(productionMaterialsListProvider(widget.orderId));
                            },
                            child: const Text('Retry', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
          error: (err, _) => Center(child: Text('Failed to load order: $err', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }
}
