import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/inventory/data/models/stock_balance_dto.dart';
import 'package:durvaeco/features/inventory/data/models/stock_transaction_dto.dart';
import 'package:durvaeco/features/inventory/data/models/audit_log_dto.dart';
import 'package:durvaeco/features/inventory/data/repositories/inventory_repository.dart';
import 'package:durvaeco/features/inventory/data/repositories/stock_transaction_repository.dart';
import 'package:durvaeco/features/inventory/data/repositories/audit_log_repository.dart';

// Repositories
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return InventoryRepository(client);
});

final stockTransactionRepositoryProvider = Provider<StockTransactionRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return StockTransactionRepository(client);
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return AuditLogRepository(client);
});

// Filters
class StockFilter {
  const StockFilter({this.warehouseId, this.productType, this.searchQuery});
  final int? warehouseId;
  final String? productType;
  final String? searchQuery;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockFilter &&
          runtimeType == other.runtimeType &&
          warehouseId == other.warehouseId &&
          productType == other.productType &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => warehouseId.hashCode ^ productType.hashCode ^ searchQuery.hashCode;
}

final stockFilterProvider = StateProvider<StockFilter>((ref) => const StockFilter());

// Stock Balances List
final stockBalancesListProvider = FutureProvider<List<StockBalanceDto>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  final filter = ref.watch(stockFilterProvider);

  final result = await repo.listStockBalances(
    warehouseId: filter.warehouseId,
    productType: filter.productType,
  );

  return result.when(
    success: (balances) {
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        return balances.where((b) {
          final name = (b.productName ?? '').toLowerCase();
          final code = (b.productCode ?? '').toLowerCase();
          return name.contains(query) || code.contains(query);
        }).toList();
      }
      return balances;
    },
    failure: (f) => throw Exception(f.message),
  );
});

// Stock Metrics Summary
class StockMetrics {
  const StockMetrics({
    required this.totalRawMaterialValue,
    required this.totalFinishedGoodsUnits,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalStockValue,
  });

  final double totalRawMaterialValue;
  final double totalFinishedGoodsUnits;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalStockValue;
}

final stockMetricsProvider = Provider<StockMetrics>((ref) {
  final balancesAsync = ref.watch(stockBalancesListProvider);
  return balancesAsync.maybeWhen(
    data: (balances) {
      double rawMaterialVal = 0.0;
      double fgUnits = 0.0;
      int lowStock = 0;
      int outOfStock = 0;
      double totalVal = 0.0;

      for (final b in balances) {
        totalVal += b.totalValue;
        final type = (b.productType ?? '').toUpperCase();
        if (type.contains('RAW') || type == 'RAW_MATERIAL') {
          rawMaterialVal += b.totalValue;
        } else if (type.contains('FINISHED') || type == 'FINISHED_GOOD') {
          fgUnits += b.quantity;
        }

        if (b.isOutOfStock) {
          outOfStock++;
        } else if (b.isLowStock) {
          lowStock++;
        }
      }

      return StockMetrics(
        totalRawMaterialValue: rawMaterialVal,
        totalFinishedGoodsUnits: fgUnits,
        lowStockCount: lowStock,
        outOfStockCount: outOfStock,
        totalStockValue: totalVal,
      );
    },
    orElse: () => const StockMetrics(
      totalRawMaterialValue: 0.0,
      totalFinishedGoodsUnits: 0.0,
      lowStockCount: 0,
      outOfStockCount: 0,
      totalStockValue: 0.0,
    ),
  );
});

// Stock Transactions Ledger
class TransactionFilter {
  const TransactionFilter({this.productId, this.warehouseId, this.type, this.dateFrom, this.dateTo});
  final int? productId;
  final int? warehouseId;
  final StockTransactionType? type;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilter &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          warehouseId == other.warehouseId &&
          type == other.type &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo;

  @override
  int get hashCode => productId.hashCode ^ warehouseId.hashCode ^ type.hashCode ^ dateFrom.hashCode ^ dateTo.hashCode;
}

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final stockTransactionsListProvider = FutureProvider<List<StockTransactionDto>>((ref) async {
  final repo = ref.watch(stockTransactionRepositoryProvider);
  final filter = ref.watch(transactionFilterProvider);

  final result = await repo.listTransactions(
    productId: filter.productId,
    warehouseId: filter.warehouseId,
    type: filter.type,
    dateFrom: filter.dateFrom,
    dateTo: filter.dateTo,
  );

  return result.when(
    success: (list) => list,
    failure: (f) => throw Exception(f.message),
  );
});

// Audit Logs
final auditLogsListProvider = FutureProvider.family<List<AuditLogDto>, String>((ref, tableName) async {
  final repo = ref.watch(auditLogRepositoryProvider);
  final result = await repo.listAuditLogs(tableName: tableName);
  return result.when(
    success: (list) => list,
    failure: (f) => throw Exception(f.message),
  );
});
