import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/features/expenses/application/expense_providers.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';
import 'package:durvaeco/features/expenses/data/repositories/expense_repository.dart';

enum ExpenseFormStatus { initial, submitting, success, error }

class ExpenseFormState {
  final int? id;
  final String expenseNumber;
  final int expenseCategoryId;
  final int? warehouseId;
  final DateTime? expenseDate;
  final String? description;
  final double amount;
  final int paymentMethodId;
  final String? vendorName;
  final String? referenceNo;
  final ExpenseFormStatus formStatus;
  final Failure? failure;

  const ExpenseFormState({
    this.id,
    this.expenseNumber = '',
    this.expenseCategoryId = 0,
    this.warehouseId,
    this.expenseDate,
    this.description,
    this.amount = 0.0,
    this.paymentMethodId = 0,
    this.vendorName,
    this.referenceNo,
    this.formStatus = ExpenseFormStatus.initial,
    this.failure,
  });

  bool get isEditing => id != null && id! > 0;

  ExpenseDto toDto() {
    return ExpenseDto(
      id: id ?? 0,
      expenseNumber: expenseNumber.trim(),
      expenseCategoryId: expenseCategoryId,
      warehouseId: warehouseId,
      expenseDate: expenseDate ?? DateTime.now(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      amount: amount,
      paymentMethodId: paymentMethodId,
      vendorName: vendorName?.trim().isEmpty == true ? null : vendorName?.trim(),
      referenceNo: referenceNo?.trim().isEmpty == true ? null : referenceNo?.trim(),
      isActive: true,
    );
  }

  ExpenseFormState copyWith({
    int? id,
    String? expenseNumber,
    int? expenseCategoryId,
    int? warehouseId,
    DateTime? expenseDate,
    String? description,
    double? amount,
    int? paymentMethodId,
    String? vendorName,
    String? referenceNo,
    ExpenseFormStatus? formStatus,
    Failure? failure,
  }) {
    return ExpenseFormState(
      id: id ?? this.id,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
      warehouseId: warehouseId ?? this.warehouseId,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      vendorName: vendorName ?? this.vendorName,
      referenceNo: referenceNo ?? this.referenceNo,
      formStatus: formStatus ?? this.formStatus,
      failure: failure ?? this.failure,
    );
  }
}

class ExpenseFormController extends StateNotifier<ExpenseFormState> {
  final ExpenseRepository _repository;
  final Ref _ref;

  ExpenseFormController(this._repository, this._ref)
      : super(ExpenseFormState(
          expenseDate: DateTime.now(),
          expenseNumber: 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        ));

  void initForCreate() {
    state = ExpenseFormState(
      expenseDate: DateTime.now(),
      expenseNumber: 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
  }

  void initForEdit(ExpenseDto expense) {
    state = ExpenseFormState(
      id: expense.id,
      expenseNumber: expense.expenseNumber,
      expenseCategoryId: expense.expenseCategoryId,
      warehouseId: expense.warehouseId,
      expenseDate: expense.expenseDate,
      description: expense.description,
      amount: expense.amount,
      paymentMethodId: expense.paymentMethodId,
      vendorName: expense.vendorName,
      referenceNo: expense.referenceNo,
      formStatus: ExpenseFormStatus.initial,
    );
  }

  void updateExpenseNumber(String val) => state = state.copyWith(expenseNumber: val);
  void updateCategory(int id) => state = state.copyWith(expenseCategoryId: id);
  void updateWarehouse(int? id) => state = state.copyWith(warehouseId: id);
  void updateDate(DateTime val) => state = state.copyWith(expenseDate: val);
  void updateDescription(String val) => state = state.copyWith(description: val);
  void updateAmount(double val) => state = state.copyWith(amount: val);
  void updatePaymentMethod(int id) => state = state.copyWith(paymentMethodId: id);
  void updateVendorName(String val) => state = state.copyWith(vendorName: val);
  void updateReferenceNo(String val) => state = state.copyWith(referenceNo: val);

  Future<bool> submit() async {
    if (state.expenseCategoryId <= 0 || state.amount <= 0 || state.paymentMethodId <= 0) {
      state = state.copyWith(
        formStatus: ExpenseFormStatus.error,
        failure: const ValidationFailure('Category, Amount (>0), and Payment Method are required.'),
      );
      return false;
    }

    state = state.copyWith(formStatus: ExpenseFormStatus.submitting, failure: null);

    final dto = state.toDto();
    final result = state.isEditing
        ? await _repository.updateExpense(state.id!, dto)
        : await _repository.createExpense(dto);

    return result.when(
      success: (_) {
        state = state.copyWith(formStatus: ExpenseFormStatus.success);
        _ref.invalidate(expensesListProvider);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(formStatus: ExpenseFormStatus.error, failure: failure);
        return false;
      },
    );
  }
}

final expenseFormControllerProvider =
    StateNotifierProvider.autoDispose<ExpenseFormController, ExpenseFormState>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return ExpenseFormController(repo, ref);
});
