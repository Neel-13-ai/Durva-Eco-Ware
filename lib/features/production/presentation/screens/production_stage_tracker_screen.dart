import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/production/data/models/production_material_issue_dto.dart';
import 'package:durvaeco/features/production/data/models/production_output_dto.dart';
import 'package:durvaeco/features/production/data/models/quality_check_dto.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';
import 'package:durvaeco/features/production/application/controllers/production_execution_controller.dart';

class ProductionStageTrackerScreen extends ConsumerWidget {
  const ProductionStageTrackerScreen({super.key, required this.orderId});

  final int orderId;

  void _showIssueDialog(BuildContext context, WidgetRef ref, ProductionMaterialIssueDto mat) {
    final qtyCtrl = TextEditingController(text: (mat.requiredQty - mat.issuedQty).toString());
    final batchCtrl = TextEditingController(text: 'RM-BATCH-${DateTime.now().millisecondsSinceEpoch % 10000}');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Issue Raw Material: ${mat.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity to Issue *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: batchCtrl,
              decoration: const InputDecoration(labelText: 'Material Batch No.', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
              if (qty <= 0) return;

              final issue = mat.copyWith(
                issuedQty: mat.issuedQty + qty,
                batchNo: batchCtrl.text.trim(),
              );

              final ok = await ref.read(productionExecutionControllerProvider.notifier).issueMaterial(issue);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Materials issued from warehouse to floor!'), backgroundColor: BrandColors.primary),
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

  void _showQcDialog(BuildContext context, WidgetRef ref, ProductionOrderDto order) {
    final sampleCtrl = TextEditingController(text: '50');
    final passedCtrl = TextEditingController(text: '49');
    final remarksCtrl = TextEditingController(text: 'Visual inspection & drop test passed.');
    QualityResult result = QualityResult.pass;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: const Text('Record Quality Inspection (QC)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sampleCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Sample Qty *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: TextField(
                        controller: passedCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Passed Qty *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                DropdownButtonFormField<QualityResult>(
                  initialValue: result,
                  decoration: const InputDecoration(labelText: 'Inspection Verdict *', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: QualityResult.pass, child: Text('PASS (Approved for Output)')),
                    DropdownMenuItem(value: QualityResult.rework, child: Text('REWORK (Requires Correction)')),
                    DropdownMenuItem(value: QualityResult.fail, child: Text('FAIL (Reject to Waste)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => result = val);
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(labelText: 'Inspector Remarks', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final sample = double.tryParse(sampleCtrl.text) ?? 0.0;
                final passed = double.tryParse(passedCtrl.text) ?? 0.0;
                final failed = sample - passed;

                final qc = QualityCheckDto(
                  id: 0,
                  productionOrderId: order.id,
                  productId: order.finishedProductId,
                  productName: order.finishedProductName,
                  batchNo: 'FG-BATCH-${order.id}',
                  sampleQty: sample,
                  passedQty: passed,
                  failedQty: failed > 0 ? failed : 0.0,
                  result: result,
                  checkedBy: 'QC Lead Incharge',
                  checkDate: DateTime.now(),
                  remarks: remarksCtrl.text.trim(),
                );

                final ok = await ref.read(productionExecutionControllerProvider.notifier).recordQC(qc);
                if (ok && ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quality Check recorded!'), backgroundColor: BrandColors.primary),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
              child: const Text('Save QC'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOutputDialog(BuildContext context, WidgetRef ref, ProductionOrderDto order) {
    final goodCtrl = TextEditingController(text: order.plannedQty.toStringAsFixed(0));
    final rejectCtrl = TextEditingController(text: '0');
    final batchCtrl = TextEditingController(text: 'FG-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${order.id}');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Finished Goods Output'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: batchCtrl,
              decoration: const InputDecoration(labelText: 'Finished Goods Batch No. *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: goodCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Good Qty *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: TextField(
                    controller: rejectCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Reject Qty', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final good = double.tryParse(goodCtrl.text) ?? 0.0;
              final reject = double.tryParse(rejectCtrl.text) ?? 0.0;
              final total = good + reject;

              final output = ProductionOutputDto(
                id: 0,
                productionOrderId: order.id,
                productId: order.finishedProductId,
                productName: order.finishedProductName,
                producedQty: total,
                goodQty: good,
                rejectQty: reject,
                batchNo: batchCtrl.text.trim(),
                outputDate: DateTime.now(),
              );

              final ok = await ref.read(productionExecutionControllerProvider.notifier).recordOutput(output);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Finished goods output verified and inwarded to warehouse stock!'), backgroundColor: BrandColors.primary),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm Inward'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(productionOrderDetailProvider(orderId));
    final executionState = ref.watch(productionExecutionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manufacturing Floor Tracker'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productionOrderDetailProvider(orderId)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Production order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.productionNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BrandColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Text(
                              order.status.name.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: BrandColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.finishedProductName ?? 'Finished Good #${order.finishedProductId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${order.plannedQty.toStringAsFixed(0)} • Actual Good Output: ${order.totalGoodOutput.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          if (order.status == ProductionStatus.planned)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: executionState.isLoading
                                    ? null
                                    : () => ref.read(productionExecutionControllerProvider.notifier).startProduction(order.id),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Production'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                              ),
                            ),
                          if (order.status == ProductionStatus.inProgress) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showQcDialog(context, ref, order),
                                icon: const Icon(Icons.verified_outlined),
                                label: const Text('Quality Inspection'),
                                style: OutlinedButton.styleFrom(foregroundColor: BrandColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showOutputDialog(context, ref, order),
                                icon: const Icon(Icons.inventory_2),
                                label: const Text('Record Output'),
                                style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
                              ),
                            ),
                          ],
                          if (order.status == ProductionStatus.inProgress && order.totalGoodOutput > 0) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                              tooltip: 'Complete Production Order',
                              onPressed: () => ref.read(productionExecutionControllerProvider.notifier).completeProduction(order.id),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // Material Issues Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Material Requisitions (${order.materials.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    if (order.isMaterialsFullyIssued)
                      const Text('All Materials Issued ✅', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: Spacing.sm),

                ...order.materials.map((m) => Card(
                      margin: const EdgeInsets.only(bottom: Spacing.sm),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        title: Text(m.productName ?? 'Material #${m.productId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Required: ${m.requiredQty.toStringAsFixed(1)} • Issued: ${m.issuedQty.toStringAsFixed(1)} ${m.unitName ?? "Units"}'),
                        trailing: m.isFullyIssued
                            ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22)
                            : OutlinedButton(
                                onPressed: () => _showIssueDialog(context, ref, m),
                                style: OutlinedButton.styleFrom(foregroundColor: BrandColors.primary),
                                child: const Text('Issue'),
                              ),
                      ),
                    )),
                const SizedBox(height: Spacing.md),

                // Multi-Stage Sequential Tracker
                Text(
                  'Multi-Stage Manufacturing Flow (${order.stages.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: Spacing.sm),

                if (order.stages.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text('Default manufacturing sequence initialized on floor launch.', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  )
                else
                  ...order.stages.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stage = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: Spacing.sm),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        side: BorderSide(
                          color: stage.isCompleted ? const Color(0xFF2E7D32) : (stage.isInProgress ? const Color(0xFF1565C0) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: stage.isCompleted
                              ? const Color(0xFF2E7D32)
                              : (stage.isInProgress ? const Color(0xFF1565C0) : const Color(0xFFE2E8F0)),
                          foregroundColor: stage.isPending ? const Color(0xFF64748B) : Colors.white,
                          child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(stage.stageName ?? 'Stage #${stage.stageId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          stage.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stage.isCompleted ? const Color(0xFF2E7D32) : (stage.isInProgress ? const Color(0xFF1565C0) : const Color(0xFF64748B)),
                          ),
                        ),
                        trailing: stage.isPending
                            ? OutlinedButton(
                                onPressed: () => ref.read(productionExecutionControllerProvider.notifier).startStage(stage),
                                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1565C0)),
                                child: const Text('Start'),
                              )
                            : (stage.isInProgress
                                ? ElevatedButton(
                                    onPressed: () => ref.read(productionExecutionControllerProvider.notifier).completeStage(stage),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                                    child: const Text('Complete'),
                                  )
                                : const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22)),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
