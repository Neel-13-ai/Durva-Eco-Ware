import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/home/application/dashboard_metrics_provider.dart';
import 'package:durvaeco/features/notifications/data/models/notification_dto.dart';
import 'package:durvaeco/features/reports/data/models/report_summary_dto.dart';

void main() {
  group('NotificationDto Model & Deep-Linking Types', () {
    test('serializes and deserializes notification alert accurately', () {
      final json = {
        'id': 1,
        'userId': 10,
        'notificationType': 'LOW_STOCK',
        'title': 'Low Stock Alert',
        'message': 'Sugarcane Bagasse Pulp is below minimum threshold (15.0 KG remaining)',
        'referenceId': 3,
        'isRead': false,
        'createdAt': '2026-09-08T09:00:00.000Z',
      };

      final notif = NotificationDto.fromJson(json);
      expect(notif.id, equals(1));
      expect(notif.notificationType, equals('LOW_STOCK'));
      expect(notif.referenceId, equals(3));
      expect(notif.isRead, isFalse);

      final outJson = notif.toJson();
      expect(outJson['notificationType'], equals('LOW_STOCK'));
      expect(outJson['title'], equals('Low Stock Alert'));
    });

    test('copyWith updates isRead status and readAt timestamp correctly', () {
      final now = DateTime.now();
      final notif = NotificationDto(
        id: 2,
        notificationType: 'DISPATCH_READY',
        title: 'Ready for Dispatch',
        message: 'Order INV-1001 packed and staged at Loading Bay 2',
        createdAt: now,
        isRead: false,
      );

      final readNotif = notif.copyWith(isRead: true, readAt: now);
      expect(readNotif.isRead, isTrue);
      expect(readNotif.readAt, equals(now));
    });
  });

  group('Reports & Analytics DTO Models', () {
    test('computes production yield percentage and reject rate accurately', () {
      const summary = ProductionSummaryRowDto(
        orderNumber: 'PRD-202609-01',
        productName: '10-inch Bagasse Round Plate',
        plannedQty: 10000.0,
        producedQty: 9800.0,
        goodQty: 9500.0,
        rejectQty: 300.0,
        status: 'COMPLETED',
      );

      // Yield = (9500 / 10000) * 100 = 95.0%
      // Reject rate = (300 / 9800) * 100 = ~3.06%
      expect(summary.yieldPercentage, equals(95.0));
      expect(summary.rejectRate, closeTo(3.06, 0.01));
    });

    test('serializes and deserializes stock and sales summary rows correctly', () {
      final stockJson = {
        'categoryName': 'Raw Materials',
        'itemCount': 12,
        'totalQuantity': 5400.0,
        'totalValuation': 285000.0,
        'lowStockCount': 2,
      };

      final stockRow = StockSummaryRowDto.fromJson(stockJson);
      expect(stockRow.categoryName, equals('Raw Materials'));
      expect(stockRow.totalValuation, equals(285000.0));
      expect(stockRow.lowStockCount, equals(2));

      final salesJson = {
        'periodOrCustomer': 'Green Catering Ltd',
        'invoiceCount': 4,
        'subtotal': 50000.0,
        'discount': 2000.0,
        'tax': 8640.0,
        'grandTotal': 56640.0,
        'paidAmount': 40000.0,
        'outstandingBalance': 16640.0,
      };

      final salesRow = SalesSummaryRowDto.fromJson(salesJson);
      expect(salesRow.periodOrCustomer, equals('Green Catering Ltd'));
      expect(salesRow.grandTotal, equals(56640.0));
      expect(salesRow.outstandingBalance, equals(16640.0));
    });
  });

  group('DashboardKpiSummary Aggregation', () {
    test('encapsulates plant-wide factory operational summary metrics', () {
      const kpis = DashboardKpiSummary(
        totalStockValuation: 1250000.0,
        lowStockCount: 3,
        activeProductionOrders: 4,
        pendingPurchases: 2,
        totalSalesRevenue: 890000.0,
        pendingDispatches: 5,
      );

      expect(kpis.totalStockValuation, equals(1250000.0));
      expect(kpis.lowStockCount, equals(3));
      expect(kpis.activeProductionOrders, equals(4));
      expect(kpis.pendingPurchases, equals(2));
      expect(kpis.totalSalesRevenue, equals(890000.0));
      expect(kpis.pendingDispatches, equals(5));
    });
  });
}
