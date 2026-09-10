import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/waste/data/models/waste_reason_dto.dart';
import 'package:durvaeco/features/waste/data/models/waste_entry_dto.dart';
import 'package:durvaeco/features/waste/data/repositories/waste_repository.dart';

// Repository Provider
final wasteRepositoryProvider = Provider<WasteRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return WasteRepository(client);
});

// Waste Reasons
final activeWasteReasonsProvider = FutureProvider<List<WasteReasonDto>>((ref) async {
  final repo = ref.watch(wasteRepositoryProvider);
  final result = await repo.listReasons(includeInactive: false);
  return result.when(
    success: (list) {
      if (list.isNotEmpty) return list;
      return const [
        WasteReasonDto(id: 1, reasonName: 'Thermoforming Mold Flashing / Offcuts'),
        WasteReasonDto(id: 2, reasonName: 'Pulp Density & Slurry Imperfections'),
        WasteReasonDto(id: 3, reasonName: 'Edge Trimming & Die-Cutting Tears'),
        WasteReasonDto(id: 4, reasonName: 'Thermal Scorching & Discoloration'),
        WasteReasonDto(id: 5, reasonName: 'Packaging & Warehouse Handling Drop'),
      ];
    },
    failure: (_) => const [
      WasteReasonDto(id: 1, reasonName: 'Thermoforming Mold Flashing / Offcuts'),
      WasteReasonDto(id: 2, reasonName: 'Pulp Density & Slurry Imperfections'),
      WasteReasonDto(id: 3, reasonName: 'Edge Trimming & Die-Cutting Tears'),
      WasteReasonDto(id: 4, reasonName: 'Thermal Scorching & Discoloration'),
      WasteReasonDto(id: 5, reasonName: 'Packaging & Warehouse Handling Drop'),
    ],
  );
});

// Disposal Filter
final wasteDisposalFilterProvider = StateProvider<DisposalMethod?>((ref) => null);

// Waste Entries List
final wasteEntriesListProvider = FutureProvider<List<WasteEntryDto>>((ref) async {
  final repo = ref.watch(wasteRepositoryProvider);
  final disposal = ref.watch(wasteDisposalFilterProvider);
  final result = await repo.listEntries(disposalMethod: disposal);
  return result.when(
    success: (list) => list,
    failure: (f) => throw Exception(f.message),
  );
});

// Waste & Scrap Analytics Summary
class WasteMetrics {
  const WasteMetrics({
    required this.totalLossAmount,
    required this.totalWasteQuantity,
    required this.recycledQuantity,
    required this.recycledPercent,
    required this.entriesCount,
  });

  final double totalLossAmount;
  final double totalWasteQuantity;
  final double recycledQuantity;
  final double recycledPercent;
  final int entriesCount;
}

final wasteMetricsProvider = Provider<WasteMetrics>((ref) {
  final entriesAsync = ref.watch(wasteEntriesListProvider);
  return entriesAsync.maybeWhen(
    data: (entries) {
      double totalLoss = 0.0;
      double totalQty = 0.0;
      double recycledQty = 0.0;

      for (final e in entries) {
        totalLoss += e.totalLossAmount;
        totalQty += e.quantity;
        if (e.isRecovered) {
          recycledQty += e.quantity;
        }
      }

      final rate = totalQty > 0 ? (recycledQty / totalQty) * 100.0 : 0.0;

      return WasteMetrics(
        totalLossAmount: totalLoss,
        totalWasteQuantity: totalQty,
        recycledQuantity: recycledQty,
        recycledPercent: rate,
        entriesCount: entries.length,
      );
    },
    orElse: () => const WasteMetrics(
      totalLossAmount: 0.0,
      totalWasteQuantity: 0.0,
      recycledQuantity: 0.0,
      recycledPercent: 0.0,
      entriesCount: 0,
    ),
  );
});
