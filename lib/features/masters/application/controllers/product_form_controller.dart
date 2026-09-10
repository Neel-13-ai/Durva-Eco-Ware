import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';
import 'package:durvaeco/features/masters/data/repositories/product_repository.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';

enum FormStatus { initial, submitting, success, error }

class ProductFormState {
  const ProductFormState({
    this.id,
    this.name = '',
    this.code = '',
    this.barcode,
    this.categoryId = 0,
    this.unitId = 0,
    this.productType = ProductType.finishedGood,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.minStockLevel = 0.0,
    this.reorderLevel = 0.0,
    this.currentStock = 0.0,
    this.hsnCode,
    this.taxRate = 0.0,
    this.isActive = true,
    this.status = FormStatus.initial,
    this.failure,
  });

  final int? id;
  final String name;
  final String code;
  final String? barcode;
  final int categoryId;
  final int unitId;
  final ProductType productType;
  final double purchasePrice;
  final double sellingPrice;
  final double minStockLevel;
  final double reorderLevel;
  final double currentStock;
  final String? hsnCode;
  final double taxRate;
  final bool isActive;
  final FormStatus status;
  final Failure? failure;

  bool get isEditing => id != null && id! > 0;

  ProductDto toDto() {
    return ProductDto(
      id: id ?? 0,
      name: name.trim(),
      code: code.trim(),
      barcode: barcode?.trim().isEmpty ?? true ? null : barcode!.trim(),
      categoryId: categoryId,
      unitId: unitId,
      productType: productType,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      minStockLevel: minStockLevel,
      reorderLevel: reorderLevel,
      currentStock: currentStock,
      hsnCode: hsnCode?.trim().isEmpty ?? true ? null : hsnCode!.trim(),
      taxRate: taxRate,
      isActive: isActive,
    );
  }

  ProductFormState copyWith({
    int? id,
    String? name,
    String? code,
    String? barcode,
    int? categoryId,
    int? unitId,
    ProductType? productType,
    double? purchasePrice,
    double? sellingPrice,
    double? minStockLevel,
    double? reorderLevel,
    double? currentStock,
    String? hsnCode,
    double? taxRate,
    bool? isActive,
    FormStatus? status,
    Failure? failure,
  }) {
    return ProductFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      productType: productType ?? this.productType,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      currentStock: currentStock ?? this.currentStock,
      hsnCode: hsnCode ?? this.hsnCode,
      taxRate: taxRate ?? this.taxRate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      failure: failure ?? this.failure,
    );
  }
}

class ProductFormController extends StateNotifier<ProductFormState> {
  ProductFormController(this._repo, this._ref) : super(const ProductFormState());

  final ProductRepository _repo;
  final Ref _ref;

  void initialize(ProductDto? product) {
    if (product != null) {
      state = ProductFormState(
        id: product.id,
        name: product.name,
        code: product.code,
        barcode: product.barcode,
        categoryId: product.categoryId,
        unitId: product.unitId,
        productType: product.productType,
        purchasePrice: product.purchasePrice,
        sellingPrice: product.sellingPrice,
        minStockLevel: product.minStockLevel,
        reorderLevel: product.reorderLevel,
        currentStock: product.currentStock,
        hsnCode: product.hsnCode,
        taxRate: product.taxRate,
        isActive: product.isActive,
      );
    } else {
      state = const ProductFormState();
    }
  }

  void setName(String val) => state = state.copyWith(name: val);
  void setCode(String val) => state = state.copyWith(code: val);
  void setBarcode(String? val) => state = state.copyWith(barcode: val);
  void setCategoryId(int val) => state = state.copyWith(categoryId: val);
  void setUnitId(int val) => state = state.copyWith(unitId: val);
  void setProductType(ProductType val) => state = state.copyWith(productType: val);
  void setPurchasePrice(double val) => state = state.copyWith(purchasePrice: val);
  void setSellingPrice(double val) => state = state.copyWith(sellingPrice: val);
  void setMinStockLevel(double val) => state = state.copyWith(minStockLevel: val);
  void setReorderLevel(double val) => state = state.copyWith(reorderLevel: val);
  void setHsnCode(String? val) => state = state.copyWith(hsnCode: val);
  void setTaxRate(double val) => state = state.copyWith(taxRate: val);
  void setIsActive(bool val) => state = state.copyWith(isActive: val);

  Future<bool> submit() async {
    if (state.name.trim().isEmpty || state.code.trim().isEmpty) {
      state = state.copyWith(
        status: FormStatus.error,
        failure: const ValidationFailure('Name and Code are required'),
      );
      return false;
    }

    state = state.copyWith(status: FormStatus.submitting, failure: null);
    final dto = state.toDto();

    final result = state.isEditing
        ? await _repo.update(state.id!, dto)
        : await _repo.create(dto);

    return result.when(
      success: (_) {
        state = state.copyWith(status: FormStatus.success);
        _ref.invalidate(productsListProvider);
        return true;
      },
      failure: (f) {
        state = state.copyWith(status: FormStatus.error, failure: f);
        return false;
      },
    );
  }
}

final productFormControllerProvider = StateNotifierProvider.autoDispose<
    ProductFormController, ProductFormState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductFormController(repo, ref);
});
