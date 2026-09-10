import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/expenses/application/expense_providers.dart';
import 'package:durvaeco/features/expenses/data/models/expense_category_dto.dart';

class ExpenseCategoryScreen extends ConsumerStatefulWidget {
  const ExpenseCategoryScreen({super.key});

  @override
  ConsumerState<ExpenseCategoryScreen> createState() => _ExpenseCategoryScreenState();
}

class _ExpenseCategoryScreenState extends ConsumerState<ExpenseCategoryScreen> {
  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Expense Category', style: TextStyle(color: BrandColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Category Name *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final cat = ExpenseCategoryDto(
                id: 0,
                categoryName: name,
                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              );

              final repo = ref.read(expenseRepositoryProvider);
              final result = await repo.createCategory(cat);
              if (result.isSuccess && ctx.mounted) {
                Navigator.of(ctx).pop();
                ref.invalidate(expenseCategoriesProvider);
                ref.invalidate(activeExpenseCategoriesProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense category added!'), backgroundColor: BrandColors.primary),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Category'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(expenseCategoriesProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: BrandColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No expense categories found. Tap "+" to create one.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (ctx, index) {
              final cat = categories[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE7F6),
                    foregroundColor: Color(0xFF673AB7),
                    child: Icon(Icons.receipt_long, size: 20),
                  ),
                  title: Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: cat.description != null ? Text(cat.description!) : null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                    child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
