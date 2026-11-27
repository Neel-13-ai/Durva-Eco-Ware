import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/inventory/data/models/stock_adjustment_request.dart';
import 'package:durvaeco/features/inventory/application/providers/inventory_providers.dart';

class StockAdjustmentController extends StateNotifier<AsyncValue<void>> {
  StockAdjustmentController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  String? _validateRequest(StockAdjustmentRequest request) {
    if (request.productId <= 0) {
      return 'Please select a product';
    }
    if (request.warehouseId <= 0) {
      return 'Please select a warehouse';
    }
    if (request.mode == AdjustmentMode.recount) {
      if (request.quantity < 0) {
        return 'Recount quantity cannot be negative';
      }
      if (request.currentOnHand != null &&
          request.quantity == request.currentOnHand) {
        return 'New recount matches current stock (${request.currentOnHand})';
      }
    } else {
      if (request.quantity <= 0) {
        return 'Adjustment quantity must be greater than 0';
      }
      if (request.mode == AdjustmentMode.decrease &&
          request.currentOnHand != null &&
          request.quantity > request.currentOnHand!) {
        return 'Reduction exceeds current on-hand stock (${request.currentOnHand})';
      }
    }
    if (request.unitCost < 0) {
      return 'Unit cost cannot be negative';
    }
    if (request.reason.trim().isEmpty) {
      return 'Adjustment reason is mandatory';
    }
    return null;
  }

  Future<bool> submitAdjustment(StockAdjustmentRequest request) async {
    final validationError = _validateRequest(request);
    if (validationError != null) {
      state = AsyncValue.error(validationError, StackTrace.empty);
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

  Future<int> submitBatchAdjustments(List<StockAdjustmentRequest> requests) async {
    if (requests.isEmpty) {
      state = const AsyncValue.error('Add at least one adjustment line', StackTrace.empty);
      return 0;
    }
    for (final req in requests) {
      final err = _validateRequest(req);
      if (err != null) {
        state = AsyncValue.error(err, StackTrace.empty);
        return 0;
      }
    }

    state = const AsyncValue.loading();
    final repo = _ref.read(inventoryRepositoryProvider);
    int succeeded = 0;

    for (final req in requests) {
      final result = await repo.adjustStock(req);
      final ok = result.when(
        success: (_) => true,
        failure: (f) {
          state = AsyncValue.error(f.message, StackTrace.current);
          return false;
        },
      );
      if (!ok) {
        if (succeeded > 0) {
          _ref.invalidate(stockBalancesListProvider);
          _ref.invalidate(stockTransactionsListProvider);
        }
        return succeeded;
      }
      succeeded++;
    }

    state = const AsyncValue.data(null);
    _ref.invalidate(stockBalancesListProvider);
    _ref.invalidate(stockTransactionsListProvider);
    return succeeded;
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

final stockAdjustmentControllerProvider = StateNotifierProvider.autoDispose<
    StockAdjustmentController, AsyncValue<void>>((ref) {
  return StockAdjustmentController(ref);
});
