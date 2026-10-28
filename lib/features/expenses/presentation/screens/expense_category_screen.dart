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
  void _showCategoryDialog({ExpenseCategoryDto? category}) {
    final nameCtrl = TextEditingController(text: category?.categoryName ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    String? nameError;
    String? errorMsg;
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text(
              category == null ? 'New Expense Category' : 'Edit Expense Category',
              style: const TextStyle(color: BrandColors.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(errorMsg!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                  ),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Category Name *',
                    border: const OutlineInputBorder(),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) setDialogState(() => nameError = null);
                  },
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
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => nameError = 'Category name is required');
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          errorMsg = null;
                        });

                        final dto = ExpenseCategoryDto(
                          id: category?.id ?? 0,
                          categoryName: name,
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        );

                        final repo = ref.read(expenseRepositoryProvider);
                        final result = category != null
                            ? await repo.updateCategory(category.id, dto)
                            : await repo.createCategory(dto);

                        if (result.isSuccess && ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ref.invalidate(expenseCategoriesProvider);
                          ref.invalidate(activeExpenseCategoriesProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(category == null
                                    ? 'Expense category added!'
                                    : 'Expense category updated!'),
                                backgroundColor: BrandColors.primary,
                              ),
                            );
                          }
                        } else {
                          final err = result.failureOrNull?.message ?? 'Failed to save expense category';
                          if (ctx.mounted) {
                            setDialogState(() {
                              isSaving = false;
                              errorMsg = err;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Category'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(ExpenseCategoryDto cat) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense Category?'),
        content: Text('Are you sure you want to delete category "${cat.categoryName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(expenseRepositoryProvider);
              final result = await repo.deleteCategory(cat.id);
              result.when(
                success: (_) {
                  ref.invalidate(expenseCategoriesProvider);
                  ref.invalidate(activeExpenseCategoriesProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense category deleted successfully!'), backgroundColor: BrandColors.primary),
                    );
                  }
                },
                failure: (err) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete category: ${err.message}'), backgroundColor: Colors.red),
                    );
                  }
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
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showCategoryDialog(),
        backgroundColor: BrandColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.invalidate(expenseCategoriesProvider),
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: Text('No expense categories found. Tap "+" to create one.')),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: BrandColors.primary),
                          tooltip: 'Edit Category',
                          onPressed: () => _showCategoryDialog(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'Delete Category',
                          onPressed: () => _confirmDelete(cat),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
