import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/controllers/partner_controllers.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/vehicle_dto.dart';
import 'package:durvaeco/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({
    super.key,
    this.vehicleId,
    this.initialVehicle,
  });

  final int? vehicleId;
  final VehicleDto? initialVehicle;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  static const List<String> _standardTypes = [
    'Truck (10 Ton)',
    'Mini Truck (Tata Ace)',
    'Container (20 Ft)',
    'Pickup (1.5 Ton)',
  ];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numCtrl;
  late final TextEditingController _driverCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _capacityCtrl;

  int? _selectedTransporterId;
  String _vehicleType = _standardTypes.first;
  bool _isActive = true;
  bool _loadingExisting = false;
  String? _submitError;

  bool get _isEditing => widget.vehicleId != null && widget.vehicleId! > 0;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVehicle;
    _numCtrl = TextEditingController(text: v?.vehicleNumber ?? '');
    _driverCtrl = TextEditingController(text: v?.driverName ?? '');
    _phoneCtrl = TextEditingController(text: v?.driverPhone ?? '');
    _capacityCtrl = TextEditingController(text: v?.capacity ?? '');
    _selectedTransporterId = v != null && v.transporterId > 0 ? v.transporterId : null;
    _vehicleType = v?.vehicleType ?? _standardTypes.first;
    _isActive = v?.isActive ?? true;

    if (_isEditing && v == null) {
      _loadExistingVehicle();
    }
  }

  Future<void> _loadExistingVehicle() async {
    setState(() => _loadingExisting = true);
    try {
      final list = await ref.read(vehiclesListProvider.future);
      final found = list.where((v) => v.id == widget.vehicleId).firstOrNull;
      if (found != null && mounted) {
        _prefill(found);
      } else if (mounted) {
        final res = await ref.read(vehicleRepositoryProvider).getById(widget.vehicleId!);
        res.when(
          success: (v) {
            if (mounted) _prefill(v);
          },
          failure: (f) {
            if (mounted) setState(() => _submitError = f.message);
          },
        );
      }
    } catch (_) {
      // Handled gracefully if list lookup fails
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  void _prefill(VehicleDto v) {
    _numCtrl.text = v.vehicleNumber;
    _driverCtrl.text = v.driverName ?? '';
    _phoneCtrl.text = v.driverPhone ?? '';
    _capacityCtrl.text = v.capacity ?? '';
    setState(() {
      _selectedTransporterId = v.transporterId > 0 ? v.transporterId : null;
      _vehicleType = v.vehicleType;
      _isActive = v.isActive;
    });
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _driverCtrl.dispose();
    _phoneCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitError = null);

    final dto = VehicleDto(
      id: widget.vehicleId ?? 0,
      transporterId: _selectedTransporterId!,
      vehicleNumber: _numCtrl.text.trim().toUpperCase(),
      driverName: _driverCtrl.text.trim().isEmpty ? null : _driverCtrl.text.trim(),
      driverPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      vehicleType: _vehicleType,
      capacity: _capacityCtrl.text.trim().isEmpty ? null : _capacityCtrl.text.trim(),
      isActive: _isActive,
    );

    final ok = await ref
        .read(vehicleFormControllerProvider.notifier)
        .save(dto, isEditing: _isEditing);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Vehicle updated successfully!' : 'Vehicle added successfully!'),
          backgroundColor: BrandColors.primary,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(vehicleFormControllerProvider).error?.toString() ??
          'Failed to save vehicle. Please try again.';
      setState(() => _submitError = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(vehicleFormControllerProvider);
    final transportersAsync = ref.watch(activeTransportersProvider);

    final availableTypes = _standardTypes.contains(_vehicleType)
        ? _standardTypes
        : [_vehicleType, ..._standardTypes];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (formState.isLoading || _loadingExisting) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                child: formState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Update Vehicle' : 'Save Vehicle',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ),
        ),
      ),
      body: _loadingExisting
          ? const Center(child: CircularProgressIndicator(color: BrandColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  if (_submitError != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: Spacing.md),
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _submitError!,
                              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Section 1: Vehicle Information
                  Card(
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
                          const Text(
                            'Vehicle Information',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.primary,
                            ),
                          ),
                          const SizedBox(height: Spacing.md),

                          // Transporter
                          transportersAsync.when(
                            data: (transporters) {
                              final validTransporterId = transporters.any((t) => t.id == _selectedTransporterId)
                                  ? _selectedTransporterId
                                  : null;
                              return DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: validTransporterId,
                                decoration: const InputDecoration(
                                  labelText: 'Transporter *',
                                  hintText: 'Select transporter',
                                  border: OutlineInputBorder(),
                                ),
                                items: transporters
                                    .map((t) => DropdownMenuItem(
                                          value: t.id,
                                          child: Text(t.transporterName, overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                validator: (val) => val == null ? 'Transporter is required' : null,
                                onChanged: (val) => setState(() => _selectedTransporterId = val),
                              );
                            },
                            loading: () => const ShimmerDropdown(labelText: 'Transporter *'),
                            error: (_, __) => const Text('Error loading transporters', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(height: Spacing.md),

                          // Vehicle Number
                          TextFormField(
                            controller: _numCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Number *',
                              hintText: 'Enter vehicle number',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'Vehicle number is required' : null,
                          ),
                          const SizedBox(height: Spacing.md),

                          // Vehicle Type
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _vehicleType,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Type',
                              hintText: 'Select vehicle type',
                              border: OutlineInputBorder(),
                            ),
                            items: availableTypes
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _vehicleType = val);
                            },
                          ),
                          const SizedBox(height: Spacing.md),

                          // Driver Name
                          TextFormField(
                            controller: _driverCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Driver Name',
                              hintText: 'Enter driver name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: Spacing.md),

                          // Phone Number
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'Enter phone number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: Spacing.md),

                          // Capacity
                          TextFormField(
                            controller: _capacityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Capacity',
                              hintText: 'Enter vehicle capacity',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Section 2: Vehicle Status
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: Spacing.sm),
                            child: Text(
                              'Vehicle Status',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: BrandColors.primary,
                              ),
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: const Text(
                              'Inactive vehicles are hidden from dispatch selection',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            value: _isActive,
                            activeThumbColor: BrandColors.primary,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
