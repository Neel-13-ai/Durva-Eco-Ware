import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/controllers/master_form_controllers.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/masters/data/models/warehouse_dto.dart';
import 'package:durvaeco/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WarehouseScreen extends ConsumerWidget {
  const WarehouseScreen({super.key});

  void _showWarehouseSheet(BuildContext context, {WarehouseDto? warehouse}) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SemanticColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      builder: (_) => _WarehouseFormSheet(
        warehouse: warehouse,
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

  void _confirmDelete(BuildContext context, WidgetRef ref, WarehouseDto wh) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        title: const Text('Delete Warehouse'),
        content: Text(
          'Are you sure you want to delete "${wh.name}" (${wh.code})? This action cannot be undone.',
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
              final ok = await ref.read(warehouseFormControllerProvider.notifier).delete(wh.id);
              if (!context.mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Warehouse "${wh.name}" deleted.'),
                    backgroundColor: SemanticColors.success,
                  ),
                );
              } else {
                final err = ref.read(warehouseFormControllerProvider).error;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete warehouse: $err'),
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
    final warehousesAsync = ref.watch(warehousesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses & Locations'),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.onPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.xs),
            child: IconButton(
              onPressed: () => _showWarehouseSheet(context),
              tooltip: 'Add Warehouse',
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
        onRefresh: () => ref.refresh(warehousesListProvider.future),
        child: warehousesAsync.when(
          data: (warehouses) {
            if (warehouses.isEmpty) {
              return _EmptyWarehousesView(
                onAdd: () => _showWarehouseSheet(context),
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
              itemCount: warehouses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final wh = warehouses[index];
                return _WarehouseRow(
                  warehouse: wh,
                  onEdit: () => _showWarehouseSheet(context, warehouse: wh),
                  onDelete: () => _confirmDelete(context, ref, wh),
                );
              },
            );
          },
          loading: () => const ShimmerList(itemCount: 8, cardHeight: 76),
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
                        'Could not load warehouses',
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
                        onPressed: () => ref.invalidate(warehousesListProvider),
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

class _WarehouseRow extends StatelessWidget {
  const _WarehouseRow({
    required this.warehouse,
    required this.onEdit,
    required this.onDelete,
  });

  final WarehouseDto warehouse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasAddress = warehouse.address != null && warehouse.address!.trim().isNotEmpty;
    final hasPhone = warehouse.contactPhone != null && warehouse.contactPhone!.trim().isNotEmpty;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BrandColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warehouse_outlined,
                    size: 21,
                    color: BrandColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warehouse.name,
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
                            warehouse.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.secondary,
                            ),
                          ),
                          if (hasPhone) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(fontSize: 12, color: SemanticColors.textMuted),
                            ),
                            Flexible(
                              child: Text(
                                warehouse.contactPhone!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: SemanticColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                          if (!warehouse.isActive) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(fontSize: 12, color: SemanticColors.textMuted),
                            ),
                            const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: SemanticColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (hasAddress) ...[
                        const SizedBox(height: 4),
                        Text(
                          warehouse.address!.trim(),
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
                  tooltip: 'Edit Warehouse',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: SemanticColors.danger,
                  ),
                  tooltip: 'Delete Warehouse',
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

class _EmptyWarehousesView extends StatelessWidget {
  const _EmptyWarehousesView({required this.onAdd});

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
                  Icons.warehouse_outlined,
                  size: 28,
                  color: BrandColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.md),
              const Text(
                'No warehouses yet',
                style: TextStyle(
                  fontSize: FontSizes.subtitle,
                  fontWeight: FontWeight.w600,
                  color: SemanticColors.text,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              const Text(
                'Add warehouses or storage locations to track stock balances and dispatches.',
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
                label: const Text('Add Warehouse'),
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

class _WarehouseFormSheet extends ConsumerStatefulWidget {
  const _WarehouseFormSheet({
    required this.onSaved,
    this.warehouse,
  });

  final WarehouseDto? warehouse;
  final void Function(String message) onSaved;

  @override
  ConsumerState<_WarehouseFormSheet> createState() => _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends ConsumerState<_WarehouseFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late bool _isActive;
  String? _nameError;
  String? _codeError;
  String? _sheetError;

  bool get _isEditing => widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.warehouse?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.warehouse?.code ?? '');
    _addressCtrl = TextEditingController(text: widget.warehouse?.address ?? '');
    _phoneCtrl = TextEditingController(text: widget.warehouse?.contactPhone ?? '');
    _isActive = widget.warehouse?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    bool hasError = false;

    if (name.isEmpty) {
      setState(() => _nameError = 'Warehouse name is required');
      hasError = true;
    }
    if (code.isEmpty) {
      setState(() => _codeError = 'Warehouse code is required');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _sheetError = null);

    final dto = WarehouseDto(
      id: widget.warehouse?.id ?? 0,
      name: name,
      code: code,
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      isActive: _isActive,
    );

    final ok = await ref
        .read(warehouseFormControllerProvider.notifier)
        .save(dto, isEditing: _isEditing);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      widget.onSaved(
        _isEditing ? 'Warehouse updated successfully.' : 'Warehouse created successfully.',
      );
    } else {
      final err = ref.read(warehouseFormControllerProvider).error;
      setState(() {
        _sheetError = err?.toString() ?? 'Failed to save warehouse';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(warehouseFormControllerProvider).isLoading;
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
                    _isEditing ? 'Edit Warehouse' : 'Add Warehouse',
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
                labelText: 'Warehouse Name *',
                hintText: 'e.g. Main Factory, Bilimora Unit',
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Code *',
                      hintText: 'e.g. WH-01',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      errorText: _codeError,
                    ),
                    onChanged: (_) {
                      if (_codeError != null || _sheetError != null) {
                        setState(() {
                          _codeError = null;
                          _sheetError = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      hintText: '10-digit number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'Plot / street / area',
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
                  'Inactive warehouses are hidden from dropdowns',
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
                        _isEditing ? 'Save Changes' : 'Add Warehouse',
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
