import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/controllers/partner_controllers.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/vehicle_dto.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  void _showVehicleDialog(BuildContext context, WidgetRef ref, {VehicleDto? vehicle}) {
    final numCtrl = TextEditingController(text: vehicle?.vehicleNumber ?? '');
    final driverCtrl = TextEditingController(text: vehicle?.driverName ?? '');
    final phoneCtrl = TextEditingController(text: vehicle?.driverPhone ?? '');
    final capacityCtrl = TextEditingController(text: vehicle?.capacity ?? '');
    String vehicleType = vehicle?.vehicleType ?? 'Truck (10 Ton)';
    int? selectedTransporterId = vehicle?.transporterId;
    bool isActive = vehicle?.isActive ?? true;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final transportersAsync = ref.watch(activeTransportersProvider);
          String? numError;
          String? transporterError;
          String? dialogError;
          bool isSaving = false;

          return StatefulBuilder(
            builder: (ctx, setInnerState) => AlertDialog(
              title: Text(vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
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
                    transportersAsync.when(
                      data: (transporters) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: selectedTransporterId,
                        decoration: InputDecoration(
                          labelText: 'Transporter *',
                          border: const OutlineInputBorder(),
                          errorText: transporterError,
                        ),
                        items: transporters.map((t) => DropdownMenuItem(value: t.id, child: Text(t.transporterName, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          setInnerState(() {
                            selectedTransporterId = val;
                            transporterError = null;
                          });
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading transporters'),
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: numCtrl,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Number * (e.g. MP09AB1234)',
                        border: const OutlineInputBorder(),
                        errorText: numError,
                      ),
                      onChanged: (_) {
                        if (numError != null) setInnerState(() => numError = null);
                      },
                    ),
                    const SizedBox(height: Spacing.sm),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: vehicleType,
                      decoration: const InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Truck (10 Ton)', child: Text('Truck (10 Ton)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'Mini Truck (Tata Ace)', child: Text('Mini Truck (Tata Ace)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'Container (20 Ft)', child: Text('Container (20 Ft)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'Pickup (1.5 Ton)', child: Text('Pickup (1.5 Ton)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) setInnerState(() => vehicleType = val);
                      },
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: driverCtrl,
                      decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Driver Phone', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: capacityCtrl,
                      decoration: const InputDecoration(labelText: 'Capacity (e.g. 5000 Pcs / 10 Tons)', border: OutlineInputBorder()),
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: isActive,
                      activeThumbColor: BrandColors.primary,
                      onChanged: (v) => setInnerState(() => isActive = v),
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
                          final vNum = numCtrl.text.trim();
                          bool hasError = false;

                          if (selectedTransporterId == null) {
                            setInnerState(() => transporterError = 'Transporter is required');
                            hasError = true;
                          }
                          if (vNum.isEmpty) {
                            setInnerState(() => numError = 'Vehicle number is required');
                            hasError = true;
                          }
                          if (hasError) return;

                          setInnerState(() {
                            isSaving = true;
                            dialogError = null;
                          });

                          final dto = VehicleDto(
                            id: vehicle?.id ?? 0,
                            transporterId: selectedTransporterId!,
                            vehicleNumber: vNum.toUpperCase(),
                            driverName: driverCtrl.text.trim().isEmpty ? null : driverCtrl.text.trim(),
                            driverPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                            vehicleType: vehicleType,
                            capacity: capacityCtrl.text.trim().isEmpty ? null : capacityCtrl.text.trim(),
                            isActive: isActive,
                          );

                          final ok = await ref
                              .read(vehicleFormControllerProvider.notifier)
                              .save(dto, isEditing: vehicle != null);

                          if (ok && dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(vehicle == null
                                      ? 'Vehicle added successfully!'
                                      : 'Vehicle updated successfully!'),
                                  backgroundColor: BrandColors.primary,
                                ),
                              );
                            }
                          } else {
                            final err = ref.read(vehicleFormControllerProvider).error?.toString() ??
                                'Failed to save vehicle. Please check backend connection.';
                            if (dialogCtx.mounted) {
                              setInnerState(() {
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
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, VehicleDto vehicle) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete vehicle "${vehicle.vehicleNumber}" (${vehicle.vehicleType})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref.read(vehicleFormControllerProvider.notifier).delete(vehicle.id);
              if (context.mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle "${vehicle.vehicleNumber}" deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final err = ref.read(vehicleFormControllerProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete vehicle: $err'),
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
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet & Vehicles Master'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        onPressed: () => _showVehicleDialog(context, ref),
      ),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async => ref.invalidate(vehiclesListProvider),
        child: vehiclesAsync.when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_filled_outlined, size: 64, color: Color(0xFF94A3B8)),
                          SizedBox(height: Spacing.md),
                          Text('No vehicles registered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Tap + Add Vehicle to assign trucks & drivers to transporters', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: BrandColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.local_shipping, color: BrandColors.primary, size: 20),
                    ),
                    title: Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${v.vehicleType}${v.driverName != null ? " • Driver: ${v.driverName}" : ""}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                          tooltip: 'Edit Vehicle',
                          onPressed: () => _showVehicleDialog(context, ref, vehicle: v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          tooltip: 'Delete Vehicle',
                          onPressed: () => _confirmDelete(context, ref, v),
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
