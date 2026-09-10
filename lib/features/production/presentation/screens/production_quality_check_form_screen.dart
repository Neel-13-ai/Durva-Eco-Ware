import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/production/data/models/quality_check_dto.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';

class ProductionQualityCheckScreen extends ConsumerStatefulWidget {
  const ProductionQualityCheckScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ProductionQualityCheckScreen> createState() =>
      _ProductionQualityCheckScreenState();
}

class _ProductionQualityCheckScreenState extends ConsumerState<ProductionQualityCheckScreen> {
  final _sampleQtyCtrl = TextEditingController(text: '50');
  final _passedQtyCtrl = TextEditingController(text: '48');
  final _failedQtyCtrl = TextEditingController(text: '2');
  final _remarksCtrl = TextEditingController(text: 'Visual inspection & dimensional check passed.');
  QualityResult _selectedResult = QualityResult.pass;

  @override
  void dispose() {
    _sampleQtyCtrl.dispose();
    _passedQtyCtrl.dispose();
    _failedQtyCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  bool get _isBalanced {
    final sample = double.tryParse(_sampleQtyCtrl.text) ?? 0.0;
    final passed = double.tryParse(_passedQtyCtrl.text) ?? 0.0;
    final failed = double.tryParse(_failedQtyCtrl.text) ?? 0.0;
    return passed + failed == sample;
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(productionOrderDetailProvider(widget.orderId));
    final qcListAsync = ref.watch(qualityChecksListProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFF1B4332)),
        title: const Text('Quality Control (QC)', style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
            onPressed: () {
              ref.invalidate(productionOrderDetailProvider(widget.orderId));
              ref.invalidate(qualityChecksListProvider(widget.orderId));
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

            return RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: () async {
                ref.invalidate(productionOrderDetailProvider(widget.orderId));
                ref.invalidate(qualityChecksListProvider(widget.orderId));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            child: const Icon(Icons.verified_user, color: Color(0xFF2E7D32), size: 24),
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
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.science, size: 16, color: Color(0xFF1976D2)),
                                SizedBox(width: 6),
                                Text('QC Inspection', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1976D2))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Existing QC Checks
                    const Text('Inspection History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A202C))),
                    const SizedBox(height: 8),

                    qcListAsync.when(
                      data: (qcList) {
                        if (qcList.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.history, size: 32, color: Color(0xFFCBD5E0)),
                                SizedBox(width: 12),
                                Text('No QC inspections recorded yet.', style: TextStyle(color: Color(0xFF718096), fontSize: 13)),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: qcList.map((qc) {
                            final isLatest = qcList.indexOf(qc) == 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: qc.isPassed ? const Color(0xFFF0FFF4) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: qc.isPassed ? const Color(0xFFB7E4C7) : const Color(0xFFEF9A9A),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: qc.isPassed ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : const Color(0xFFE53935).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      qc.isPassed ? Icons.check_circle : Icons.cancel,
                                      color: qc.isPassed ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          qc.result.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: qc.isPassed ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Sample: ${NumberFormat('#,##0').format(qc.sampleQty)} | Passed: ${NumberFormat('#,##0').format(qc.passedQty)} | Failed: ${NumberFormat('#,##0').format(qc.failedQty)}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Batch: ${qc.batchNo}',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isLatest)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Latest', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
                      error: (err, _) => Text('Failed to load QC history: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEDF2F7), height: 1),
                    const SizedBox(height: 16),

                    // New QC Form
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
                          const Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF2E7D32)),
                              SizedBox(width: 8),
                              Text('New Inspection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A202C))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEDF2F7)),
                          const SizedBox(height: 12),

                          // Sample Qty
                          TextField(
                            controller: _sampleQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Sample Quantity Inspected *',
                              hintText: 'e.g., 50',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.analytics_outlined, size: 18),
                              filled: true,
                              fillColor: Color(0xFFFAFBFC),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),

                          // Passed Qty
                          TextField(
                            controller: _passedQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Passed Quantity *',
                              hintText: 'e.g., 48',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF2E7D32)),
                              filled: true,
                              fillColor: Color(0xFFFAFBFC),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),

                          // Failed Qty
                          TextField(
                            controller: _failedQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Failed / Rejected Quantity *',
                              hintText: 'e.g., 2',
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
                                  _isBalanced ? 'Balanced: Passed + Failed = Sample' : 'Passed + Failed does not equal Sample',
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

                          // Result Selection
                          const Text('QC Result *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ResultChip(
                                label: 'PASS',
                                isSelected: _selectedResult == QualityResult.pass,
                                color: const Color(0xFF2E7D32),
                                onTap: () => setState(() => _selectedResult = QualityResult.pass),
                              ),
                              const SizedBox(width: 8),
                              _ResultChip(
                                label: 'FAIL',
                                isSelected: _selectedResult == QualityResult.fail,
                                color: const Color(0xFFE53935),
                                onTap: () => setState(() => _selectedResult = QualityResult.fail),
                              ),
                              const SizedBox(width: 8),
                              _ResultChip(
                                label: 'REWORK',
                                isSelected: _selectedResult == QualityResult.rework,
                                color: const Color(0xFFE65100),
                                onTap: () => setState(() => _selectedResult = QualityResult.rework),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Checked By
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Inspected By',
                              hintText: 'Inspector name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                              filled: true,
                              fillColor: Color(0xFFFAFBFC),
                            ),
                            onChanged: (v) => setState(() {}),
                          ),
                          const SizedBox(height: 12),

                          // Remarks
                          TextField(
                            controller: _remarksCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Remarks / Notes',
                              hintText: 'Inspection notes...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.notes, size: 18),
                              filled: true,
                              fillColor: Color(0xFFFAFBFC),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Batch No Display
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFE082)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.label, size: 16, color: Color(0xFFE65100)),
                                const SizedBox(width: 8),
                                const Text('Batch Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFE65100))),
                                const Spacer(),
                                Text(
                                  'FG-BATCH-${order.id}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isBalanced
                                  ? () async {
                                      final sample = double.tryParse(_sampleQtyCtrl.text) ?? 0.0;
                                      final passed = double.tryParse(_passedQtyCtrl.text) ?? 0.0;
                                      final failed = double.tryParse(_failedQtyCtrl.text) ?? 0.0;

                                      if (sample <= 0 || passed <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Sample quantity and passed quantity must be greater than zero.'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }

                                      final qc = QualityCheckDto(
                                        id: 0,
                                        productionOrderId: widget.orderId,
                                        productId: order.finishedProductId,
                                        batchNo: 'FG-BATCH-${order.id}',
                                        sampleQty: sample,
                                        passedQty: passed,
                                        failedQty: failed,
                                        result: _selectedResult,
                                        checkDate: DateTime.now(),
                                        remarks: _remarksCtrl.text.trim(),
                                      );

                                      final repo = ref.read(qualityCheckRepositoryProvider);
                                      final result = await repo.create(qc);

                                      result.when(
                                        success: (created) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(
                                                      created.isPassed ? Icons.check_circle : Icons.cancel,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text('QC ${created.isPassed ? "PASSED" : "FAILED"}: ${passed.toStringAsFixed(0)}/${sample.toStringAsFixed(0)} units passed inspection.'),
                                                  ],
                                                ),
                                                backgroundColor: created.isPassed ? BrandColors.primary : Colors.redAccent,
                                              ),
                                            );
                                            ref.invalidate(qualityChecksListProvider(widget.orderId));
                                            ref.invalidate(productionOrderDetailProvider(widget.orderId));
                                          }
                                        },
                                        failure: (f) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('QC recording failed: ${f.message}'), backgroundColor: Colors.redAccent),
                                            );
                                          }
                                        },
                                      );
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
                                    Icon(Icons.verified, size: 18),
                                    SizedBox(width: 8),
                                    Text('Submit QC Inspection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_selectedResult == QualityResult.fail)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEF9A9A)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Color(0xFFC62828)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'FAIL result prevents finished goods output. Items will need rework or scrap processing.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFFC62828)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
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

class _ResultChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResultChip({required this.label, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
