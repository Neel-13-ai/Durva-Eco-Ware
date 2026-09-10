import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/production/data/models/production_stage_entry_dto.dart';
import 'package:durvaeco/features/production/data/models/production_material_issue_dto.dart';
import 'package:durvaeco/features/production/data/models/production_output_dto.dart';
import 'package:durvaeco/features/production/data/models/quality_check_dto.dart';

void main() {
  group('ProductionOutputDto Balance & Reject Rate Formulas', () {
    test('verifies output balance where ProducedQty == GoodQty + RejectQty', () {
      final balancedOutput = ProductionOutputDto(
        id: 1,
        productionOrderId: 10,
        productId: 201,
        producedQty: 5000.0,
        goodQty: 4850.0,
        rejectQty: 150.0,
        batchNo: 'FG-202609-10',
        outputDate: DateTime(2026, 9, 9),
      );

      expect(balancedOutput.isBalanced, true);
      // Reject rate = (150 / 5000) * 100 = 3.0%
      expect(balancedOutput.rejectRatePercent, 3.0);
    });

    test('detects unbalanced output quantities correctly', () {
      final unbalancedOutput = ProductionOutputDto(
        id: 2,
        productionOrderId: 10,
        productId: 201,
        producedQty: 5000.0,
        goodQty: 4000.0,
        rejectQty: 200.0, // 4000 + 200 != 5000
        batchNo: 'FG-202609-10',
        outputDate: DateTime(2026, 9, 9),
      );

      expect(unbalancedOutput.isBalanced, false);
    });
  });

  group('QualityCheckDto Quality Gates & Sampling', () {
    test('computes pass rate and PASS status accurately', () {
      final qc = QualityCheckDto(
        id: 1,
        productionOrderId: 10,
        productId: 201,
        batchNo: 'FG-202609-10',
        sampleQty: 100.0,
        passedQty: 98.0,
        failedQty: 2.0,
        result: QualityResult.pass,
        checkedBy: 'QC Lead Incharge',
        checkDate: DateTime(2026, 9, 9, 14, 0),
      );

      expect(qc.isPassed, true);
      expect(qc.passRatePercent, 98.0);
    });

    test('handles REWORK and FAIL results correctly', () {
      final failQc = QualityCheckDto(
        id: 2,
        productionOrderId: 10,
        productId: 201,
        batchNo: 'FG-202609-10',
        sampleQty: 50.0,
        passedQty: 20.0,
        failedQty: 30.0,
        result: QualityResult.fail,
        checkedBy: 'QC Inspector',
        checkDate: DateTime.now(),
      );

      expect(failQc.isPassed, false);
      expect(failQc.result.toApiValue(), 'FAIL');
    });
  });

  group('ProductionOrderDto Execution Aggregates', () {
    test('computes stage progress fraction across sequential workflow', () {
      const stage1 = ProductionStageEntryDto(
        id: 1,
        productionOrderId: 1,
        stageId: 101,
        stageName: 'Pulping',
        sequenceNo: 1,
        status: StageStatus.completed,
      );

      const stage2 = ProductionStageEntryDto(
        id: 2,
        productionOrderId: 1,
        stageId: 102,
        stageName: 'Thermoforming Press',
        sequenceNo: 2,
        status: StageStatus.inProgress,
      );

      const stage3 = ProductionStageEntryDto(
        id: 3,
        productionOrderId: 1,
        stageId: 103,
        stageName: 'Packaging',
        sequenceNo: 3,
        status: StageStatus.pending,
      );

      final order = ProductionOrderDto(
        id: 1,
        productionNumber: 'PRD-2026-001',
        bomId: 10,
        finishedProductId: 201,
        warehouseId: 1,
        productionDate: DateTime(2026, 9, 9),
        plannedQty: 5000.0,
        stages: const [stage1, stage2, stage3],
      );

      // 1 of 3 completed = 33.33%
      expect(order.stageProgress, closeTo(1 / 3, 0.01));
    });

    test('tracks material issue completeness and good output tallies', () {
      const mat1 = ProductionMaterialIssueDto(
        id: 1,
        productionOrderId: 1,
        productId: 50,
        requiredQty: 250.0,
        issuedQty: 250.0,
      );

      const mat2 = ProductionMaterialIssueDto(
        id: 2,
        productionOrderId: 1,
        productId: 51,
        requiredQty: 10.0,
        issuedQty: 10.0,
      );

      final out1 = ProductionOutputDto(
        id: 1,
        productionOrderId: 1,
        productId: 201,
        producedQty: 3000.0,
        goodQty: 2950.0,
        rejectQty: 50.0,
        batchNo: 'FG-01',
        outputDate: DateTime.now(),
      );

      final out2 = ProductionOutputDto(
        id: 2,
        productionOrderId: 1,
        productId: 201,
        producedQty: 2000.0,
        goodQty: 1980.0,
        rejectQty: 20.0,
        batchNo: 'FG-02',
        outputDate: DateTime.now(),
      );

      final order = ProductionOrderDto(
        id: 1,
        productionNumber: 'PRD-2026-001',
        bomId: 10,
        finishedProductId: 201,
        warehouseId: 1,
        productionDate: DateTime(2026, 9, 9),
        plannedQty: 5000.0,
        materials: const [mat1, mat2],
        outputs: [out1, out2],
      );

      expect(order.isMaterialsFullyIssued, true);
      // Good outputs = 2950 + 1980 = 4930
      expect(order.totalGoodOutput, 4930.0);
    });
  });
}
