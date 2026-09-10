import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/dispatch/application/dispatch_providers.dart';
import 'package:durvaeco/features/inventory/application/providers/inventory_providers.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';

class DashboardKpiSummary {
  final double totalStockValuation;
  final int lowStockCount;
  final int activeProductionOrders;
  final int pendingPurchases;
  final double totalSalesRevenue;
  final int pendingDispatches;

  const DashboardKpiSummary({
    this.totalStockValuation = 0.0,
    this.lowStockCount = 0,
    this.activeProductionOrders = 0,
    this.pendingPurchases = 0,
    this.totalSalesRevenue = 0.0,
    this.pendingDispatches = 0,
  });
}

final dashboardMetricsProvider = FutureProvider.autoDispose<DashboardKpiSummary>((ref) async {
  final balances = await ref.watch(stockBalancesListProvider.future);
  final orders = await ref.watch(productionOrdersListProvider.future);
  final purchases = await ref.watch(purchasesListProvider.future);
  final sales = await ref.watch(salesListProvider.future);
  final pendingDispatches = await ref.watch(pendingDispatchQueueProvider.future);

  double totalStockVal = 0.0;
  int lowStock = 0;
  for (final b in balances) {
    totalStockVal += b.totalValue;
    if (b.isLowStock || b.isOutOfStock) {
      lowStock++;
    }
  }

  final activeOrders = orders.where((o) => o.status == ProductionStatus.inProgress || o.status == ProductionStatus.draft).length;
  final pendingPurchaseOrders = purchases.where((p) => p.status.name == 'approved' || p.status.name == 'pending').length;
  final totalSalesVal = sales.fold(0.0, (sum, s) => sum + s.totalAmount);

  return DashboardKpiSummary(
    totalStockValuation: totalStockVal,
    lowStockCount: lowStock,
    activeProductionOrders: activeOrders,
    pendingPurchases: pendingPurchaseOrders,
    totalSalesRevenue: totalSalesVal,
    pendingDispatches: pendingDispatches.length,
  );
});
