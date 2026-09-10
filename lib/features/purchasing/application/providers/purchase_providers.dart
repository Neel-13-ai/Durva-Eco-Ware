import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import '../../data/models/goods_receipt_dto.dart';
import '../../data/models/purchase_dto.dart';
import '../../data/models/vendor_payment_dto.dart';
import '../../data/repositories/goods_receipt_repository.dart';
import '../../data/repositories/purchase_repository.dart';
import '../../data/repositories/vendor_payment_repository.dart';

// --- Repositories ---
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return PurchaseRepository(client);
});

final goodsReceiptRepositoryProvider = Provider<GoodsReceiptRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return GoodsReceiptRepository(client);
});

final vendorPaymentRepositoryProvider = Provider<VendorPaymentRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return VendorPaymentRepository(client);
});

// --- Filter State ---
final purchaseFilterStatusProvider = StateProvider<PurchaseStatus?>((ref) => null);
final purchaseFilterSupplierProvider = StateProvider<int?>((ref) => null);
final purchaseSearchQueryProvider = StateProvider<String>((ref) => '');

// --- List & Family Future Providers ---
final purchasesListProvider = FutureProvider.autoDispose<List<PurchaseDto>>((ref) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  final status = ref.watch(purchaseFilterStatusProvider);
  final supplierId = ref.watch(purchaseFilterSupplierProvider);
  final search = ref.watch(purchaseSearchQueryProvider);

  final result = await repo.getAll(
    status: status,
    supplierId: supplierId,
    search: search,
  );
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final purchaseDetailProvider = FutureProvider.family.autoDispose<PurchaseDto, int>((ref, id) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final goodsReceiptsListProvider = FutureProvider.autoDispose<List<GoodsReceiptDto>>((ref) async {
  final repo = ref.watch(goodsReceiptRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final vendorPaymentsListProvider = FutureProvider.family.autoDispose<List<VendorPaymentDto>, int?>((ref, purchaseId) async {
  final repo = ref.watch(vendorPaymentRepositoryProvider);
  final result = await repo.getAll(purchaseId: purchaseId);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});
