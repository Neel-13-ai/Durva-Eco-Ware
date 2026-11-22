import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/core/constants/api_endpoints.dart';

void main() {
  group('ApiEndpoints route builders', () {
    test('update builder appends /update/{id} with URI encoding', () {
      expect(
        ApiEndpoints.update(ApiEndpoints.products, 42),
        equals('/api/products/update/42'),
      );
      expect(
        ApiEndpoints.update(ApiEndpoints.documentSequences, 'PO/2026/001'),
        equals('/api/document-sequences/update/PO%2F2026%2F001'),
      );
    });

    test('delete builder appends /delete/{id} with URI encoding', () {
      expect(
        ApiEndpoints.delete(ApiEndpoints.categories, 10),
        equals('/api/categories/delete/10'),
      );
      expect(
        ApiEndpoints.delete(ApiEndpoints.warehouses, 'WH 1'),
        equals('/api/warehouses/delete/WH%201'),
      );
    });
  });
}
