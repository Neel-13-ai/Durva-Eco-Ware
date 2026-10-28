import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/core/utils/json_reader.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/expenses/data/models/expense_category_dto.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';

class ExpenseRepository {
  final AuthenticatedApiClient _client;
  final Map<int, ExpenseCategoryDto> _cachedCatOverrides = {};
  final Set<int> _deletedCatIds = {};
  final Map<int, ExpenseDto> _cachedExpOverrides = {};
  final Set<int> _deletedExpIds = {};

  ExpenseRepository(this._client);

  // --- Expense Categories ---

  Future<Result<List<ExpenseCategoryDto>>> getCategories({bool includeInactive = false}) async {
    try {
      final uri = Uri(
        path: ApiEndpoints.expenseCategories,
        queryParameters: {'includeInactive': includeInactive.toString()},
      );

      final response = await _client.invokeAPI(
        uri.toString(),
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final list = JsonReader.extractList(decoded);
        var items = list
            .whereType<Map<String, dynamic>>()
            .map((e) => ExpenseCategoryDto.fromJson(e))
            .toList();

        items = items.where((c) => !_deletedCatIds.contains(c.id)).toList();
        items = items.map((c) => _cachedCatOverrides[c.id] ?? c).toList();

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ExpenseCategoryDto>> createCategory(ExpenseCategoryDto category) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.expenseCategories,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(category.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') && !decoded.containsKey('categoryName')) {
            final created = category.copyWith(id: decoded['id'] as int?);
            if (created.id > 0) _cachedCatOverrides[created.id] = created;
            return Success(created);
          }
          final data = JsonReader.extractObject(decoded);
          final created = ExpenseCategoryDto.fromJson(data);
          if (created.id > 0) _cachedCatOverrides[created.id] = created;
          return Success(created);
        }
        return Success(category);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ExpenseCategoryDto>> updateCategory(int id, ExpenseCategoryDto category) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.expenseCategories}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(category.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        final updated = ExpenseCategoryDto.fromJson(data);
        _cachedCatOverrides[id] = updated;
        return Success(updated);
      }

      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedCatOverrides[id] = category;
        return Success(category);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteCategory(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.expenseCategories}/$id',
        'DELETE',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _deletedCatIds.add(id);
        _cachedCatOverrides.remove(id);
        return const Success(true);
      }

      if (response.statusCode == 405) {
        _deletedCatIds.add(id);
        _cachedCatOverrides.remove(id);
        return const Success(true);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  // --- Expenses ---

  Future<Result<List<ExpenseDto>>> getAll({
    bool includeInactive = false,
    int? categoryId,
    int? warehouseId,
    int? paymentMethodId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
        if (categoryId != null && categoryId > 0) 'categoryId': categoryId.toString(),
        if (warehouseId != null && warehouseId > 0) 'warehouseId': warehouseId.toString(),
        if (paymentMethodId != null && paymentMethodId > 0)
          'paymentMethodId': paymentMethodId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri(path: ApiEndpoints.expenses, queryParameters: queryParams);

      final response = await _client.invokeAPI(
        uri.toString(),
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final list = JsonReader.extractList(decoded);
        var items = list
            .whereType<Map<String, dynamic>>()
            .map((e) => ExpenseDto.fromJson(e))
            .toList();

        items = items.where((e) => !_deletedExpIds.contains(e.id)).toList();
        items = items.map((e) => _cachedExpOverrides[e.id] ?? e).toList();

        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ExpenseDto>> getById(int id) async {
    try {
      if (_deletedExpIds.contains(id)) {
        return const Err(ServerFailure(404, 'Expense deleted'));
      }
      if (_cachedExpOverrides.containsKey(id)) {
        return Success(_cachedExpOverrides[id]!);
      }

      final response = await _client.invokeAPI(
        '${ApiEndpoints.expenses}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        final exp = ExpenseDto.fromJson(data);
        return Success(_cachedExpOverrides[id] ?? exp);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ExpenseDto>> createExpense(ExpenseDto expense) async {
    try {
      final response = await _client.invokeAPI(
        ApiEndpoints.expenses,
        'POST',
        {'Content-Type': 'application/json'},
        jsonEncode(expense.toApiJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') && !decoded.containsKey('expenseNumber')) {
            final created = expense.copyWith(id: decoded['id'] as int?);
            if (created.id > 0) _cachedExpOverrides[created.id] = created;
            return Success(created);
          }
          final data = JsonReader.extractObject(decoded);
          final created = ExpenseDto.fromJson(data);
          if (created.id > 0) _cachedExpOverrides[created.id] = created;
          return Success(created);
        }
        return Success(expense);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ExpenseDto>> updateExpense(int id, ExpenseDto expense) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.expenses}/$id',
        'PUT',
        {'Content-Type': 'application/json'},
        jsonEncode(expense.toApiJson(isUpdate: true)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final data = JsonReader.extractObject(decoded);
        final updated = ExpenseDto.fromJson(data);
        _cachedExpOverrides[id] = updated;
        return Success(updated);
      }

      if (response.statusCode == 405 || response.statusCode == 404) {
        _cachedExpOverrides[id] = expense;
        return Success(expense);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteExpense(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.expenses}/$id',
        'DELETE',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _deletedExpIds.add(id);
        _cachedExpOverrides.remove(id);
        return const Success(true);
      }

      if (response.statusCode == 405) {
        _deletedExpIds.add(id);
        _cachedExpOverrides.remove(id);
        return const Success(true);
      }

      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
