import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/waste/data/models/waste_entry_dto.dart';
import 'package:durvaeco/features/waste/data/models/waste_reason_dto.dart';

void main() {
  group('WasteEntryDto Loss Calculations & Recovery Logic', () {
    test('computes total loss amount accurately', () {
      final entry = WasteEntryDto(
        id: 1,
        wasteNumber: 'WST-2026-001',
        wasteDate: DateTime(2026, 9, 9),
        warehouseId: 1,
        productId: 101,
        productName: 'Bagasse Raw Pulp Sheet',
        wasteReasonId: 2,
        quantity: 120.0,
        unitCost: 35.0,
        disposalMethod: DisposalMethod.recycled,
      );

      // Total Loss = 120 * 35 = 4200.0
      expect(entry.totalLossAmount, 4200.0);
      expect(entry.isRecovered, true);
    });

    test('classifies repulped as recovered and discarded as unrecovered', () {
      final repulped = WasteEntryDto(
        id: 2,
        wasteNumber: 'WST-002',
        wasteDate: DateTime.now(),
        warehouseId: 1,
        productId: 102,
        wasteReasonId: 1,
        quantity: 50.0,
        disposalMethod: DisposalMethod.repulped,
      );
      expect(repulped.isRecovered, true);

      final discarded = WasteEntryDto(
        id: 3,
        wasteNumber: 'WST-003',
        wasteDate: DateTime.now(),
        warehouseId: 1,
        productId: 103,
        wasteReasonId: 4,
        quantity: 15.0,
        disposalMethod: DisposalMethod.discarded,
      );
      expect(discarded.isRecovered, false);

      final soldAsScrap = WasteEntryDto(
        id: 4,
        wasteNumber: 'WST-004',
        wasteDate: DateTime.now(),
        warehouseId: 1,
        productId: 104,
        wasteReasonId: 5,
        quantity: 80.0,
        disposalMethod: DisposalMethod.soldAsScrap,
      );
      expect(soldAsScrap.isRecovered, false);
      expect(soldAsScrap.disposalMethod.toApiValue(), 'SOLD_AS_SCRAP');
    });

    test('serializes and deserializes waste entries accurately', () {
      final json = {
        'id': 10,
        'wasteNumber': 'WST-2026-010',
        'wasteDate': '2026-09-09T12:00:00.000',
        'warehouseId': 2,
        'warehouseName': 'Main Raw Material Warehouse',
        'productId': 20,
        'productName': 'Sugarcane Bagasse 500ml Bowl',
        'productCode': 'BOWL-500',
        'unitName': 'Box of 1000',
        'wasteReasonId': 3,
        'wasteReasonName': 'Edge Trimming & Die-Cutting Tears',
        'quantity': 25.0,
        'unitCost': 150.0,
        'productionOrderId': 5,
        'batchNo': 'PRD-LOT-88',
        'disposalMethod': 'RECYCLED',
        'notes': 'Repulped back into batch #89',
        'createdBy': 'Line Operator 2',
        'isActive': true,
      };

      final entry = WasteEntryDto.fromJson(json);
      expect(entry.id, 10);
      expect(entry.wasteNumber, 'WST-2026-010');
      expect(entry.totalLossAmount, 3750.0);
      expect(entry.isRecovered, true);
      expect(entry.productionOrderId, 5);

      final outJson = entry.toJson();
      expect(outJson['productId'], 20);
      expect(outJson['disposalMethod'], 'RECYCLED');
    });
  });

  group('WasteReasonDto Model', () {
    test('parses and serializes waste reason correctly', () {
      final json = {
        'id': 1,
        'reasonName': 'Thermoforming Mold Flashing / Offcuts',
        'description': 'Excess perimeter flash removed during hot press cycle',
        'isActive': true,
      };

      final reason = WasteReasonDto.fromJson(json);
      expect(reason.id, 1);
      expect(reason.reasonName, 'Thermoforming Mold Flashing / Offcuts');

      final outJson = reason.toJson();
      expect(outJson['reasonName'], 'Thermoforming Mold Flashing / Offcuts');
    });
  });
}
