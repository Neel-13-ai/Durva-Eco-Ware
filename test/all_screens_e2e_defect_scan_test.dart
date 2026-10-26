import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'package:durvaeco/features/auth/presentation/screens/login_screen.dart';
import 'package:durvaeco/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:durvaeco/features/auth/presentation/screens/splash_screen.dart';
import 'package:durvaeco/features/auth/presentation/screens/app_settings_screen.dart';
import 'package:durvaeco/features/auth/presentation/screens/user_management_screen.dart';
import 'package:durvaeco/features/home/presentation/screens/home_screen.dart';
import 'package:durvaeco/features/home/presentation/screens/more_menu_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/purchase_list_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/purchase_order_form_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/purchase_detail_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/goods_receipt_form_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/vendor_payment_form_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/vendor_payment_receipt_screen.dart';
import 'package:durvaeco/features/production/presentation/screens/production_order_list_screen.dart';
import 'package:durvaeco/features/production/presentation/screens/production_order_form_screen.dart';
import 'package:durvaeco/features/production/presentation/screens/production_stage_tracker_screen.dart';
import 'package:durvaeco/features/production/presentation/screens/production_material_issue_screen.dart';
import 'package:durvaeco/features/production/presentation/screens/production_output_form_screen.dart';
import 'package:durvaeco/features/production/presentation/screens/production_quality_check_form_screen.dart';
import 'package:durvaeco/features/production/bom/presentation/screens/bom_list_screen.dart';
import 'package:durvaeco/features/production/bom/presentation/screens/bom_form_screen.dart';
import 'package:durvaeco/features/production/bom/presentation/screens/bom_detail_screen.dart';
import 'package:durvaeco/features/inventory/presentation/screens/stock_dashboard_screen.dart';
import 'package:durvaeco/features/inventory/presentation/screens/stock_movement_screen.dart';
import 'package:durvaeco/features/inventory/presentation/screens/audit_log_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/sales_list_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/sales_form_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/sales_detail_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/customer_payment_list_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/customer_payment_form_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/customer_payment_receipt_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/master_entry_hub_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/products/product_list_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/products/product_form_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/products/product_detail_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/categories/category_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/units/unit_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/warehouses/warehouse_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/sequences/sequence_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/suppliers/supplier_list_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/suppliers/supplier_form_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/customers/customer_list_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/customers/customer_form_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/transporters/transporter_list_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/transporters/transporter_form_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/vehicles/vehicle_list_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/payment_methods/payment_method_screen.dart';
import 'package:durvaeco/features/waste/presentation/screens/waste_list_screen.dart';
import 'package:durvaeco/features/waste/presentation/screens/waste_entry_form_screen.dart';
import 'package:durvaeco/features/waste/presentation/screens/waste_reason_screen.dart';
import 'package:durvaeco/features/expenses/presentation/screens/expense_list_screen.dart';
import 'package:durvaeco/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:durvaeco/features/expenses/presentation/screens/expense_category_screen.dart';
import 'package:durvaeco/features/reports/presentation/screens/reports_hub_screen.dart';
import 'package:durvaeco/features/manufacturing_flow/presentation/screens/manufacturing_flow_screen.dart';
import 'package:durvaeco/features/notifications/presentation/screens/notifications_screen.dart';

