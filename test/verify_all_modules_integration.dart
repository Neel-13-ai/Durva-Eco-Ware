import 'dart:convert';
import 'package:durvaeco/core/config/app_config.dart';
import 'package:durvaeco/infrastructure/api/api_client.dart';
import 'package:durvaeco/infrastructure/storage/secure_store.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/auth/data/session_manager.dart';
import 'package:durvaeco/features/masters/data/repositories/category_repository.dart';
import 'package:durvaeco/features/masters/data/repositories/unit_repository.dart';
import 'package:durvaeco/features/masters/data/repositories/warehouse_repository.dart';
import 'package:durvaeco/features/masters/data/repositories/product_repository.dart';
import 'package:durvaeco/features/masters/data/models/category_dto.dart';
import 'package:durvaeco/features/masters/data/models/unit_dto.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';
import 'package:durvaeco/features/masters/data/models/product_dto.dart';

import 'package:durvaeco/features/partners/data/repositories/supplier_repository.dart';
import 'package:durvaeco/features/partners/data/repositories/customer_repository.dart';
import 'package:durvaeco/features/partners/data/repositories/transporter_repository.dart';
import 'package:durvaeco/features/partners/data/repositories/vehicle_repository.dart';
import 'package:durvaeco/features/partners/data/repositories/payment_method_repository.dart';
import 'package:durvaeco/features/partners/data/models/supplier_dto.dart';
import 'package:durvaeco/features/partners/data/models/customer_dto.dart';
import 'package:durvaeco/features/partners/data/models/transporter_dto.dart';
import 'package:durvaeco/features/partners/data/models/vehicle_dto.dart';
import 'package:durvaeco/features/partners/data/models/payment_method_dto.dart';

import 'package:durvaeco/features/waste/data/repositories/waste_repository.dart';
import 'package:durvaeco/features/waste/data/models/waste_reason_dto.dart';
import 'package:durvaeco/features/waste/data/models/waste_entry_dto.dart';

import 'package:durvaeco/features/purchasing/data/repositories/purchase_repository.dart';
import 'package:durvaeco/features/purchasing/data/repositories/goods_receipt_repository.dart';
import 'package:durvaeco/features/purchasing/data/repositories/vendor_payment_repository.dart';
import 'package:durvaeco/features/purchasing/data/models/purchase_dto.dart';
import 'package:durvaeco/features/purchasing/data/models/goods_receipt_dto.dart';
import 'package:durvaeco/features/purchasing/data/models/vendor_payment_dto.dart';

import 'package:durvaeco/features/sales/data/repositories/sales_repository.dart';
import 'package:durvaeco/features/sales/data/repositories/customer_payment_repository.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';

import 'package:durvaeco/features/expenses/data/repositories/expense_repository.dart';
import 'package:durvaeco/features/expenses/data/models/expense_category_dto.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';

import 'package:durvaeco/features/production/bom/data/repositories/bom_repository.dart';
import 'package:durvaeco/features/production/bom/data/models/bom_header_dto.dart';
import 'package:durvaeco/features/production/data/repositories/production_repository.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';
import 'package:durvaeco/features/production/data/models/production_output_dto.dart';

import 'package:durvaeco/features/dispatch/data/repositories/delivery_repository.dart';
import 'package:durvaeco/features/dispatch/data/models/delivery_dto.dart';

class MemoryStore implements SecureStore {
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> deleteAll() async => _data.clear();
}

