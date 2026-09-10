import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/purchasing/data/models/goods_receipt_detail_dto.dart';
import 'package:durvaeco/features/purchasing/data/models/goods_receipt_dto.dart';
import 'package:durvaeco/features/purchasing/data/models/purchase_detail_dto.dart';
import 'package:durvaeco/features/purchasing/data/models/purchase_dto.dart';
import 'package:durvaeco/features/purchasing/data/models/vendor_payment_dto.dart';

void main() {
  group('PurchaseDto and PurchaseDetailDto Calculations', () {
    test('calculates line total and remaining pending quantity accurately', () {
      const line = PurchaseDetailDto(
        id: 1,
        purchaseId: 100,
        productId: 10,
        productName: 'Areca Palm Leaf Sheet',
        quantity: 500.0,
        unitCost: 12.50,
        discount: 100.0,
        tax: 50.0,
        receivedQuantity: 300.0,
      );

      // (500 * 12.50) - 100 + 50 = 6250 - 100 + 50 = 6200
      expect(line.lineTotal, 6200.0);
      expect(line.pendingQuantity, 200.0);
    });

    test('calculates PO outstanding balance correctly', () {
      final po = PurchaseDto(
        id: 100,
        purchaseNumber: 'PO/24/001',
        supplierId: 1,
        warehouseId: 1,
        purchaseDate: DateTime(2026, 9, 1),
        totalAmount: 15000.0,
        paidAmount: 5000.0,
        status: PurchaseStatus.approved,
      );

      expect(po.outstandingBalance, 10000.0);
      expect(po.isFullyPaid, false);
    });
  });

  group('GoodsReceiptDto and GoodsReceiptDetailDto Logic', () {
    test('computes accepted quantities and total cost on inward receipt', () {
      const grnDetail = GoodsReceiptDetailDto(
        id: 1,
        grnId: 10,
        productId: 10,
        productName: 'Bagasse Pulp',
        orderedQuantity: 200.0,
        receivedQuantity: 195.0,
        rejectedQuantity: 5.0,
        unitCost: 40.0,
      );

      expect(grnDetail.acceptedQuantity, 190.0);
      expect(grnDetail.totalCost, 7600.0);
    });

    test('serializes GRN header accurately', () {
      final grn = GoodsReceiptDto(
        id: 5,
        grnNumber: 'GRN/24/001',
        purchaseId: 100,
        warehouseId: 1,
        receiptDate: DateTime(2026, 9, 5),
        status: GRNStatus.confirmed,
        totalItems: 2,
        totalQuantity: 400.0,
        totalAmount: 16000.0,
      );

      final json = grn.toJson();
      expect(json['grnNumber'], 'GRN/24/001');
      expect(json['status'], 'CONFIRMED');
      expect(json['totalAmount'], 16000.0);
    });
  });

  group('VendorPaymentDto Logic', () {
    test('serializes vendor payout vouchers accurately', () {
      final payment = VendorPaymentDto(
        id: 1,
        paymentNumber: 'VP/001',
        supplierId: 1,
        purchaseId: 100,
        paymentDate: DateTime(2026, 9, 6),
        amount: 5000.0,
        paymentMethodId: 2,
        referenceNo: 'UPI-987654321',
      );

      final json = payment.toJson();
      expect(json['paymentNumber'], 'VP/001');
      expect(json['amount'], 5000.0);
      expect(json['referenceNo'], 'UPI-987654321');
    });
  });
}
