import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/masters/data/models/category_dto.dart';
import 'package:durvaeco/features/masters/data/models/document_sequence_dto.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/features/masters/data/models/unit_dto.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';

void main() {
  group('CategoryDto Serialization', () {
    test('converts from and to JSON accurately', () {
      final json = {
        'id': 1,
        'name': 'Areca Plates',
        'code': 'CAT-AP',
        'description': 'Eco friendly plates',
        'type': 'FINISHED_GOOD',
        'isActive': true,
      };

      final dto = CategoryDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.name, 'Areca Plates');
      expect(dto.type, CategoryType.finishedGood);

      final encoded = dto.toJson();
      expect(encoded['name'], 'Areca Plates');
      expect(encoded['type'], 'FINISHED_GOOD');
    });
  });

  group('UnitDto Serialization', () {
    test('converts from and to JSON correctly', () {
      final json = {
        'id': 2,
        'name': 'Kilogram',
        'symbol': 'Kg',
        'description': 'Weight metric',
        'isActive': true,
      };

      final unit = UnitDto.fromJson(json);
      expect(unit.name, 'Kilogram');
      expect(unit.symbol, 'Kg');
    });
  });

  group('ProductDto Business Rules', () {
    test('detects low stock condition correctly', () {
      const lowProduct = ProductDto(
        id: 10,
        name: 'Areca Palm Leaf Sheet',
        code: 'RM-APL001',
        categoryId: 1,
        unitId: 2,
        productType: ProductType.rawMaterial,
        currentStock: 40.0,
        minStockLevel: 100.0,
      );

      expect(lowProduct.isLowStock, true);

      const sufficientProduct = ProductDto(
        id: 11,
        name: '10 Inch Round Plate',
        code: 'FG-PL01',
        categoryId: 1,
        unitId: 2,
        productType: ProductType.finishedGood,
        currentStock: 450.0,
        minStockLevel: 100.0,
      );

      expect(sufficientProduct.isLowStock, false);
    });
  });

  group('DocumentSequenceDto Formatting', () {
    test('generates padded document codes with prefix and suffix', () {
      const seq = DocumentSequenceDto(
        id: 1,
        moduleName: 'Purchase Orders',
        prefix: 'PO/24-25/',
        nextNumber: 42,
        padding: 4,
        suffix: null,
      );

      expect(seq.sampleGeneratedCode, 'PO/24-25/0042');
    });
  });

  group('WarehouseDto Model', () {
    test('creates warehouse and parses fields correctly', () {
      final json = {
        'id': 1,
        'name': 'Central Godown',
        'code': 'WH-01',
        'address': 'Plot 12, Industrial Area',
        'city': 'Indore',
        'state': 'MP',
        'managerName': 'Rahul Verma',
        'phone': '9999999999',
        'isActive': true,
      };

      final wh = WarehouseDto.fromJson(json);
      expect(wh.name, 'Central Godown');
      expect(wh.code, 'WH-01');
      expect(wh.managerName, 'Rahul Verma');
    });
  });
}
