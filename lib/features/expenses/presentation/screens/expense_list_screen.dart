import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/expenses/application/expense_providers.dart';
import 'package:durvaeco/features/expenses/data/models/expense_dto.dart';

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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ExpenseDto exp) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense Voucher?'),
        content: Text(
          'Voucher ${exp.expenseNumber} for ₹${exp.amount.toStringAsFixed(2)} will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Deleting expense voucher...')),
              );
              final result = await ref.read(expenseRepositoryProvider).deleteExpense(exp.id);
              result.when(
                success: (_) {
                  ref.invalidate(expensesListProvider);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Expense deleted successfully'),
                      backgroundColor: BrandColors.primary,
                    ),
                  );
                },
                failure: (err) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: ${err.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
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
            onPressed: () async {
              await context.push('/expenses/categories');
              if (mounted) {
                ref.invalidate(expenseCategoriesProvider);
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          await context.push('/expenses/new');
          if (mounted) {
            ref.invalidate(expensesListProvider);
          }
        },
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.invalidate(expensesListProvider),
        child: expensesAsync.when(
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
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: const Center(child: Text('No expense records matching filter.')),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exp.expenseNumber,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(4)),
                                          child: Text(
                                            exp.categoryName ?? 'Category #${exp.expenseCategoryId}',
                                            style: const TextStyle(color: Color(0xFF673AB7), fontWeight: FontWeight.bold, fontSize: 10),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        tooltip: 'Delete',
                                        padding: const EdgeInsets.only(left: 6),
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showDeleteConfirmation(exp),
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
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Date: ${exp.expenseDate.day}/${exp.expenseDate.month}/${exp.expenseDate.year} • ${exp.paymentMethodName ?? "Paid"}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(child: Text('Error loading expenses: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
