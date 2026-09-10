import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/sales/application/sales_form_controller.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';

void main() {
  group('SaleDetailDto & Line Item Calculations', () {
    test('computes line total with quantity, unit rate, discount and tax accurately', () {
      const item = SaleDetailDto(
        id: 1,
        saleId: 10,
        productId: 5,
        productName: 'Bagasse Plate 10-inch',
        quantity: 500,
        unitPrice: 4.50,
        discount: 50.0,
        tax: 110.0,
      );

      // (500 * 4.5) - 50 + 110 = 2250 - 50 + 110 = 2310
      expect(item.lineTotal, equals(2310.0));
      expect(item.productName, equals('Bagasse Plate 10-inch'));
    });

    test('serializes and deserializes line item correctly', () {
      final json = {
        'id': 101,
        'saleId': 50,
        'productId': 12,
        'productName': 'Eco Bowl 250ml',
        'quantity': 1000.0,
        'unitPrice': 3.20,
        'discount': 100.0,
        'tax': 155.0,
      };

      final item = SaleDetailDto.fromJson(json);
      expect(item.id, equals(101));
      expect(item.productId, equals(12));
      expect(item.quantity, equals(1000.0));
      expect(item.unitPrice, equals(3.20));

      final serialized = item.toJson();
      expect(serialized['id'], equals(101));
      expect(serialized['quantity'], equals(1000.0));
    });
  });

  group('SaleDto Lifecycle & Invoice Calculations', () {
    test('computes outstanding balance and detects overdue state correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final sale = SaleDto(
        id: 1,
        invoiceNumber: 'INV-2026-001',
        customerId: 2,
        warehouseId: 1,
        saleDate: DateTime.now().subtract(const Duration(days: 35)),
        dueDate: pastDate,
        subtotal: 10000.0,
        discount: 500.0,
        tax: 1710.0,
        transportCharge: 300.0,
        totalAmount: 11510.0,
        paidAmount: 5000.0,
        status: 'CONFIRMED',
        paymentStatus: 'PARTIALLY_PAID',
      );

      expect(sale.outstandingBalance, equals(6510.0));
      expect(sale.isOverdue, isTrue);
    });

    test('paid invoice is not marked overdue even if due date has passed', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final paidSale = SaleDto(
        id: 2,
        invoiceNumber: 'INV-2026-002',
        customerId: 2,
        warehouseId: 1,
        saleDate: DateTime.now().subtract(const Duration(days: 35)),
        dueDate: pastDate,
        totalAmount: 10000.0,
        paidAmount: 10000.0,
        status: 'CONFIRMED',
        paymentStatus: 'PAID',
      );

      expect(paidSale.outstandingBalance, equals(0.0));
      expect(paidSale.isOverdue, isFalse);
    });
  });

  group('CustomerPaymentDto Model', () {
    test('converts from and to JSON accurately', () {
      final json = {
        'id': 7,
        'receiptNumber': 'REC-9001',
        'customerId': 4,
        'customerName': 'Green Bistro Ltd',
        'saleId': 12,
        'invoiceNumber': 'INV-1002',
        'paymentDate': '2026-09-01T10:00:00.000Z',
        'amount': 25000.0,
        'paymentMethodId': 2,
        'paymentMethodName': 'Bank NEFT',
        'referenceNo': 'NEFT-889977',
      };

      final payment = CustomerPaymentDto.fromJson(json);
      expect(payment.id, equals(7));
      expect(payment.receiptNumber, equals('REC-9001'));
      expect(payment.amount, equals(25000.0));
      expect(payment.customerName, equals('Green Bistro Ltd'));

      final outJson = payment.toJson();
      expect(outJson['receiptNumber'], equals('REC-9001'));
      expect(outJson['amount'], equals(25000.0));
    });
  });

  group('SalesFormState Rollup Calculations', () {
    test('aggregates items subtotal, total tax and grand total with transport charges', () {
      const state = SalesFormState(
        transportCharge: 450.0,
        items: [
          SaleDetailDto(
            id: 1,
            saleId: 0,
            productId: 1,
            quantity: 200,
            unitPrice: 5.0,
            discount: 50.0,
            tax: 95.0,
          ), // subtotal: 1000 - 50 = 950, tax: 95
          SaleDetailDto(
            id: 2,
            saleId: 0,
            productId: 2,
            quantity: 100,
            unitPrice: 10.0,
            discount: 0.0,
            tax: 100.0,
          ), // subtotal: 1000, tax: 100
        ],
      );

      // itemsSubtotal = 950 + 1000 = 1950
      // itemsTax = 95 + 100 = 195
      // grandTotal = 1950 + 195 + 450 = 2595
      expect(state.itemsSubtotal, equals(1950.0));
      expect(state.itemsTax, equals(195.0));
      expect(state.grandTotal, equals(2595.0));
    });
  });
}
