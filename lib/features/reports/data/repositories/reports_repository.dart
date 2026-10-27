import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/core/utils/json_reader.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/reports/data/models/report_summary_dto.dart';

class ReportsRepository {
  final AuthenticatedApiClient _client;

  ReportsRepository(this._client);

  Future<Result<List<StockSummaryRowDto>>> getStockSummary() async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.stockSummaryReport,
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final list = JsonReader.extractList(decoded);
        final items = list
            .whereType<Map<String, dynamic>>()
            .map((e) => StockSummaryRowDto.fromJson(e))
            .toList();
        return Success(items);
      }

      // Fallback: fetch stock balances from core API
      final fallbackRes = await _client.invokeAPI(
        ApiEndpoints.stockBalances,
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );
      if (fallbackRes.statusCode >= 200 && fallbackRes.statusCode < 300) {
        final dynamic decoded = jsonDecode(fallbackRes.body);
        final List<dynamic> list = decoded is List ? decoded : [];
        final rows = <StockSummaryRowDto>[];
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          rows.add(StockSummaryRowDto(
            categoryName: (m['categoryName'] ?? m['CategoryName'] ?? m['productName'] ?? m['ProductName'] ?? 'General').toString(),
            itemCount: 1,
            totalQuantity: (m['currentQuantity'] as num? ?? m['CurrentQuantity'] as num? ?? 0.0).toDouble(),
            totalValuation: (m['totalValue'] as num? ?? m['TotalValue'] as num? ?? 0.0).toDouble(),
            lowStockCount: ((m['isLowStock'] as bool? ?? m['IsLowStock'] as bool?) == true) ? 1 : 0,
          ));
        }
        return Success(rows);
      }
      return const Success([]);
    } catch (_) {
      return const Success([]);
    }
  }

  Future<Result<List<ProductionSummaryRowDto>>> getProductionSummary() async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.productionSummaryReport,
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final list = JsonReader.extractList(decoded);
        final items = list
            .whereType<Map<String, dynamic>>()
            .map((e) => ProductionSummaryRowDto.fromJson(e))
            .toList();
        return Success(items);
      }

      // Fallback: fetch production orders from core API
      final fallbackRes = await _client.invokeAPI(
        ApiEndpoints.productionOrders,
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );
      if (fallbackRes.statusCode >= 200 && fallbackRes.statusCode < 300) {
        final dynamic decoded = jsonDecode(fallbackRes.body);
        final list = JsonReader.extractList(decoded);
        final rows = list.whereType<Map<String, dynamic>>().map((m) {
          return ProductionSummaryRowDto(
            orderNumber: (m['orderNumber'] ?? m['OrderNumber'] ?? m['orderCode'] ?? m['OrderCode'] ?? '').toString(),
            productName: (m['productName'] ?? m['ProductName'] ?? 'Finished Good').toString(),
            plannedQty: (m['plannedQuantity'] as num? ?? m['PlannedQuantity'] as num? ?? 0.0).toDouble(),
            producedQty: (m['producedQuantity'] as num? ?? m['ProducedQuantity'] as num? ?? 0.0).toDouble(),
            goodQty: (m['goodQuantity'] as num? ?? m['GoodQuantity'] as num? ?? 0.0).toDouble(),
            rejectQty: (m['rejectedQuantity'] as num? ?? m['RejectedQuantity'] as num? ?? 0.0).toDouble(),
            status: (m['status'] ?? m['Status'] ?? 'PLANNED').toString(),
          );
        }).toList();
        return Success(rows);
      }
      return const Success([]);
    } catch (_) {
      return const Success([]);
    }
  }

  Future<Result<List<SalesSummaryRowDto>>> getSalesSummary() async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.salesSummaryReport,
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final list = JsonReader.extractList(decoded);
        final items = list
            .whereType<Map<String, dynamic>>()
            .map((e) => SalesSummaryRowDto.fromJson(e))
            .toList();
        return Success(items);
      }

      // Fallback: fetch sales from core API
      final fallbackRes = await _client.invokeAPI(
        ApiEndpoints.sales,
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );
      if (fallbackRes.statusCode >= 200 && fallbackRes.statusCode < 300) {
        final dynamic decoded = jsonDecode(fallbackRes.body);
        final list = JsonReader.extractList(decoded);
        final rows = list.whereType<Map<String, dynamic>>().map((m) {
          final total = (m['totalAmount'] as num? ?? m['TotalAmount'] as num? ?? 0.0).toDouble();
          final paid = (m['paidAmount'] as num? ?? m['PaidAmount'] as num? ?? 0.0).toDouble();
          return SalesSummaryRowDto(
            periodOrCustomer: (m['customerName'] ?? m['CustomerName'] ?? m['invoiceNumber'] ?? m['InvoiceNumber'] ?? 'Customer').toString(),
            invoiceCount: 1,
            subtotal: total,
            grandTotal: total,
            paidAmount: paid,
            outstandingBalance: (total - paid).clamp(0.0, double.infinity),
          );
        }).toList();
        return Success(rows);
      }
      return const Success([]);
    } catch (_) {
      return const Success([]);
    }
  }
}
