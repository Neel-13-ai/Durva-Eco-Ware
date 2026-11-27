import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/master_form_controllers.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/unit_dto.dart';
import 'package:durvaeco/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitScreen extends ConsumerWidget {
  const UnitScreen({super.key});

  void _showUnitSheet(BuildContext context, WidgetRef ref, {UnitDto? unit}) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SemanticColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      builder: (_) => _UnitFormSheet(
        unit: unit,
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

  void _confirmDelete(BuildContext context, WidgetRef ref, UnitDto unit) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        title: const Text('Delete Unit'),
        content: Text(
          'Are you sure you want to delete "${unit.name}" (${unit.symbol})? This action cannot be undone.',
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
              final ok = await ref.read(unitFormControllerProvider.notifier).delete(unit.id);
              if (!context.mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unit "${unit.name}" deleted.'),
                    backgroundColor: SemanticColors.success,
                  ),
                );
              } else {
                final err = ref.read(unitFormControllerProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete unit: $err'),
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
    final unitsAsync = ref.watch(unitsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Units of Measure'),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.onPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.xs),
            child: IconButton(
              onPressed: () => _showUnitSheet(context, ref),
              tooltip: 'Add Unit',
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
        onRefresh: () => ref.refresh(unitsListProvider.future),
        child: unitsAsync.when(
          data: (units) {
            if (units.isEmpty) {
              return _EmptyUnitsView(
                onAdd: () => _showUnitSheet(context, ref),
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
              itemCount: units.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final u = units[index];
                return _UnitRow(
                  unit: u,
                  onEdit: () => _showUnitSheet(context, ref, unit: u),
                  onDelete: () => _confirmDelete(context, ref, u),
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
                        'Could not load units',
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
                        onPressed: () => ref.invalidate(unitsListProvider),
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

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.onEdit,
    required this.onDelete,
  });

  final UnitDto unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                    color: BrandColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unit.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: BrandColors.secondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: SemanticColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unit.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: unit.isActive
                              ? SemanticColors.textMuted
                              : SemanticColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: SemanticColors.textMuted,
                  ),
                  tooltip: 'Edit Unit',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: SemanticColors.danger,
                  ),
                  tooltip: 'Delete Unit',
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

class _EmptyUnitsView extends StatelessWidget {
  const _EmptyUnitsView({required this.onAdd});

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
                  Icons.straighten_outlined,
                  size: 28,
                  color: BrandColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.md),
              const Text(
                'No units yet',
                style: TextStyle(
                  fontSize: FontSizes.subtitle,
                  fontWeight: FontWeight.w600,
                  color: SemanticColors.text,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              const Text(
                'Add units of measure like Kilogram, Piece, or Bundle to use across products and orders.',
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
                label: const Text('Add Unit'),
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

class _UnitFormSheet extends ConsumerStatefulWidget {
  const _UnitFormSheet({
    required this.onSaved,
    this.unit,
  });

  final UnitDto? unit;
  final void Function(String message) onSaved;

  @override
  ConsumerState<_UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends ConsumerState<_UnitFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _symbolCtrl;
  late bool _isActive;
  String? _nameError;
  String? _symbolError;
  String? _sheetError;

  bool get _isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.unit?.name ?? '');
    _symbolCtrl = TextEditingController(text: widget.unit?.symbol ?? '');
    _isActive = widget.unit?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _symbolCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final symbol = _symbolCtrl.text.trim();
    bool hasError = false;

    if (name.isEmpty) {
      setState(() => _nameError = 'Unit name is required');
      hasError = true;
    }
    if (symbol.isEmpty) {
      setState(() => _symbolError = 'Symbol is required');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _sheetError = null);

    final dto = UnitDto(
      id: widget.unit?.id ?? 0,
      name: name,
      symbol: symbol,
      isActive: _isActive,
    );

    final ok = await ref
        .read(unitFormControllerProvider.notifier)
        .save(dto, isEditing: _isEditing);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      widget.onSaved(
        _isEditing ? 'Unit updated successfully.' : 'Unit created successfully.',
      );
    } else {
      final err = ref.read(unitFormControllerProvider).error;
      setState(() {
        _sheetError = err?.toString() ?? 'Failed to save unit';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(unitFormControllerProvider).isLoading;
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
                    _isEditing ? 'Edit Unit' : 'Add Unit',
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
                padding: const EdgeInsets.all(Spacing.sm + 4),
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
                labelText: 'Unit Name *',
                hintText: 'e.g. Kilogram, Piece, Bundle',
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
            TextField(
              controller: _symbolCtrl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!saving) _submit();
              },
              decoration: InputDecoration(
                labelText: 'Symbol *',
                hintText: 'e.g. Kg, Pcs, Bdl',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                errorText: _symbolError,
              ),
              onChanged: (_) {
                if (_symbolError != null) setState(() => _symbolError = null);
              },
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
                  'Inactive units are hidden from dropdowns',
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
                        _isEditing ? 'Save Changes' : 'Add Unit',
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
