import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/inventory/data/models/stock_adjustment_request.dart';
import 'package:durvaeco/features/inventory/application/providers/inventory_providers.dart';

class StockAdjustmentController extends StateNotifier<AsyncValue<void>> {
  StockAdjustmentController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> submitAdjustment(StockAdjustmentRequest request) async {
    if (request.quantity <= 0) {
      state = const AsyncValue.error('Adjustment quantity must be greater than 0', StackTrace.empty);
      return false;
    }
    if (request.reason.trim().isEmpty) {
      state = const AsyncValue.error('Adjustment reason is mandatory', StackTrace.empty);
      return false;
    }

    state = const AsyncValue.loading();
    final repo = _ref.read(inventoryRepositoryProvider);
    final result = await repo.adjustStock(request);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(stockBalancesListProvider);
        _ref.invalidate(stockTransactionsListProvider);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final stockAdjustmentControllerProvider = StateNotifierProvider.autoDispose<
    StockAdjustmentController, AsyncValue<void>>((ref) {
  return StockAdjustmentController(ref);
});