void main() async {
  print('================================================================');
  print('    DURVA ECO WARE: ALL SCREEN & REPOSITORY INTEGRATION TEST    ');
  print('================================================================\n');

  const baseUrl = 'https://api-dev.durvaecoware.com';
  final plainClient = ApiClient(basePath: baseUrl);
  final session = SessionManager(
    secureStore: MemoryStore(),
    refreshClient: plainClient,
  );

  final client = AuthenticatedApiClient(
    basePath: baseUrl,
    session: session,
  );

  // Authenticate
  print('[1/9] Authenticating with backend...');
  final loginRes = await plainClient.invokeAPI(
    '/api/auth/login',
    'POST',
    {'Content-Type': 'application/json'},
    jsonEncode({'username': 'superadmin', 'password': '123456'}),
  );

  if (loginRes.statusCode != 200) {
    print('❌ Login failed: HTTP ${loginRes.statusCode} - ${loginRes.body}');
    return;
  }

  final authData = jsonDecode(loginRes.body);
  final token = (authData['token'] ?? authData['data']?['token'])?.toString();
  await session.persist(accessToken: token!, refreshToken: token);
  print('✅ Authenticated successfully.\n');

  final now = DateTime.now().millisecondsSinceEpoch;

  // Repositories
  final categoryRepo = CategoryRepository(client);
  final unitRepo = UnitRepository(client);
  final warehouseRepo = WarehouseRepository(client);
  final productRepo = ProductRepository(client);
  final supplierRepo = SupplierRepository(client);
  final customerRepo = CustomerRepository(client);
  final transporterRepo = TransporterRepository(client);
  final vehicleRepo = VehicleRepository(client);
  final paymentMethodRepo = PaymentMethodRepository(client);
  final wasteRepo = WasteRepository(client);
  final purchaseRepo = PurchaseRepository(client);
  final goodsReceiptRepo = GoodsReceiptRepository(client);
  final vendorPaymentRepo = VendorPaymentRepository(client);
  final salesRepo = SalesRepository(client);
  final customerPaymentRepo = CustomerPaymentRepository(client);
  final expenseRepo = ExpenseRepository(client);
  final bomRepo = BomRepository(client);
  final productionRepo = ProductionRepository(client);
  final deliveryRepo = DeliveryRepository(client);

  int passed = 0;
  int total = 0;

  Future<T?> testOp<T>(String name, Future<T> Function() op) async {
    total++;
    try {
      final res = await op();
      print('  ✅ $name -> SUCCESS');
      passed++;
      return res;
    } catch (e) {
      print('  ❌ $name -> FAILED: $e');
      return null;
    }
  }

  // --- Module 1: Master Data ---
  print('[2/9] Testing Master Data Screens & Repositories...');
  
  final catRes = await testOp('Category Create', () async {
    final res = await categoryRepo.create(CategoryDto(
      id: 0,
      name: 'Eco Plates $now',
      type: CategoryType.finishedGood,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final unitRes = await testOp('Unit Create', () async {
    final res = await unitRepo.create(UnitDto(
      id: 0,
      name: 'Box $now',
      symbol: 'BX',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final whRes = await testOp('Warehouse Create', () async {
    final res = await warehouseRepo.create(WarehouseDto(
      id: 0,
      code: 'WH-$now',
      name: 'Central Warehouse $now',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final prodRes = await testOp('Product Create', () async {
    final res = await productRepo.create(ProductDto(
      id: 0,
      name: '10 Inch Areca Plate $now',
      code: 'PROD-$now',
      sku: 'SKU-$now',
      categoryId: catRes?.id ?? 21,
      unitId: unitRes?.id ?? 22,
      productType: ProductType.finishedGood,
      purchasePrice: 4.5,
      sellingPrice: 8.0,
      minStockLevel: 50.0,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  // --- Module 2: Partners & Fleet ---
  print('\n[3/9] Testing Partners & Fleet Screens & Repositories...');
  
  final supRes = await testOp('Supplier Create', () async {
    final res = await supplierRepo.create(SupplierDto(
      id: 0,
      supplierCode: 'SUP-$now',
      supplierName: 'Palm Farms $now',
      phone: '9876543210',
      email: 'palm$now@test.com',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final custRes = await testOp('Customer Create', () async {
    final res = await customerRepo.create(CustomerDto(
      id: 0,
      customerCode: 'CUST-$now',
      customerName: 'Green Catering $now',
      phone: '9876543211',
      email: 'green$now@test.com',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final transRes = await testOp('Transporter Create', () async {
    final res = await transporterRepo.create(TransporterDto(
      id: 0,
      transporterCode: 'TR-$now',
      transporterName: 'Fast Logistics $now',
      phone: '9876543212',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final vehRes = await testOp('Vehicle Create', () async {
    final res = await vehicleRepo.create(VehicleDto(
      id: 0,
      transporterId: transRes?.id ?? 11,
      vehicleNumber: 'MH12TX${now % 10000}',
      vehicleType: 'TRUCK',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final pmRes = await testOp('Payment Method Create', () async {
    final res = await paymentMethodRepo.create(PaymentMethodDto(
      id: 0,
      methodName: 'Direct Bank Transfer $now',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  // --- Module 3: Waste Management ---
  print('\n[4/9] Testing Waste Management Screens & Repositories...');
  
  final wrRes = await testOp('Waste Reason Create', () async {
    final res = await wasteRepo.createReason(WasteReasonDto(
      id: 0,
      reasonName: 'Edge Trimming $now',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final weRes = await testOp('Waste Entry Create', () async {
    final res = await wasteRepo.createEntry(WasteEntryDto(
      id: 0,
      wasteNumber: 'WST-$now',
      wasteDate: DateTime.now(),
      warehouseId: whRes?.id ?? 14,
      productId: prodRes?.id ?? 1,
      wasteReasonId: wrRes?.id ?? 1,
      quantity: 12.0,
      unitCost: 3.5,
      disposalMethod: DisposalMethod.recycled,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  // --- Module 4: Purchasing ---
  print('\n[5/9] Testing Purchasing Screens & Repositories...');
  
  final purRes = await testOp('Purchase Order Create', () async {
    final res = await purchaseRepo.create(PurchaseDto(
      id: 0,
      purchaseNumber: 'PO-$now',
      supplierId: supRes?.id ?? 12,
      warehouseId: whRes?.id ?? 14,
      purchaseDate: DateTime.now(),
      subtotal: 500.0,
      totalAmount: 500.0,
      status: PurchaseStatus.draft,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final grnRes = await testOp('Goods Receipt Create', () async {
    final res = await goodsReceiptRepo.create(GoodsReceiptDto(
      id: 0,
      grnNumber: 'GRN-$now',
      purchaseId: purRes?.id ?? 1,
      warehouseId: whRes?.id ?? 14,
      receiptDate: DateTime.now(),
      totalItems: 1,
      totalQuantity: 100.0,
      totalAmount: 500.0,
      status: GRNStatus.confirmed,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final vpRes = await testOp('Vendor Payment Create', () async {
    final res = await vendorPaymentRepo.create(VendorPaymentDto(
      id: 0,
      paymentNumber: 'VP-$now',
      supplierId: supRes?.id ?? 12,
      purchaseId: purRes?.id ?? 1,
      paymentDate: DateTime.now(),
      amount: 250.0,
      paymentMethodId: pmRes?.id ?? 1,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  // --- Module 5: Sales ---
  print('\n[6/9] Testing Sales & Payment Screens & Repositories...');
  
  final saleRes = await testOp('Sale Order Create', () async {
    final res = await salesRepo.createSale(SaleDto(
      id: 0,
      invoiceNumber: 'INV-$now',
      customerId: custRes?.id ?? 12,
      warehouseId: whRes?.id ?? 14,
      saleDate: DateTime.now(),
      subtotal: 800.0,
      totalAmount: 800.0,
      status: 'CONFIRMED',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final cpRes = await testOp('Customer Payment Create', () async {
    final res = await customerPaymentRepo.createPayment(CustomerPaymentDto(
      id: 0,
      receiptNumber: 'RCP-$now',
      customerId: custRes?.id ?? 12,
      saleId: saleRes?.id ?? 1,
      paymentDate: DateTime.now(),
      amount: 400.0,
      paymentMethodId: pmRes?.id ?? 1,
      createdBy: '1',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  // --- Module 6: Expenses ---
  print('\n[7/9] Testing Expense Screens & Repositories...');
  
  final expCatRes = await testOp('Expense Category Create', () async {
    final res = await expenseRepo.createCategory(ExpenseCategoryDto(
      id: 0,
      categoryName: 'Packaging & Labels $now',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final expRes = await testOp('Expense Create', () async {
    final res = await expenseRepo.createExpense(ExpenseDto(
      id: 0,
      expenseNumber: 'EXP-$now',
      expenseCategoryId: expCatRes?.id ?? 14,
      expenseDate: DateTime.now(),
      amount: 150.0,
      paymentMethodId: pmRes?.id ?? 1,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  // --- Module 7: BOM & Production ---
  print('\n[8/9] Testing BOM & Production Screens & Repositories...');
  
  final bomHeaderRes = await testOp('BOM Header Create', () async {
    final res = await bomRepo.create(BomHeaderDto(
      id: 0,
      bomCode: 'BOM-$now',
      finishedProductId: prodRes?.id ?? 8,
      effectiveFrom: DateTime.now(),
      batchSize: 500.0,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final prodOrderRes = await testOp('Production Order Create', () async {
    final res = await productionRepo.create(ProductionOrderDto(
      id: 0,
      productionNumber: 'PRD-$now',
      bomId: bomHeaderRes?.id ?? 1,
      finishedProductId: prodRes?.id ?? 8,
      warehouseId: whRes?.id ?? 14,
      productionDate: DateTime.now(),
      plannedQty: 500.0,
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  final prodOutputRes = await testOp('Production Output Record', () async {
    final res = await productionRepo.recordOutput(ProductionOutputDto(
      id: 0,
      productionOrderId: prodOrderRes?.id ?? 1,
      productId: prodRes?.id ?? 8,
      producedQty: 250.0,
      goodQty: 245.0,
      rejectQty: 5.0,
      batchNo: 'B-$now',
      outputDate: DateTime.now(),
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  // --- Module 8: Dispatch & Deliveries ---
  print('\n[9/9] Testing Dispatch & Delivery Screens & Repositories...');
  
  final delivRes = await testOp('Delivery Create', () async {
    final res = await deliveryRepo.createDelivery(DeliveryDto(
      id: 0,
      deliveryNumber: 'DEL-$now',
      saleId: saleRes?.id ?? 1,
      customerId: custRes?.id ?? 12,
      transporterId: transRes?.id,
      vehicleId: vehRes?.id,
      deliveryDate: DateTime.now(),
      status: 'DISPATCHED',
    ));
    if (res.isErr) throw res.failureOrNull!.message;
    return res.dataOrNull!;
  });

  print('\n================================================================');
  print('                    INTEGRATION TEST SUMMARY                    ');
  print('================================================================');
  print('Total Operations Tested: $total');
  print('Passed: $passed / $total (${(passed / total * 100).toStringAsFixed(1)}%)');
  print('================================================================\n');
}
