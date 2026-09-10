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

          return AlertDialog(
            title: Text(vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  transportersAsync.when(
                    data: (transporters) => DropdownButtonFormField<int>(
                      initialValue: selectedTransporterId,
                      decoration: const InputDecoration(labelText: 'Transporter *', border: OutlineInputBorder()),
                      items: transporters.map((t) => DropdownMenuItem(value: t.id, child: Text(t.transporterName))).toList(),
                      onChanged: (val) => setState(() => selectedTransporterId = val),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading transporters'),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: numCtrl,
                    decoration: const InputDecoration(labelText: 'Vehicle Number * (e.g. MP09AB1234)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: Spacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: vehicleType,
                    decoration: const InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Truck (10 Ton)', child: Text('Truck (10 Ton)')),
                      DropdownMenuItem(value: 'Mini Truck (Tata Ace)', child: Text('Mini Truck (Tata Ace)')),
                      DropdownMenuItem(value: 'Container (20 Ft)', child: Text('Container (20 Ft)')),
                      DropdownMenuItem(value: 'Pickup (1.5 Ton)', child: Text('Pickup (1.5 Ton)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => vehicleType = val);
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
                  if (numCtrl.text.trim().isEmpty || selectedTransporterId == null) return;
                  final dto = VehicleDto(
                    id: vehicle?.id ?? 0,
                    transporterId: selectedTransporterId!,
                    vehicleNumber: numCtrl.text.trim().toUpperCase(),
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
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(vehiclesListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        onPressed: () => _showVehicleDialog(context, ref),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(
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
            );
          }
          return ListView.separated(
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
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showVehicleDialog(context, ref, vehicle: v),
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
