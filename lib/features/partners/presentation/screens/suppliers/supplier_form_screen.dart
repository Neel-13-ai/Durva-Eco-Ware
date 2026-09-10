import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/controllers/partner_controllers.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/supplier_dto.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  const SupplierFormScreen({super.key, this.supplierId});

  final int? supplierId;

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _gstCtrl;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _contactCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _gstCtrl = TextEditingController();

    if (widget.supplierId != null) {
      Future.microtask(() async {
        final suppliers = await ref.read(suppliersListProvider.future);
        final found = suppliers.firstWhere((s) => s.id == widget.supplierId);
        _nameCtrl.text = found.supplierName;
        _codeCtrl.text = found.supplierCode;
        _contactCtrl.text = found.contactPerson ?? '';
        _phoneCtrl.text = found.phone ?? '';
        _emailCtrl.text = found.email ?? '';
        _addressCtrl.text = found.address ?? '';
        _cityCtrl.text = found.city ?? '';
        _stateCtrl.text = found.state ?? '';
        _gstCtrl.text = found.taxNumber ?? '';
        setState(() => _isActive = found.isActive);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(supplierFormControllerProvider);
    final isEditing = widget.supplierId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Supplier' : 'New Supplier'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: formState.isLoading
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final dto = SupplierDto(
                        id: widget.supplierId ?? 0,
                        supplierCode: _codeCtrl.text.trim(),
                        supplierName: _nameCtrl.text.trim(),
                        contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
                        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
                        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
                        taxNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
                        isActive: _isActive,
                      );

                      final ok = await ref
                          .read(supplierFormControllerProvider.notifier)
                          .save(dto, isEditing: isEditing);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Supplier updated' : 'Supplier saved'),
                            backgroundColor: BrandColors.primary,
                          ),
                        );
                        context.pop();
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
            ),
            child: formState.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEditing ? 'UPDATE SUPPLIER' : 'SAVE SUPPLIER', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Supplier Name *', hintText: 'Green Globe Enterprises', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Supplier name is required' : null,
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(labelText: 'Supplier Code *', hintText: 'SUP-001', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Code is required' : null,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _contactCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Person', hintText: 'Ramesh Gupta', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone', hintText: '9876543210', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', hintText: 'ramesh@greenglobe.com', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address', hintText: '12, Industrial Area', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City', hintText: 'Indore', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(labelText: 'State', hintText: 'MP', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: _gstCtrl,
                decoration: const InputDecoration(labelText: 'GST / Tax ID', hintText: '23AABFG1403A1Z5', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
              ),
              const SizedBox(height: Spacing.md),
              SwitchListTile(
                title: const Text('Active Status'),
                value: _isActive,
                activeThumbColor: BrandColors.primary,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
