import 'dart:convert';

import 'package:durvaeco/core/config/app_config.dart';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/providers.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/inventory/application/controllers/stock_adjustment_controller.dart';
import 'package:durvaeco/features/inventory/data/models/stock_adjustment_request.dart';
import 'package:durvaeco/features/inventory/data/models/stock_balance_dto.dart';
import 'package:durvaeco/features/inventory/presentation/screens/stock_adjustment_screen.dart';
import 'package:durvaeco/features/inventory/presentation/widgets/stock_adjustment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../../support/fakes.dart';

void main() {
  const baseUrl = 'https://api-dev.durvaecoware.com';

  MockClient buildInventoryMock({
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? warehouses,
    List<Map<String, dynamic>>? balances,
    int postStatus = 200,
    List<Map<String, dynamic>>? capturedPayloads,
  }) {
    return MockClient((request) async {
      final path = request.url.path;
      if (path == ApiEndpoints.products) {
        return jsonResponse(200, {
          'data': products ??
              [
                {
                  'id': 10,
                  'name': 'Bagasse Pulp',
                  'code': 'PULP-10',
                  'purchasePrice': 45.0,
                  'isActive': true,
                },
                {
                  'id': 11,
                  'name': 'Eco Bowl',
                  'code': 'BOWL-11',
                  'purchasePrice': 12.0,
                  'isActive': true,
                },
              ],
        });
      }
      if (path == ApiEndpoints.warehouses) {
        return jsonResponse(200, {
          'data': warehouses ??
              [
                {'id': 1, 'name': 'Main Godown', 'isActive': true},
              ],
        });
      }
      if (path == ApiEndpoints.stockBalances) {
        return jsonResponse(200, {
          'data': balances ??
              [
                {
                  'id': 1,
                  'productId': 10,
                  'productName': 'Bagasse Pulp',
                  'warehouseId': 1,
                  'warehouseName': 'Main Godown',
                  'quantity': 50.0,
                  'averageCost': 45.0,
                  'isActive': true,
                },
              ],
        });
      }
      if (path == ApiEndpoints.stockTransactions && request.method == 'POST') {
        if (capturedPayloads != null) {
          capturedPayloads.add(
            jsonDecode(request.body) as Map<String, dynamic>,
          );
        }
        if (postStatus >= 400) {
          return jsonResponse(postStatus, {'message': 'Adjustment rejected'});
        }
        return jsonResponse(postStatus, {'id': 99, 'productId': 10});
      }
      return jsonResponse(200, {'data': <Map<String, dynamic>>[]});
    });
  }

  group('StockAdjustmentController & Repository', () {
    test('recount mode allows 0 and computes negative delta accurately', () async {
      final captured = <Map<String, dynamic>>[];
      final client = buildInventoryMock(capturedPayloads: captured);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: baseUrl,
              environment: AppEnvironment.dev,
            ),
          ),
          httpClientProvider.overrideWithValue(client),
          secureStoreProvider.overrideWithValue(InMemorySecureStore()),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(stockAdjustmentControllerProvider.notifier)
          .submitAdjustment(
            const StockAdjustmentRequest(
              productId: 10,
              warehouseId: 1,
              mode: AdjustmentMode.recount,
              quantity: 0.0,
              reason: 'Damaged / Scrap Write-off',
              unitCost: 45.0,
              currentOnHand: 50.0,
            ),
          );

      expect(ok, isTrue);
      expect(captured.length, 1);
      expect(captured.first['quantityIn'], 0.0);
      expect(captured.first['quantityOut'], 50.0);
    });

    test('rejects decrease exceeding current stock and unchanged recount', () async {
      final client = buildInventoryMock();
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: baseUrl,
              environment: AppEnvironment.dev,
            ),
          ),
          httpClientProvider.overrideWithValue(client),
          secureStoreProvider.overrideWithValue(InMemorySecureStore()),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(stockAdjustmentControllerProvider.notifier);

      final overDecrease = await notifier.submitAdjustment(
        const StockAdjustmentRequest(
          productId: 10,
          warehouseId: 1,
          mode: AdjustmentMode.decrease,
          quantity: 60.0,
          reason: 'Shrinkage',
          currentOnHand: 50.0,
        ),
      );
      expect(overDecrease, isFalse);
      expect(
        container.read(stockAdjustmentControllerProvider).hasError,
        isTrue,
      );

      final sameRecount = await notifier.submitAdjustment(
        const StockAdjustmentRequest(
          productId: 10,
          warehouseId: 1,
          mode: AdjustmentMode.recount,
          quantity: 50.0,
          reason: 'Audit',
          currentOnHand: 50.0,
        ),
      );
      expect(sameRecount, isFalse);
    });
  });

  group('StockAdjustmentScreen & StockAdjustmentBottomSheet UI', () {
    testWidgets('StockAdjustmentScreen shows live stock preview, supports batching, and submits', (tester) async {
      final captured = <Map<String, dynamic>>[];
      final client = buildInventoryMock(capturedPayloads: captured);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              const AppConfig(
                apiBaseUrl: baseUrl,
                environment: AppEnvironment.dev,
              ),
            ),
            httpClientProvider.overrideWithValue(client),
            secureStoreProvider.overrideWithValue(InMemorySecureStore()),
          ],
          child: const MaterialApp(
            home: StockAdjustmentScreen(
              initialProductId: 10,
              initialWarehouseId: 1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Adjust Stock / Audit'), findsOneWidget);
      expect(find.text('Current Stock'), findsOneWidget);
      expect(find.text('50.00'), findsOneWidget);
      expect(find.text('+1.00'), findsOneWidget);
      expect(find.text('51.00'), findsOneWidget);

      await tester.ensureVisible(find.text('Add Line to Audit Batch'));
      await tester.tap(find.text('Add Line to Audit Batch'));
      await tester.pumpAndSettle();

      expect(find.text('Queued Audit Lines (1)'), findsOneWidget);
      expect(find.text('Submit 1 Adjustments'), findsOneWidget);

      await tester.ensureVisible(find.text('Submit 1 Adjustments'));
      await tester.tap(find.text('Submit 1 Adjustments'));
      await tester.pumpAndSettle();

      expect(captured.length, 1);
      expect(captured.first['quantityIn'], 1.0);
    });

    testWidgets('StockAdjustmentBottomSheet shows pre-selected balance and inline errors', (tester) async {
      final client = buildInventoryMock(postStatus: 400);
      const balance = StockBalanceDto(
        id: 1,
        productId: 10,
        productName: 'Bagasse Pulp',
        warehouseId: 1,
        warehouseName: 'Main Godown',
        quantity: 50.0,
        averageCost: 45.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              const AppConfig(
                apiBaseUrl: baseUrl,
                environment: AppEnvironment.dev,
              ),
            ),
            httpClientProvider.overrideWithValue(client),
            secureStoreProvider.overrideWithValue(InMemorySecureStore()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => StockAdjustmentBottomSheet.show(
                    context,
                    balance: balance,
                  ),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Bagasse Pulp'), findsOneWidget);
      expect(find.text('Main Godown'), findsOneWidget);
      expect(find.text('50.00'), findsOneWidget);

      await tester.tap(find.text('Save Adjustment'));
      await tester.pumpAndSettle();

      // Inline error is displayed inside the bottom sheet on failure.
      expect(find.textContaining('Adjustment rejected'), findsOneWidget);
    });
  });
}
