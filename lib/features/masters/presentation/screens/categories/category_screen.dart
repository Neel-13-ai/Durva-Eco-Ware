import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/master_form_controllers.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/category_dto.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {CategoryDto? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final codeCtrl = TextEditingController(text: category?.code ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    CategoryType selectedType = category?.type ?? CategoryType.general;
    bool isActive = category?.isActive ?? true;
    String? nameError;
    String? dialogError;
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogError!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Category Name *',
                    border: const OutlineInputBorder(),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) {
                      setState(() => nameError = null);
                    }
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()),
                ),
                const SizedBox(height: Spacing.sm),
                DropdownButtonFormField<CategoryType>(
                  isExpanded: true,
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: CategoryType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase(), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  activeThumbColor: BrandColors.primary,
                  onChanged: (v) => setState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        setState(() => nameError = 'Category name is required');
                        return;
                      }

                      setState(() {
                        isSaving = true;
                        dialogError = null;
                      });

                      final dto = CategoryDto(
                        id: category?.id ?? 0,
                        name: name,
                        code: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        type: selectedType,
                        isActive: isActive,
                      );

                      final ok = await ref
                          .read(categoryFormControllerProvider.notifier)
                          .save(dto, isEditing: category != null);

                      if (ok && dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(category == null
                                  ? 'Category created successfully!'
                                  : 'Category updated successfully!'),
                              backgroundColor: BrandColors.primary,
                            ),
                          );
                        }
                      } else {
                        final err = ref.read(categoryFormControllerProvider).error?.toString() ??
                            'Failed to save category. Please check backend connection.';
                        if (dialogCtx.mounted) {
                          setState(() {
                            isSaving = false;
                            dialogError = err;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CategoryDto cat) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete category "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref.read(categoryFormControllerProvider.notifier).delete(cat.id);
              if (context.mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category "${cat.name}" deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final err = ref.read(categoryFormControllerProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete category: $err'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Master'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.refresh(categoriesListProvider),
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: Text('No categories found. Tap + to create one.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: BrandColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.category, color: BrandColors.primary, size: 20),
                    ),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${cat.type.name.toUpperCase()}${cat.code != null ? ' • Code: ${cat.code}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                          tooltip: 'Edit Category',
                          onPressed: () => _showCategoryDialog(context, ref, category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          tooltip: 'Delete Category',
                          onPressed: () => _confirmDelete(context, ref, cat),
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
