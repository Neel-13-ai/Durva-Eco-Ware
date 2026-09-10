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

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Category Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()),
                ),
                const SizedBox(height: Spacing.sm),
                DropdownButtonFormField<CategoryType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: CategoryType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
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
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final dto = CategoryDto(
                  id: category?.id ?? 0,
                  name: nameCtrl.text.trim(),
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
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(categoriesListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found. Tap + to create one.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(categoriesListProvider),
            child: ListView.separated(
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
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showCategoryDialog(context, ref, category: cat),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
