import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/purchasing/data/models/vendor_payment_dto.dart';

class VendorPaymentController extends StateNotifier<AsyncValue<void>> {
  VendorPaymentController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> submitPayment(VendorPaymentDto payment) async {
    if (payment.amount <= 0) {
      state = const AsyncValue.error('Payment amount must be greater than 0', StackTrace.empty);
      return false;
    }

    state = const AsyncValue.loading();
    final repo = _ref.read(vendorPaymentRepositoryProvider);
    final result = await repo.create(payment);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(purchasesListProvider);
        _ref.invalidate(purchaseDetailProvider(payment.purchaseId));
        _ref.invalidate(vendorPaymentsListProvider(payment.purchaseId));
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

final vendorPaymentControllerProvider = StateNotifierProvider.autoDispose<
    VendorPaymentController, AsyncValue<void>>((ref) {
  return VendorPaymentController(ref);
});
