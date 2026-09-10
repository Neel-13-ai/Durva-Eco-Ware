import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/expenses/application/expense_form_controller.dart';
import 'package:durvaeco/features/expenses/data/models/expense_category_dto.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';

void main() {
  group('ExpenseCategoryDto Model', () {
    test('serializes and deserializes expense category accurately', () {
      final json = {
        'id': 3,
        'categoryName': 'Machine Spares & Maintenance',
        'description': 'Hydraulic seals, thermoforming heating elements and oil',
        'isActive': true,
      };

      final cat = ExpenseCategoryDto.fromJson(json);
      expect(cat.id, equals(3));
      expect(cat.categoryName, equals('Machine Spares & Maintenance'));
      expect(cat.description, contains('heating elements'));
      expect(cat.isActive, isTrue);

      final outJson = cat.toJson();
      expect(outJson['id'], equals(3));
      expect(outJson['categoryName'], equals('Machine Spares & Maintenance'));
    });
  });

  group('ExpenseDto Model & Calculations', () {
    test('serializes and deserializes expense voucher accurately', () {
      final json = {
        'id': 15,
        'expenseNumber': 'EXP-202609-0012',
        'expenseCategoryId': 2,
        'categoryName': 'Factory Utilities',
        'warehouseId': 1,
        'warehouseName': 'Main Production Plant',
        'expenseDate': '2026-09-08T14:30:00.000Z',
        'description': 'Electricity bill for Plant 1 August cycle',
        'amount': 45800.0,
        'paymentMethodId': 1,
        'paymentMethodName': 'Bank NEFT',
        'vendorName': 'State Electricity Board',
        'referenceNo': 'EB-BILL-998822',
        'createdBy': '1',
        'isActive': true,
      };

      final exp = ExpenseDto.fromJson(json);
      expect(exp.id, equals(15));
      expect(exp.expenseNumber, equals('EXP-202609-0012'));
      expect(exp.amount, equals(45800.0));
      expect(exp.categoryName, equals('Factory Utilities'));
      expect(exp.vendorName, equals('State Electricity Board'));

      final outJson = exp.toJson();
      expect(outJson['id'], equals(15));
      expect(outJson['amount'], equals(45800.0));
    });

    test('computes total outflow and category aggregation across vouchers', () {
      final dt = DateTime(2026, 9, 1);
      final vouchers = [
        ExpenseDto(
          id: 1,
          expenseNumber: 'EXP-01',
          expenseCategoryId: 1,
          expenseDate: dt,
          amount: 5000.0,
          paymentMethodId: 1,
        ),
        ExpenseDto(
          id: 2,
          expenseNumber: 'EXP-02',
          expenseCategoryId: 1,
          expenseDate: dt,
          amount: 3500.0,
          paymentMethodId: 1,
        ),
        ExpenseDto(
          id: 3,
          expenseNumber: 'EXP-03',
          expenseCategoryId: 2,
          expenseDate: dt,
          amount: 12000.0,
          paymentMethodId: 1,
        ),
      ];

      final totalOutflow = vouchers.fold(0.0, (sum, e) => sum + e.amount);
      expect(totalOutflow, equals(20500.0));

      final cat1Total = vouchers.where((e) => e.expenseCategoryId == 1).fold(0.0, (sum, e) => sum + e.amount);
      expect(cat1Total, equals(8500.0));
    });
  });

  group('ExpenseFormState Validation', () {
    test('generates valid DTO from form state', () {
      final now = DateTime.now();
      final state = ExpenseFormState(
        expenseNumber: 'EXP-TEST',
        expenseCategoryId: 4,
        amount: 2500.0,
        paymentMethodId: 2,
        expenseDate: now,
        vendorName: 'Local Hardware Supplier',
      );

      final dto = state.toDto();
      expect(dto.expenseNumber, equals('EXP-TEST'));
      expect(dto.expenseCategoryId, equals(4));
      expect(dto.amount, equals(2500.0));
      expect(dto.vendorName, equals('Local Hardware Supplier'));
    });
  });
}
