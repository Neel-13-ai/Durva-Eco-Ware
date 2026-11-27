import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/master_form_controllers.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/category_dto.dart';
import 'package:durvaeco/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  void _showCategorySheet(BuildContext context, {CategoryDto? category}) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SemanticColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      builder: (_) => _CategoryFormSheet(
        category: category,
        onSaved: (message) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: SemanticColors.success,
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CategoryDto cat) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${cat.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SemanticColors.danger,
              foregroundColor: BrandColors.onPrimary,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref.read(categoryFormControllerProvider.notifier).delete(cat.id);
              if (!context.mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Category "${cat.name}" deleted.'),
                    backgroundColor: SemanticColors.success,
                  ),
                );
              } else {
                final err = ref.read(categoryFormControllerProvider).error;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete category: $err'),
                    backgroundColor: SemanticColors.danger,
                  ),
                );
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
        foregroundColor: BrandColors.onPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.xs),
            child: IconButton(
              onPressed: () => _showCategorySheet(context),
              tooltip: 'Add Category',
              icon: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: BrandColors.onPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: BrandColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: SemanticColors.background,
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () => ref.refresh(categoriesListProvider.future),
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return _EmptyCategoriesView(
                onAdd: () => _showCategorySheet(context),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.md,
                Spacing.md,
                Spacing.xl,
              ),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return _CategoryRow(
                  category: cat,
                  onEdit: () => _showCategorySheet(context, category: cat),
                  onDelete: () => _confirmDelete(context, ref, cat),
                );
              },
            );
          },
          loading: () => const ShimmerList(itemCount: 8, cardHeight: 68),
          error: (err, _) {
            final cleanMessage = err.toString().replaceFirst('Exception: ', '');
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.xxl,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 44,
                        color: SemanticColors.danger,
                      ),
                      const SizedBox(height: Spacing.md),
                      const Text(
                        'Could not load categories',
                        style: TextStyle(
                          fontSize: FontSizes.subtitle,
                          fontWeight: FontWeight.w600,
                          color: SemanticColors.text,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        cleanMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: SemanticColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(categoriesListProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.primary,
                          foregroundColor: BrandColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryDto category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _typeLabel(CategoryType t) {
    switch (t) {
      case CategoryType.rawMaterial:
        return 'RAW MATERIAL';
      case CategoryType.packaging:
        return 'PACKAGING';
      case CategoryType.finishedGood:
      case CategoryType.general:
        return 'FINISHED GOOD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRaw = category.type == CategoryType.rawMaterial;
    final hasDescription =
        category.description != null && category.description!.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: SemanticColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SemanticColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (isRaw ? BrandColors.secondary : BrandColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isRaw ? Icons.layers_outlined : Icons.category_outlined,
                    size: 20,
                    color: isRaw ? BrandColors.secondary : BrandColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: SemanticColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            _typeLabel(category.type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isRaw ? BrandColors.secondary : BrandColors.primary,
                            ),
                          ),
                          if (!category.isActive) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 11,
                                color: SemanticColors.textMuted,
                              ),
                            ),
                            const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SemanticColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: SemanticColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: SemanticColors.textMuted,
                  ),
                  tooltip: 'Edit Category',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: SemanticColors.danger,
                  ),
                  tooltip: 'Delete Category',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCategoriesView extends StatelessWidget {
  const _EmptyCategoriesView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xxl,
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Radii.lg),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  size: 28,
                  color: BrandColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.md),
              const Text(
                'No categories yet',
                style: TextStyle(
                  fontSize: FontSizes.subtitle,
                  fontWeight: FontWeight.w600,
                  color: SemanticColors.text,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              const Text(
                'Add categories like Raw Materials, Finished Goods, or Packaging to organize your items.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: SemanticColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: BrandColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({
    required this.onSaved,
    this.category,
  });

  final CategoryDto? category;
  final void Function(String message) onSaved;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late CategoryType _selectedType;
  late bool _isActive;
  String? _nameError;
  String? _sheetError;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _descCtrl = TextEditingController(text: widget.category?.description ?? '');
    final initialType = widget.category?.type ?? CategoryType.finishedGood;
    _selectedType = initialType == CategoryType.general
        ? CategoryType.finishedGood
        : initialType;
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Category name is required');
      return;
    }

    setState(() => _sheetError = null);

    final dto = CategoryDto(
      id: widget.category?.id ?? 0,
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      type: _selectedType,
      isActive: _isActive,
    );

    final ok = await ref
        .read(categoryFormControllerProvider.notifier)
        .save(dto, isEditing: _isEditing);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      widget.onSaved(
        _isEditing ? 'Category updated successfully.' : 'Category created successfully.',
      );
    } else {
      final err = ref.read(categoryFormControllerProvider).error;
      setState(() {
        _sheetError = err?.toString() ?? 'Failed to save category';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(categoryFormControllerProvider).isLoading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: Spacing.md),
                decoration: BoxDecoration(
                  color: SemanticColors.border,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit Category' : 'Add Category',
                    style: const TextStyle(
                      fontSize: FontSizes.subtitle,
                      fontWeight: FontWeight.w700,
                      color: SemanticColors.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: SemanticColors.textMuted),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            if (_sheetError != null)
              Container(
                margin: const EdgeInsets.only(bottom: Spacing.md),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SemanticColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: SemanticColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: SemanticColors.danger,
                      size: 18,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        _sheetError!,
                        style: const TextStyle(
                          color: SemanticColors.danger,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _nameCtrl,
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Category Name *',
                hintText: 'e.g. Finished Plate, 120GSM Paper',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null || _sheetError != null) {
                  setState(() {
                    _nameError = null;
                    _sheetError = null;
                  });
                }
              },
            ),
            const SizedBox(height: Spacing.md),
            DropdownButtonFormField<CategoryType>(
              isExpanded: true,
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Category Type *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: CategoryType.finishedGood,
                  child: Text('Finished Good'),
                ),
                DropdownMenuItem(
                  value: CategoryType.rawMaterial,
                  child: Text('Raw Material'),
                ),
                DropdownMenuItem(
                  value: CategoryType.packaging,
                  child: Text('Packaging'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Material(
              color: SemanticColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                side: const BorderSide(color: SemanticColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                title: const Text(
                  'Active',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Inactive categories are hidden from dropdowns',
                  style: TextStyle(fontSize: 12, color: SemanticColors.textMuted),
                ),
                value: _isActive,
                activeThumbColor: BrandColors.primary,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: BrandColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BrandColors.onPrimary,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Add Category',
                        style: const TextStyle(
                          fontSize: FontSizes.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
