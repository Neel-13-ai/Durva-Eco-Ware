import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:durvaeco/features/auth/application/auth_controller.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/presentation/screens/login_screen.dart';
import 'package:durvaeco/features/auth/presentation/screens/splash_screen.dart';
import 'package:durvaeco/features/home/presentation/screens/home_screen.dart';
import 'package:durvaeco/features/home/presentation/screens/more_menu_screen.dart';
import 'package:durvaeco/shared/widgets/app_shell_scaffold.dart';
import 'package:durvaeco/shared/widgets/route_guard.dart';

import 'package:durvaeco/features/masters/presentation/screens/categories/category_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/master_entry_hub_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/products/product_detail_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/products/product_form_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/products/product_list_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/sequences/sequence_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/units/unit_screen.dart';
import 'package:durvaeco/features/masters/presentation/screens/warehouses/warehouse_screen.dart';

import 'package:durvaeco/features/partners/presentation/screens/customers/customer_form_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/customers/customer_list_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/payment_methods/payment_method_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/suppliers/supplier_form_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/suppliers/supplier_list_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/transporters/transporter_form_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/transporters/transporter_list_screen.dart';
import 'package:durvaeco/features/partners/presentation/screens/vehicles/vehicle_list_screen.dart';

import 'package:durvaeco/features/purchasing/presentation/screens/goods_receipt_form_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/purchase_detail_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/purchase_list_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/purchase_order_form_screen.dart';
import 'package:durvaeco/features/purchasing/presentation/screens/vendor_payment_form_screen.dart';

import 'package:durvaeco/features/inventory/presentation/screens/stock_dashboard_screen.dart';
import 'package:durvaeco/features/inventory/presentation/screens/stock_movement_screen.dart';

import 'package:durvaeco/features/production/bom/presentation/screens/bom_list_screen.dart';
import 'package:durvaeco/features/production/bom/presentation/screens/bom_form_screen.dart';
import 'package:durvaeco/features/production/bom/presentation/screens/bom_detail_screen.dart';

import 'package:durvaeco/features/production/presentation/screens/production_order_list_screen.dart';
import 'package:durvaeco/features/production/presentation/screens/production_order_form_screen.dart';
import 'package:durvaeco/features/production/presentation/screens/production_stage_tracker_screen.dart';

import 'package:durvaeco/features/waste/presentation/screens/waste_list_screen.dart';
import 'package:durvaeco/features/waste/presentation/screens/waste_entry_form_screen.dart';
import 'package:durvaeco/features/waste/presentation/screens/waste_reason_screen.dart';

import 'package:durvaeco/features/sales/presentation/screens/sales_list_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/sales_form_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/sales_detail_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/customer_payment_form_screen.dart';

import 'package:durvaeco/features/dispatch/presentation/screens/dispatch_history_screen.dart';
import 'package:durvaeco/features/dispatch/presentation/screens/pending_dispatch_screen.dart';
import 'package:durvaeco/features/dispatch/presentation/screens/delivery_form_screen.dart';
import 'package:durvaeco/features/dispatch/presentation/screens/delivery_detail_screen.dart';

import 'package:durvaeco/features/expenses/presentation/screens/expense_list_screen.dart';
import 'package:durvaeco/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:durvaeco/features/expenses/presentation/screens/expense_category_screen.dart';

