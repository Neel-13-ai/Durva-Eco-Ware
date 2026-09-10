import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/production/bom/data/models/bom_detail_dto.dart';
import 'package:durvaeco/features/production/bom/data/models/bom_header_dto.dart';

void main() {
  group('BomDetailDto Scrap Allowance & Cost Calculations', () {
    test('computes effective quantity with 0% scrap correctly', () {
      const detail = BomDetailDto(
        id: 1,
        bomId: 10,
        rawMaterialId: 101,
        quantityRequired: 50.0,
        scrapPercent: 0.0,
        unitCost: 40.0,
      );

      expect(detail.effectiveQuantity, 50.0);
      expect(detail.itemCost, 2000.0);
    });

    test('computes effective quantity with positive scrap allowance percentage', () {
      const detail = BomDetailDto(
        id: 2,
        bomId: 10,
        rawMaterialId: 102,
        rawMaterialName: 'Bagasse Pulp (Unbleached)',
        quantityRequired: 100.0,
        scrapPercent: 5.0, // 5% scrap
        unitCost: 35.0,
      );

      // effectiveQty = 100 * (1 + 0.05) = 105.0
      expect(detail.effectiveQuantity, 105.0);
      // itemCost = 105.0 * 35.0 = 3675.0
      expect(detail.itemCost, 3675.0);
    });

    test('converts from and to JSON accurately', () {
      final json = {
        'id': 1,
        'bomId': 5,
        'rawMaterialId': 20,
        'rawMaterialName': 'Waterproof Additive',
        'rawMaterialCode': 'CHEM-01',
        'unitName': 'Liter',
        'quantityRequired': 4.5,
        'scrapPercent': 2.0,
        'unitCost': 120.0,
        'notes': 'Add during pulping stage',
        'isActive': true,
      };

      final dto = BomDetailDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.rawMaterialName, 'Waterproof Additive');
      expect(dto.scrapPercent, 2.0);
      expect(dto.effectiveQuantity, closeTo(4.59, 0.001));

      final outJson = dto.toJson();
      expect(outJson['rawMaterialId'], 20);
      expect(outJson['unitCost'], 120.0);
    });
  });

  group('BomHeaderDto Batch Costing & Lifecycle Logic', () {
    test('computes total batch cost and per-unit production cost accurately', () {
      const item1 = BomDetailDto(
        id: 1,
        bomId: 1,
        rawMaterialId: 101,
        quantityRequired: 50.0,
        scrapPercent: 0.0,
        unitCost: 40.0, // 2000
      );

      const item2 = BomDetailDto(
        id: 2,
        bomId: 1,
        rawMaterialId: 102,
        quantityRequired: 100.0,
        scrapPercent: 5.0, // 105 effective
        unitCost: 30.0, // 3150
      );

      final bom = BomHeaderDto(
        id: 1,
        bomCode: 'BOM-2026-001',
        finishedProductId: 201,
        finishedProductName: '500ml Bagasse Bowl',
        batchSize: 1000.0, // 1000 units
        effectiveFrom: DateTime(2026, 1, 1),
        items: const [item1, item2],
      );

      // Total batch cost = 2000 + 3150 = 5150
      expect(bom.totalBatchCost, 5150.0);
      // Cost per unit = 5150 / 1000 = 5.15
      expect(bom.costPerUnit, 5.15);
      expect(bom.componentCount, 2);
    });

    test('validates active effective date range correctly', () {
      final activeBom = BomHeaderDto(
        id: 1,
        bomCode: 'BOM-ACTIVE',
        finishedProductId: 201,
        effectiveFrom: DateTime(2025, 1, 1),
        effectiveTo: DateTime(2030, 12, 31),
        isActive: true,
      );
      expect(activeBom.isEffectiveNow, true);

      final expiredBom = BomHeaderDto(
        id: 2,
        bomCode: 'BOM-EXPIRED',
        finishedProductId: 201,
        effectiveFrom: DateTime(2020, 1, 1),
        effectiveTo: DateTime(2021, 1, 1),
        isActive: true,
      );
      expect(expiredBom.isEffectiveNow, false);

      final futureBom = BomHeaderDto(
        id: 3,
        bomCode: 'BOM-FUTURE',
        finishedProductId: 201,
        effectiveFrom: DateTime(2035, 1, 1),
        isActive: true,
      );
      expect(futureBom.isEffectiveNow, false);
    });

    test('serializes and deserializes BOM header with nested details', () {
      final json = {
        'id': 10,
        'bomCode': 'BOM-RECIPE-99',
        'finishedProductId': 301,
        'finishedProductName': 'Eco Clamshell 8x8',
        'finishedProductCode': 'CLAM-88',
        'versionNo': '2.1',
        'batchSize': 500.0,
        'effectiveFrom': '2026-01-01T00:00:00.000',
        'isActive': true,
        'items': [
          {
            'id': 1,
            'bomId': 10,
            'rawMaterialId': 11,
            'rawMaterialName': 'Pulp Sheet',
            'quantityRequired': 25.0,
            'scrapPercent': 4.0,
            'unitCost': 50.0,
          }
        ],
      };

      final bom = BomHeaderDto.fromJson(json);
      expect(bom.id, 10);
      expect(bom.bomCode, 'BOM-RECIPE-99');
      expect(bom.versionNo, '2.1');
      expect(bom.items.length, 1);
      expect(bom.items.first.rawMaterialName, 'Pulp Sheet');

      final outJson = bom.toJson();
      expect(outJson['finishedProductId'], 301);
      expect((outJson['items'] as List).length, 1);
    });
  });
}
