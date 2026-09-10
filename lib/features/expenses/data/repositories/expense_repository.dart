import 'dart:convert';
import 'package:durvaeco/core/constants/api_endpoints.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/data/authenticated_api_client.dart';
import 'package:durvaeco/features/expenses/data/models/expense_category_dto.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';

class ExpenseRepository {
  final AuthenticatedApiClient _client;

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
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : [];
        final items = list.map((e) => ExpenseCategoryDto.fromJson(e as Map<String, dynamic>)).toList();
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
        jsonEncode(category.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        return Success(ExpenseCategoryDto.fromJson(data));
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
        jsonEncode(category.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        return Success(ExpenseCategoryDto.fromJson(data));
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
        if (paymentMethodId != null && paymentMethodId > 0) 'paymentMethodId': paymentMethodId.toString(),
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
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : [];
        final items = list.map((e) => ExpenseDto.fromJson(e as Map<String, dynamic>)).toList();
        return Success(items);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  Future<Result<ExpenseDto>> getById(int id) async {
    try {
      final response = await _client.invokeAPI(
        '${ApiEndpoints.expenses}/$id',
        'GET',
        {'Content-Type': 'application/json'},
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        return Success(ExpenseDto.fromJson(data));
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
        jsonEncode(expense.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        return Success(ExpenseDto.fromJson(data));
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
        jsonEncode(expense.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map<String, dynamic>
            ? (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : {};
        return Success(ExpenseDto.fromJson(data));
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
        return const Success(true);
      }
      return Err(ServerFailure(response.statusCode, response.body));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
