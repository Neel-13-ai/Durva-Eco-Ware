import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/inventory/data/models/stock_balance_dto.dart';
import 'package:durvaeco/features/inventory/data/models/stock_transaction_dto.dart';
import 'package:durvaeco/features/inventory/data/models/stock_adjustment_request.dart';
import 'package:durvaeco/features/inventory/data/models/audit_log_dto.dart';

void main() {
  group('StockBalanceDto Calculations & Health Badges', () {
    test('computes total valuation accurately', () {
      const balance = StockBalanceDto(
        id: 1,
        productId: 10,
        productName: 'Bagasse Pulp (Unbleached)',
        warehouseId: 2,
        quantity: 250.0,
        averageCost: 45.0,
        minimumStock: 50.0,
      );

      expect(balance.totalValue, 11250.0);
      expect(balance.isOutOfStock, false);
      expect(balance.isLowStock, false);
    });

    test('detects low stock threshold correctly', () {
      const lowStockBalance = StockBalanceDto(
        id: 2,
        productId: 10,
        productName: 'Bagasse Pulp (Unbleached)',
        warehouseId: 2,
        quantity: 30.0,
        averageCost: 45.0,
        minimumStock: 50.0,
      );

      expect(lowStockBalance.isLowStock, true);
      expect(lowStockBalance.isOutOfStock, false);
    });

    test('detects zero stock as out-of-stock condition', () {
      const zeroStockBalance = StockBalanceDto(
        id: 3,
        productId: 12,
        productName: 'Eco Kraft Box',
        warehouseId: 1,
        quantity: 0.0,
        averageCost: 12.0,
        minimumStock: 100.0,
      );

      expect(zeroStockBalance.isOutOfStock, true);
      expect(zeroStockBalance.isLowStock, false);
      expect(zeroStockBalance.totalValue, 0.0);
    });

    test('converts from and to JSON accurately', () {
      final json = {
        'id': 5,
        'productId': 15,
        'productName': 'Sugarcane Bagasse 500ml Bowl',
        'productCode': 'BOWL-500',
        'unitName': 'Box of 1000',
        'productType': 'FINISHED_GOOD',
        'warehouseId': 1,
        'warehouseName': 'Main Plant Godown',
        'quantity': 1200.0,
        'averageCost': 2.25,
        'minimumStock': 500.0,
        'isActive': true,
      };

      final balance = StockBalanceDto.fromJson(json);
      expect(balance.id, 5);
      expect(balance.productName, 'Sugarcane Bagasse 500ml Bowl');
      expect(balance.totalValue, 2700.0);

      final outJson = balance.toJson();
      expect(outJson['productId'], 15);
      expect(outJson['productType'], 'FINISHED_GOOD');
    });
  });

  group('StockTransactionDto Ledger Model', () {
    test('computes net flow and total cost for inward and outward transactions', () {
      final inTx = StockTransactionDto(
        id: 1,
        productId: 10,
        productName: 'Bagasse Raw Pulp',
        warehouseId: 1,
        transactionType: StockTransactionType.inward,
        quantityIn: 500.0,
        quantityOut: 0.0,
        unitCost: 40.0,
        transactionDate: DateTime(2026, 9, 9, 10, 30),
      );

      expect(inTx.netQuantity, 500.0);
      expect(inTx.totalCost, 20000.0);

      final outTx = StockTransactionDto(
        id: 2,
        productId: 10,
        productName: 'Bagasse Raw Pulp',
        warehouseId: 1,
        transactionType: StockTransactionType.outward,
        quantityIn: 0.0,
        quantityOut: 150.0,
        unitCost: 40.0,
        transactionDate: DateTime(2026, 9, 9, 14, 0),
      );

      expect(outTx.netQuantity, -150.0);
      expect(outTx.totalCost, 6000.0);
    });

    test('serializes transaction types to API values', () {
      expect(StockTransactionType.inward.toApiValue(), 'IN');
      expect(StockTransactionType.outward.toApiValue(), 'OUT');
      expect(StockTransactionType.transfer.toApiValue(), 'TRANSFER');
      expect(StockTransactionType.adjustment.toApiValue(), 'ADJUSTMENT');
    });
  });

  group('StockAdjustmentRequest & AuditLogDto', () {
    test('serializes stock adjustment payload', () {
      const req = StockAdjustmentRequest(
        productId: 10,
        warehouseId: 1,
        mode: AdjustmentMode.increase,
        quantity: 25.0,
        reason: 'Physical Audit Discrepancy',
        unitCost: 42.0,
        notes: 'Discovered in rack B-4',
      );

      final json = req.toJson();
      expect(json['productId'], 10);
      expect(json['mode'], 'INCREASE');
      expect(json['quantity'], 25.0);
      expect(json['reason'], 'Physical Audit Discrepancy');
    });

    test('parses AuditLogDto accurately', () {
      final json = {
        'id': 101,
        'tableName': 'StockBalances',
        'recordId': 5,
        'action': 'UPDATE',
        'changedBy': 'Plant Supervisor',
        'oldValues': '{"Quantity": 100.0}',
        'newValues': '{"Quantity": 125.0}',
        'changeDate': '2026-09-09T15:30:00.000Z',
      };

      final log = AuditLogDto.fromJson(json);
      expect(log.id, 101);
      expect(log.tableName, 'StockBalances');
      expect(log.action, 'UPDATE');
      expect(log.changedBy, 'Plant Supervisor');
    });
  });
}
