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
    this.sku,
    this.barcode,
    this.categoryId = 0,
    this.unitId = 0,
    this.productType = ProductType.finishedGood,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.minStockLevel = 0.0,
    this.maxStockLevel,
    this.reorderLevel = 0.0,
    this.currentStock = 0.0,
    this.hsnCode,
    this.taxRate = 0.0,
    this.description,
    this.isActive = true,
    this.status = FormStatus.initial,
    this.failure,
  });

  final int? id;
  final String name;
  final String code;
  final String? sku;
  final String? barcode;
  final int categoryId;
  final int unitId;
  final ProductType productType;
  final double purchasePrice;
  final double sellingPrice;
  final double minStockLevel;
  final double? maxStockLevel;
  final double reorderLevel;
  final double currentStock;
  final String? hsnCode;
  final double taxRate;
  final String? description;
  final bool isActive;
  final FormStatus status;
  final Failure? failure;

  bool get isEditing => id != null && id! > 0;

  ProductDto toDto() {
    return ProductDto(
      id: id ?? 0,
      name: name.trim(),
      code: code.trim(),
      sku: sku?.trim().isEmpty ?? true ? null : sku!.trim(),
      barcode: barcode?.trim().isEmpty ?? true ? null : barcode!.trim(),
      categoryId: categoryId,
      unitId: unitId,
      productType: productType,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      minStockLevel: minStockLevel,
      maxStockLevel: maxStockLevel,
      reorderLevel: reorderLevel,
      currentStock: currentStock,
      hsnCode: hsnCode?.trim().isEmpty ?? true ? null : hsnCode!.trim(),
      taxRate: taxRate,
      description: description?.trim().isEmpty ?? true ? null : description!.trim(),
      isActive: isActive,
    );
  }

  ProductFormState copyWith({
    int? id,
    String? name,
    String? code,
    String? sku,
    String? barcode,
    int? categoryId,
    int? unitId,
    ProductType? productType,
    double? purchasePrice,
    double? sellingPrice,
    double? minStockLevel,
    double? maxStockLevel,
    double? reorderLevel,
    double? currentStock,
    String? hsnCode,
    double? taxRate,
    String? description,
    bool? isActive,
    FormStatus? status,
    Failure? failure,
  }) {
    return ProductFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      productType: productType ?? this.productType,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      currentStock: currentStock ?? this.currentStock,
      hsnCode: hsnCode ?? this.hsnCode,
      taxRate: taxRate ?? this.taxRate,
      description: description ?? this.description,
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
        sku: product.sku,
        barcode: product.barcode,
        categoryId: product.categoryId,
        unitId: product.unitId,
        productType: product.productType,
        purchasePrice: product.purchasePrice,
        sellingPrice: product.sellingPrice,
        minStockLevel: product.minStockLevel,
        maxStockLevel: product.maxStockLevel,
        reorderLevel: product.reorderLevel,
        currentStock: product.currentStock,
        hsnCode: product.hsnCode,
        taxRate: product.taxRate,
        description: product.description,
        isActive: product.isActive,
      );
    } else {
      state = const ProductFormState();
    }
  }

  void setName(String val) => state = state.copyWith(name: val);
  void setCode(String val) => state = state.copyWith(code: val);
  void setSku(String? val) => state = state.copyWith(sku: val);
  void setBarcode(String? val) => state = state.copyWith(barcode: val);
  void setCategoryId(int val) => state = state.copyWith(categoryId: val);
  void setUnitId(int val) => state = state.copyWith(unitId: val);
  void setProductType(ProductType val) => state = state.copyWith(productType: val);
  void setPurchasePrice(double val) => state = state.copyWith(purchasePrice: val);
  void setSellingPrice(double val) => state = state.copyWith(sellingPrice: val);
  void setMinStockLevel(double val) => state = state.copyWith(minStockLevel: val);
  void setMaxStockLevel(double? val) => state = state.copyWith(maxStockLevel: val);
  void setReorderLevel(double val) => state = state.copyWith(reorderLevel: val);
  void setHsnCode(String? val) => state = state.copyWith(hsnCode: val);
  void setTaxRate(double val) => state = state.copyWith(taxRate: val);
  void setDescription(String? val) => state = state.copyWith(description: val);
  void setIsActive(bool val) => state = state.copyWith(isActive: val);

  Future<bool> submit() async {
    if (state.name.trim().isEmpty || state.code.trim().isEmpty || (state.sku?.trim().isEmpty ?? true)) {
      state = state.copyWith(
        status: FormStatus.error,
        failure: const ValidationFailure('Name, Code, and SKU are required'),
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
        _ref.invalidate(productsListProvider);
        if (state.isEditing && state.id != null) {
          _ref.invalidate(productDetailProvider(state.id!));
        }
        if (mounted) state = state.copyWith(status: FormStatus.success);
        return true;
      },
      failure: (f) {
        if (mounted) state = state.copyWith(status: FormStatus.error, failure: f);
        return false;
      },
    );
  }

  Future<bool> delete(int id) async {
    state = state.copyWith(status: FormStatus.submitting, failure: null);
    final result = await _repo.delete(id);
    return result.when(
      success: (_) {
        _ref.invalidate(productsListProvider);
        _ref.invalidate(productDetailProvider(id));
        if (mounted) state = state.copyWith(status: FormStatus.success);
        return true;
      },
      failure: (f) {
        if (mounted) state = state.copyWith(status: FormStatus.error, failure: f);
        return false;
      },
    );
  }
}

final productFormControllerProvider =
    StateNotifierProvider<ProductFormController, ProductFormState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductFormController(repo, ref);
});
