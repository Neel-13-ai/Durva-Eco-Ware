import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/dispatch/application/delivery_form_controller.dart';
import 'package:durvaeco/features/dispatch/data/models/delivery_dto.dart';

void main() {
  group('DeliveryDetailDto Model', () {
    test('serializes and deserializes delivery line items accurately', () {
      final json = {
        'id': 201,
        'deliveryId': 55,
        'saleDetailId': 12,
        'productId': 3,
        'productName': '10-inch 3-CP Bagasse Plate',
        'quantity': 1500.0,
        'notes': 'Packed in 30 master cartons',
      };

      final item = DeliveryDetailDto.fromJson(json);
      expect(item.id, equals(201));
      expect(item.deliveryId, equals(55));
      expect(item.saleDetailId, equals(12));
      expect(item.productId, equals(3));
      expect(item.productName, equals('10-inch 3-CP Bagasse Plate'));
      expect(item.quantity, equals(1500.0));

      final serialized = item.toJson();
      expect(serialized['id'], equals(201));
      expect(serialized['quantity'], equals(1500.0));
    });
  });

  group('DeliveryDto Lifecycle & Status Logic', () {
    test('validates dispatch and delivery flags correctly', () {
      final draft = DeliveryDto(
        id: 1,
        deliveryNumber: 'DEL-001',
        saleId: 10,
        customerId: 4,
        deliveryDate: DateTime.now(),
        status: 'DRAFT',
      );
      expect(draft.isDispatched, isFalse);
      expect(draft.isDelivered, isFalse);

      final inTransit = DeliveryDto(
        id: 2,
        deliveryNumber: 'DEL-002',
        saleId: 10,
        customerId: 4,
        deliveryDate: DateTime.now(),
        status: 'DISPATCHED',
      );
      expect(inTransit.isDispatched, isTrue);
      expect(inTransit.isDelivered, isFalse);

      final delivered = DeliveryDto(
        id: 3,
        deliveryNumber: 'DEL-003',
        saleId: 10,
        customerId: 4,
        deliveryDate: DateTime.now(),
        status: 'DELIVERED',
      );
      expect(delivered.isDispatched, isTrue);
      expect(delivered.isDelivered, isTrue);
    });

    test('serializes and deserializes delivery header with nested items accurately', () {
      final json = {
        'id': 99,
        'deliveryNumber': 'DEL-9900',
        'saleId': 44,
        'invoiceNumber': 'INV-4400',
        'customerId': 12,
        'customerName': 'Eco Dine Chain',
        'transporterId': 2,
        'transporterName': 'Blue Dart Cargo',
        'vehicleId': 5,
        'vehicleNumber': 'MH-12-AB-9876',
        'driverName': 'Suresh Patil',
        'driverPhone': '9876543210',
        'trackingNumber': 'BD-TRACK-777',
        'deliveryAddress': 'Shop 14, High Street Mall, Pune',
        'freightAmount': 1200.0,
        'deliveryDate': '2026-09-05T10:00:00.000Z',
        'status': 'DISPATCHED',
        'items': [
          {
            'id': 1,
            'deliveryId': 99,
            'productId': 10,
            'productName': 'Eco Straws 50pk',
            'quantity': 200.0,
          }
        ],
      };

      final delivery = DeliveryDto.fromJson(json);
      expect(delivery.id, equals(99));
      expect(delivery.deliveryNumber, equals('DEL-9900'));
      expect(delivery.customerName, equals('Eco Dine Chain'));
      expect(delivery.transporterName, equals('Blue Dart Cargo'));
      expect(delivery.freightAmount, equals(1200.0));
      expect(delivery.items.length, equals(1));
      expect(delivery.items.first.quantity, equals(200.0));

      final serialized = delivery.toJson();
      expect(serialized['id'], equals(99));
      expect(serialized['trackingNumber'], equals('BD-TRACK-777'));
    });
  });

  group('DeliveryFormState Dispatch Rollup Calculations', () {
    test('computes total dispatched units across multi-product shipment', () {
      const state = DeliveryFormState(
        items: [
          DeliveryDetailDto(id: 1, deliveryId: 0, productId: 1, quantity: 400.0),
          DeliveryDetailDto(id: 2, deliveryId: 0, productId: 2, quantity: 600.0),
          DeliveryDetailDto(id: 3, deliveryId: 0, productId: 3, quantity: 250.0),
        ],
      );

      expect(state.totalDispatchedUnits, equals(1250.0));
    });
  });
}