import 'package:durvaeco/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:durvaeco/features/manufacturing_flow/presentation/screens/manufacturing_flow_screen.dart';
import 'package:durvaeco/features/reports/presentation/screens/reports_hub_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
const _publicRoutes = {'/', '/login'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AuthState>(ref.read(authControllerProvider));

  ref.listen<AuthState>(authControllerProvider, (_, next) {
    refresh.value = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    observers: [SentryNavigatorObserver()],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (authState.status == AuthStatus.unauthenticated && !isPublic) {
        return '/login';
      }

      if (authState.status == AuthStatus.authenticated && isPublic) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Public Auth Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 5-Tab Shell Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const RouteGuard(child: HomeScreen()),
              ),
            ],
          ),
          // Tab 1: Purchase
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/purchases',
                builder: (context, state) => const RouteGuard(child: PurchaseListScreen()),
              ),
            ],
          ),
          // Tab 2: Production
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/production',
                builder: (context, state) => const RouteGuard(child: ProductionOrderListScreen()),
              ),
            ],
          ),
          // Tab 3: Inventory / Stock
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const RouteGuard(child: StockDashboardScreen()),
              ),
            ],
          ),
          // Tab 4: More / Hub
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const RouteGuard(child: MoreMenuScreen()),
              ),
            ],
          ),
        ],
      ),

      // Sub-Routes & Detail Views (Pushing over root navigator)
      // Core Master Data (Epic #02)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters',
        builder: (context, state) => const RouteGuard(child: MasterEntryHubScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters/products',
        builder: (context, state) => const RouteGuard(child: ProductListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters/products/new',
        builder: (context, state) => const RouteGuard(child: ProductFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters/products/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: ProductDetailScreen(productId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters/products/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: ProductFormScreen(productId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters/categories',
        builder: (context, state) => const RouteGuard(child: CategoryScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters/units',
        builder: (context, state) => const RouteGuard(child: UnitScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters/warehouses',
        builder: (context, state) => const RouteGuard(child: WarehouseScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/masters/sequences',
        builder: (context, state) => const RouteGuard(child: SequenceScreen()),
      ),

      // Partner Masters & Fleet (Epic #03)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/suppliers',
        builder: (context, state) => const RouteGuard(child: SupplierListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/suppliers/new',
        builder: (context, state) => const RouteGuard(child: SupplierFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/suppliers/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: SupplierFormScreen(supplierId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/customers',
        builder: (context, state) => const RouteGuard(child: CustomerListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/customers/new',
        builder: (context, state) => const RouteGuard(child: CustomerFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/customers/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: CustomerFormScreen(customerId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/transporters',
        builder: (context, state) => const RouteGuard(child: TransporterListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/transporters/new',
        builder: (context, state) => const RouteGuard(child: TransporterFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/transporters/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: TransporterFormScreen(transporterId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/vehicles',
        builder: (context, state) => const RouteGuard(child: VehicleListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/partners/payment-methods',
        builder: (context, state) => const RouteGuard(child: PaymentMethodScreen()),
      ),

      // Purchasing Detail & Action Routes (Epic #04)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/purchases/new',
        builder: (context, state) => const RouteGuard(child: PurchaseOrderFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/purchases/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: PurchaseDetailScreen(purchaseId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/purchases/:id/grn',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: GoodsReceiptFormScreen(purchaseId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/purchases/:id/pay',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: VendorPaymentFormScreen(purchaseId: id));
        },
      ),

      // Inventory Movements (Epic #05)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/inventory/movements',
        builder: (context, state) => const RouteGuard(child: StockMovementScreen()),
      ),

      // BOM & Recipe Engineering (Epic #06)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/bom',
        builder: (context, state) => const RouteGuard(child: BomListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/bom/new',
        builder: (context, state) => const RouteGuard(child: BomFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/bom/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: BomDetailScreen(bomId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/bom/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: BomFormScreen(bomId: id));
        },
      ),

      // Production Actions (Epic #07)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/production/new',
        builder: (context, state) => const RouteGuard(child: ProductionOrderFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/production/:id/track',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: ProductionStageTrackerScreen(orderId: id));
        },
      ),

      // Waste & Scrap Management (Epic #08)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/waste',
        builder: (context, state) => const RouteGuard(child: WasteListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/waste/new',
        builder: (context, state) => const RouteGuard(child: WasteEntryFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/waste/reasons',
        builder: (context, state) => const RouteGuard(child: WasteReasonScreen()),
      ),

      // Sales Orders, Invoicing & Customer Payments (Epic #09)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sales',
        builder: (context, state) => const RouteGuard(child: SalesListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sales/new',
        builder: (context, state) => const RouteGuard(child: SalesFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sales/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: SalesDetailScreen(saleId: id));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sales/payments/new',
        builder: (context, state) => const RouteGuard(child: CustomerPaymentFormScreen()),
      ),

      // Dispatch Logistics, Deliveries & Fleet (Epic #10)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/dispatch',
        builder: (context, state) => const RouteGuard(child: DispatchHistoryScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/dispatch/pending',
        builder: (context, state) => const RouteGuard(child: PendingDispatchScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/dispatch/new',
        builder: (context, state) => const RouteGuard(child: DeliveryFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/dispatch/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RouteGuard(child: DeliveryDetailScreen(deliveryId: id));
        },
      ),

      // Expense Management (Epic #11)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/expenses',
        builder: (context, state) => const RouteGuard(child: ExpenseListScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/expenses/new',
        builder: (context, state) => const RouteGuard(child: ExpenseFormScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/expenses/categories',
        builder: (context, state) => const RouteGuard(child: ExpenseCategoryScreen()),
      ),

      // Dashboard, Flow, Notifications & Reports (Epic #12)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const RouteGuard(child: NotificationsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/manufacturing-flow',
        builder: (context, state) => const RouteGuard(child: ManufacturingFlowScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reports',
        builder: (context, state) => const RouteGuard(child: ReportsHubScreen()),
      ),
    ],
  );
});
