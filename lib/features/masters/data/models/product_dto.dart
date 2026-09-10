import '../../../../core/utils/json_reader.dart';

enum ProductType {
  finishedGood,
  rawMaterial,
  packaging,
}

class ProductDto {
  const ProductDto({
    required this.id,
    required this.name,
    required this.code,
    this.barcode,
    required this.categoryId,
    this.categoryName,
    required this.unitId,
    this.unitName,
    this.productType = ProductType.finishedGood,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.minStockLevel = 0.0,
    this.reorderLevel = 0.0,
    this.currentStock = 0.0,
    this.hsnCode,
    this.taxRate = 0.0,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String code;
  final String? barcode;
  final int categoryId;
  final String? categoryName;
  final int unitId;
  final String? unitName;
  final ProductType productType;
  final double purchasePrice;
  final double sellingPrice;
  final double minStockLevel;
  final double reorderLevel;
  final double currentStock;
  final String? hsnCode;
  final double taxRate;
  final bool isActive;

  bool get isLowStock => currentStock <= minStockLevel && minStockLevel > 0;
  bool get isRawMaterial => productType == ProductType.rawMaterial;
  bool get isFinishedGood => productType == ProductType.finishedGood;
  bool get isPackaging => productType == ProductType.packaging;

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    ProductType parseProductType(String? t) {
      switch (t?.toUpperCase()) {
        case 'RAW_MATERIAL':
        case 'RAWMATERIAL':
        case 'RAW':
          return ProductType.rawMaterial;
        case 'PACKAGING':
          return ProductType.packaging;
        case 'FINISHED_GOOD':
        case 'FINISHEDGOOD':
        case 'FINISHED':
        default:
          return ProductType.finishedGood;
      }
    }

    return ProductDto(
      id: reader.getInt('id', aliases: ['productId', 'ProductId', 'Id']),
      name: reader.getString('name', aliases: ['productName', 'ProductName', 'Name']),
      code: reader.getString('code', aliases: ['productCode', 'ProductCode', 'Code']),
      barcode: reader.getOptionalString('barcode', aliases: ['Barcode']),
      categoryId: reader.getInt('categoryId', aliases: ['CategoryId']),
      categoryName: reader.getOptionalString('categoryName', aliases: ['CategoryName']),
      unitId: reader.getInt('unitId', aliases: ['unitId', 'UnitId']),
      unitName: reader.getOptionalString('unitName', aliases: ['UnitName']),
      productType: parseProductType(reader.getOptionalString('productType', aliases: ['ProductType', 'type', 'Type'])),
      purchasePrice: reader.getDouble('purchasePrice', aliases: ['PurchasePrice', 'purchaseRate', 'PurchaseRate']),
      sellingPrice: reader.getDouble('sellingPrice', aliases: ['SellingPrice', 'price', 'Price']),
      minStockLevel: reader.getDouble('minStockLevel', aliases: ['MinStockLevel', 'minStock', 'MinStock']),
      reorderLevel: reader.getDouble('reorderLevel', aliases: ['ReorderLevel', 'reorderStock', 'ReorderStock']),
      currentStock: reader.getDouble('currentStock', aliases: ['CurrentStock', 'stock', 'Stock', 'quantity', 'Quantity']),
      hsnCode: reader.getOptionalString('hsnCode', aliases: ['HsnCode', 'hsn', 'HSN']),
      taxRate: reader.getDouble('taxRate', aliases: ['TaxRate', 'tax', 'Tax', 'gstRate', 'GstRate']),
      isActive: reader.getBool('isActive', aliases: ['IsActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    String typeToString() {
      switch (productType) {
        case ProductType.rawMaterial:
          return 'RAW_MATERIAL';
        case ProductType.packaging:
          return 'PACKAGING';
        case ProductType.finishedGood:
          return 'FINISHED_GOOD';
      }
    }

    return {
      'id': id,
      'name': name,
      'code': code,
      if (barcode != null) 'barcode': barcode,
      'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      'unitId': unitId,
      if (unitName != null) 'unitName': unitName,
      'productType': typeToString(),
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'minStockLevel': minStockLevel,
      'reorderLevel': reorderLevel,
      'currentStock': currentStock,
      if (hsnCode != null) 'hsnCode': hsnCode,
      'taxRate': taxRate,
      'isActive': isActive,
    };
  }

  ProductDto copyWith({
    int? id,
    String? name,
    String? code,
    String? barcode,
    int? categoryId,
    String? categoryName,
    int? unitId,
    String? unitName,
    ProductType? productType,
    double? purchasePrice,
    double? sellingPrice,
    double? minStockLevel,
    double? reorderLevel,
    double? currentStock,
    String? hsnCode,
    double? taxRate,
    bool? isActive,
  }) {
    return ProductDto(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      productType: productType ?? this.productType,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      currentStock: currentStock ?? this.currentStock,
      hsnCode: hsnCode ?? this.hsnCode,
      taxRate: taxRate ?? this.taxRate,
      isActive: isActive ?? this.isActive,
    );
  }
}
