import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/expenses/data/models/expense_category_dto.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';
import 'package:durvaeco/features/expenses/data/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final client = ref.watch(authenticatedApiClientProvider) as AuthenticatedApiClient;
  return ExpenseRepository(client);
});

final expenseCategoriesProvider = FutureProvider.autoDispose<List<ExpenseCategoryDto>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final result = await repo.getCategories();
  return result.when(
    success: (categories) => categories,
    failure: (failure) => throw Exception(failure.message),
  );
});

final activeExpenseCategoriesProvider = FutureProvider<List<ExpenseCategoryDto>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final result = await repo.getCategories();
  return result.when(
    success: (categories) => categories.where((c) => c.isActive).toList(),
    failure: (failure) => [],
  );
});

final expensesListProvider = FutureProvider.autoDispose<List<ExpenseDto>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final result = await repo.getAll();
  return result.when(
    success: (expenses) => expenses,
    failure: (failure) => throw Exception(failure.message),
  );
});

final expenseDetailProvider = FutureProvider.autoDispose.family<ExpenseDto, int>((ref, id) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (expense) => expense,
    failure: (failure) => throw Exception(failure.message),
  );
});
