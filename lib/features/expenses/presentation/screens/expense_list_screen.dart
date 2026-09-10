import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/expenses/application/expense_providers.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';
import 'package:durvaeco/features/expenses/presentation/screens/expense_category_screen.dart';
import 'package:durvaeco/features/expenses/presentation/screens/expense_form_screen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  int? _selectedCategoryId;
  String _search = '';

  Widget _buildMetric(String label, String val, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesListProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Expense Categories',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ExpenseCategoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(expensesListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ExpenseFormScreen()),
          );
        },
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: expensesAsync.when(
        data: (List<ExpenseDto> allExpenses) {
          final filtered = allExpenses.where((e) {
            final matchesSearch = _search.isEmpty ||
                e.expenseNumber.toLowerCase().contains(_search.toLowerCase()) ||
                (e.vendorName?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
                (e.categoryName?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
                (e.description?.toLowerCase().contains(_search.toLowerCase()) ?? false);

            if (!matchesSearch) return false;
            if (_selectedCategoryId != null && e.expenseCategoryId != _selectedCategoryId) return false;
            return true;
          }).toList();

          final totalExpenseAmount = allExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final avgExpense = allExpenses.isNotEmpty ? totalExpenseAmount / allExpenses.length : 0.0;

          return Column(
            children: [
              // Metrics Banner
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                child: Row(
                  children: [
                    _buildMetric('Total Outflow', '₹${totalExpenseAmount.toStringAsFixed(0)}', const Color(0xFFC62828)),
                    _buildMetric('Vouchers Logged', allExpenses.length.toString(), const Color(0xFF1976D2)),
                    _buildMetric('Average / Entry', '₹${avgExpense.toStringAsFixed(0)}', const Color(0xFF673AB7)),
                  ],
                ),
              ),

              // Search & Category Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search expense #, payee, purpose...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                      onChanged: (v) => setState(() => _search = v.trim()),
                    ),
                    const SizedBox(height: Spacing.xs),
                    categoriesAsync.when(
                      data: (cats) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: const Text('All Categories', style: TextStyle(fontSize: 12)),
                                selected: _selectedCategoryId == null,
                                selectedColor: BrandColors.primary,
                                onSelected: (_) => setState(() => _selectedCategoryId = null),
                              ),
                            ),
                            ...cats.map((c) => Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: ChoiceChip(
                                    label: Text(c.categoryName, style: TextStyle(fontSize: 12, color: _selectedCategoryId == c.id ? Colors.white : Colors.black87)),
                                    selected: _selectedCategoryId == c.id,
                                    selectedColor: BrandColors.primary,
                                    onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Expense Voucher List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No expense records matching filter.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                        itemBuilder: (ctx, index) {
                          final exp = filtered[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.md),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(Spacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        exp.expenseNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(4)),
                                        child: Text(
                                          exp.categoryName ?? 'Category #${exp.expenseCategoryId}',
                                          style: const TextStyle(color: Color(0xFF673AB7), fontWeight: FontWeight.bold, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (exp.vendorName != null) ...[
                                    Text('Payee: ${exp.vendorName!}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                  ],
                                  if (exp.description != null) ...[
                                    Text(exp.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Date: ${exp.expenseDate.day}/${exp.expenseDate.month}/${exp.expenseDate.year} • ${exp.paymentMethodName ?? "Paid"}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        '₹${exp.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFC62828)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error loading expenses: $err')),
      ),
    );
  }
}