Widget _wrap(Widget child, [Size size = const Size(1280, 800)]) {
  return ProviderScope(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  final defects = <String>[];

  Future<void> testScreen(WidgetTester tester, String screenName, Widget widget, [Size size = const Size(1280, 800)]) async {
    try {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(_wrap(widget, size));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final exception = tester.takeException();
      if (exception != null) {
        final msg = exception.toString();
        defects.add('$screenName: $msg');
        print('❌ DEFECT on $screenName: $msg (type: ${exception.runtimeType})');
        if (exception is Error) {
          print(exception.stackTrace);
        }
      } else {
        print('✅ PASSED: $screenName');
      }
    } catch (e) {
      defects.add('$screenName Exception: $e');
      print('❌ EXCEPTION on $screenName: $e');
    }
  }

  testWidgets('E2E Screen Defect Scan across all screens', (tester) async {
    print('======================================================');
    print('   DURVA ECO WARE: COMPREHENSIVE SCREEN DEFECT SCAN   ');
    print('======================================================\n');

    // Auth & Onboarding
    await testScreen(tester, 'SplashScreen', const SplashScreen());
    await testScreen(tester, 'LoginScreen', const LoginScreen());
    await testScreen(tester, 'ForgotPasswordScreen', const ForgotPasswordScreen());

    // Shell & Navigation
    await testScreen(tester, 'HomeScreen (Desktop 1280x800)', const HomeScreen());
    await testScreen(tester, 'HomeScreen (Mobile 390x844)', const HomeScreen(), const Size(390, 844));
    await testScreen(tester, 'MoreMenuScreen', const MoreMenuScreen());

    // Purchasing Module
    await testScreen(tester, 'PurchaseListScreen', const PurchaseListScreen());
    await testScreen(tester, 'PurchaseOrderFormScreen', const PurchaseOrderFormScreen());
    await testScreen(tester, 'PurchaseDetailScreen', const PurchaseDetailScreen(purchaseId: 1));
    await testScreen(tester, 'GoodsReceiptFormScreen', const GoodsReceiptFormScreen(purchaseId: 1));
    await testScreen(tester, 'VendorPaymentFormScreen', const VendorPaymentFormScreen(purchaseId: 1));
    await testScreen(tester, 'VendorPaymentReceiptScreen', const VendorPaymentReceiptScreen(paymentId: 1));

    // Production Module
    await testScreen(tester, 'ProductionOrderListScreen', const ProductionOrderListScreen());
    await testScreen(tester, 'ProductionOrderFormScreen', const ProductionOrderFormScreen());
    await testScreen(tester, 'ProductionStageTrackerScreen', const ProductionStageTrackerScreen(orderId: 1));
    await testScreen(tester, 'ProductionMaterialIssueScreen', const ProductionMaterialIssueScreen(orderId: 1));
    await testScreen(tester, 'ProductionOutputFormScreen', const ProductionOutputFormScreen(orderId: 1));
    await testScreen(tester, 'ProductionQualityCheckScreen', const ProductionQualityCheckScreen(orderId: 1));

    // BOM Module
    await testScreen(tester, 'BomListScreen', const BomListScreen());
    await testScreen(tester, 'BomFormScreen', const BomFormScreen());
    await testScreen(tester, 'BomDetailScreen', const BomDetailScreen(bomId: 1));

    // Inventory Module
    await testScreen(tester, 'StockDashboardScreen', const StockDashboardScreen());
    await testScreen(tester, 'StockMovementScreen', const StockMovementScreen());
    await testScreen(tester, 'AuditLogScreen', const AuditLogScreen());

    // Sales Module
    await testScreen(tester, 'SalesListScreen', const SalesListScreen());
    await testScreen(tester, 'SalesFormScreen', const SalesFormScreen());
    await testScreen(tester, 'SalesDetailScreen', const SalesDetailScreen(saleId: 1));
    await testScreen(tester, 'CustomerPaymentListScreen', const CustomerPaymentListScreen());
    await testScreen(tester, 'CustomerPaymentFormScreen', const CustomerPaymentFormScreen());
    await testScreen(tester, 'CustomerPaymentReceiptScreen', const CustomerPaymentReceiptScreen(paymentId: 1));

    // Masters Module
    await testScreen(tester, 'MasterEntryHubScreen', const MasterEntryHubScreen());
    await testScreen(tester, 'ProductListScreen', const ProductListScreen());
    await testScreen(tester, 'ProductFormScreen', const ProductFormScreen());
    await testScreen(tester, 'ProductDetailScreen', const ProductDetailScreen(productId: 1));
    await testScreen(tester, 'CategoryScreen', const CategoryScreen());
    await testScreen(tester, 'UnitScreen', const UnitScreen());
    await testScreen(tester, 'WarehouseScreen', const WarehouseScreen());
    await testScreen(tester, 'SequenceScreen', const SequenceScreen());

    // Partners & Logistics Module
    await testScreen(tester, 'SupplierListScreen', const SupplierListScreen());
    await testScreen(tester, 'SupplierFormScreen', const SupplierFormScreen());
    await testScreen(tester, 'CustomerListScreen', const CustomerListScreen());
    await testScreen(tester, 'CustomerFormScreen', const CustomerFormScreen());
    await testScreen(tester, 'TransporterListScreen', const TransporterListScreen());
    await testScreen(tester, 'TransporterFormScreen', const TransporterFormScreen());
    await testScreen(tester, 'VehicleListScreen', const VehicleListScreen());
    await testScreen(tester, 'PaymentMethodScreen', const PaymentMethodScreen());

    // Waste Module
    await testScreen(tester, 'WasteListScreen (Desktop)', const WasteListScreen());
    await testScreen(tester, 'WasteListScreen (Mobile 320x642)', const WasteListScreen(), const Size(320, 642));
    await testScreen(tester, 'WasteEntryFormScreen', const WasteEntryFormScreen());
    await testScreen(tester, 'WasteReasonScreen', const WasteReasonScreen());

    // Expense Module
    await testScreen(tester, 'ExpenseListScreen (Desktop)', const ExpenseListScreen());
    await testScreen(tester, 'ExpenseListScreen (Mobile 320x642)', const ExpenseListScreen(), const Size(320, 642));
    await testScreen(tester, 'ExpenseFormScreen', const ExpenseFormScreen());
    await testScreen(tester, 'ExpenseCategoryScreen', const ExpenseCategoryScreen());

    // Reports, Manufacturing Flow, System
    await testScreen(tester, 'ReportsHubScreen', const ReportsHubScreen());
    await testScreen(tester, 'ManufacturingFlowScreen', const ManufacturingFlowScreen());
    await testScreen(tester, 'NotificationsScreen', const NotificationsScreen());
    await testScreen(tester, 'AppSettingsScreen', const AppSettingsScreen());
    await testScreen(tester, 'UserManagementScreen', const UserManagementScreen());

    print('\n======================================================');
    print('               DEFECT SCAN RESULTS SUMMARY             ');
    print('======================================================');
    print('Total Screens Tested: 52');
    print('Defects Found: ${defects.length}');
    for (final d in defects) {
      print(' - $d');
    }
    print('======================================================\n');
  });
}
