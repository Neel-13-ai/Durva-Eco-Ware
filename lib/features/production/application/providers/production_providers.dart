import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/production/data/models/production_material_issue_dto.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/production/data/models/production_stage_dto.dart';
import 'package:durvaeco/features/production/data/models/quality_check_dto.dart';
import 'package:durvaeco/features/production/data/repositories/production_repository.dart';
import 'package:durvaeco/features/production/data/repositories/quality_check_repository.dart';

// Repositories
final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return ProductionRepository(client);
});

final qualityCheckRepositoryProvider = Provider<QualityCheckRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return QualityCheckRepository(client);
});

// Filters & Order List
final productionStatusFilterProvider = StateProvider<ProductionStatus?>((ref) => null);

final productionOrdersListProvider = FutureProvider<List<ProductionOrderDto>>((ref) async {
  final repo = ref.watch(productionRepositoryProvider);
  final status = ref.watch(productionStatusFilterProvider);
  final result = await repo.getAll(status: status);
  return result.when(
    success: (list) => list,
    failure: (f) => throw Exception(f.message),
  );
});

// Single Order Detail
final productionOrderDetailProvider = FutureProvider.family<ProductionOrderDto?, int>((ref, id) async {
  final repo = ref.watch(productionRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (order) => order,
    failure: (f) => throw Exception(f.message),
  );
});

// Production Stages
final productionStagesListProvider = FutureProvider<List<ProductionStageDto>>((ref) async {
  final repo = ref.watch(productionRepositoryProvider);
  final result = await repo.listStages();
  return result.when(
    success: (stages) {
      if (stages.isNotEmpty) return stages;
      // Default standard manufacturing stages if backend returns empty
      return const [
        ProductionStageDto(id: 1, stageName: 'Raw Pulp Preparation & Mixing', sequenceNo: 1),
        ProductionStageDto(id: 2, stageName: 'Thermoforming / Molding Press', sequenceNo: 2),
        ProductionStageDto(id: 3, stageName: 'Edge Trimming & Die-Cutting', sequenceNo: 3),
        ProductionStageDto(id: 4, stageName: 'Quality Control & Disinfection', sequenceNo: 4),
        ProductionStageDto(id: 5, stageName: 'Shrink Wrapping & Boxing', sequenceNo: 5),
      ];
    },
    failure: (_) => const [
      ProductionStageDto(id: 1, stageName: 'Raw Pulp Preparation & Mixing', sequenceNo: 1),
      ProductionStageDto(id: 2, stageName: 'Thermoforming / Molding Press', sequenceNo: 2),
      ProductionStageDto(id: 3, stageName: 'Edge Trimming & Die-Cutting', sequenceNo: 3),
      ProductionStageDto(id: 4, stageName: 'Quality Control & Disinfection', sequenceNo: 4),
      ProductionStageDto(id: 5, stageName: 'Shrink Wrapping & Boxing', sequenceNo: 5),
    ],
  );
});

// Quality Checks for an Order
final qualityChecksListProvider = FutureProvider.family<List<QualityCheckDto>, int>((ref, orderId) async {
  final repo = ref.watch(qualityCheckRepositoryProvider);
  final result = await repo.getAll(productionOrderId: orderId);
  return result.when(
    success: (list) => list,
    failure: (f) => throw Exception(f.message),
  );
});

// Material Issues for an Order
final productionMaterialsListProvider = FutureProvider.family<List<ProductionMaterialIssueDto>, int>((ref, orderId) async {
  final repo = ref.watch(productionRepositoryProvider);
  final result = await repo.getMaterialIssues(orderId);
  return result.when(
    success: (list) => list,
    failure: (f) => throw Exception(f.message),
  );
});
