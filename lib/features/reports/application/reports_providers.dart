import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/reports/data/models/report_summary_dto.dart';
import 'package:durvaeco/features/reports/data/repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return ReportsRepository(client);
});

final stockSummaryReportProvider = FutureProvider.autoDispose<List<StockSummaryRowDto>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final result = await repo.getStockSummary();
  return result.when(
    success: (rows) => rows,
    failure: (failure) => throw Exception(failure.message),
  );
});

final productionSummaryReportProvider = FutureProvider.autoDispose<List<ProductionSummaryRowDto>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final result = await repo.getProductionSummary();
  return result.when(
    success: (rows) => rows,
    failure: (failure) => throw Exception(failure.message),
  );
});

final salesSummaryReportProvider = FutureProvider.autoDispose<List<SalesSummaryRowDto>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final result = await repo.getSalesSummary();
  return result.when(
    success: (rows) => rows,
    failure: (failure) => throw Exception(failure.message),
  );
});
