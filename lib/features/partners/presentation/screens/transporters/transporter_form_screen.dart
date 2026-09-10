import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/controllers/partner_controllers.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/transporter_dto.dart';

class TransporterFormScreen extends ConsumerStatefulWidget {
  const TransporterFormScreen({super.key, this.transporterId});

  final int? transporterId;

  @override
  ConsumerState<TransporterFormScreen> createState() => _TransporterFormScreenState();
}

class _TransporterFormScreenState extends ConsumerState<TransporterFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
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
    _gstCtrl = TextEditingController();

    if (widget.transporterId != null) {
      Future.microtask(() async {
        final transporters = await ref.read(transportersListProvider.future);
        final found = transporters.firstWhere((t) => t.id == widget.transporterId);
        _nameCtrl.text = found.transporterName;
        _codeCtrl.text = found.transporterCode;
        _contactCtrl.text = found.contactPerson ?? '';
        _phoneCtrl.text = found.phone ?? '';
        _emailCtrl.text = found.email ?? '';
        _addressCtrl.text = found.address ?? '';
        _gstCtrl.text = found.gstNumber ?? '';
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
    _gstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(transporterFormControllerProvider);
    final isEditing = widget.transporterId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transporter' : 'New Transporter'),
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
                      final dto = TransporterDto(
                        id: widget.transporterId ?? 0,
                        transporterCode: _codeCtrl.text.trim(),
                        transporterName: _nameCtrl.text.trim(),
                        contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
                        gstNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
                        isActive: _isActive,
                      );

                      final ok = await ref
                          .read(transporterFormControllerProvider.notifier)
                          .save(dto, isEditing: isEditing);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Transporter updated' : 'Transporter saved'),
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
                : Text(isEditing ? 'UPDATE TRANSPORTER' : 'SAVE TRANSPORTER', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                decoration: const InputDecoration(labelText: 'Transporter Name *', hintText: 'ABC Transport Co.', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Transporter name is required' : null,
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(labelText: 'Transporter Code *', hintText: 'TR-001', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Code is required' : null,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _contactCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Person', hintText: 'Mohan Singh', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Phone', hintText: '9822211222', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', hintText: 'logistics@abctransport.com', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Hub / Office Address', hintText: 'Indore Bypass, MP', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
              ),
              const SizedBox(height: Spacing.md),
              TextFormField(
                controller: _gstCtrl,
                decoration: const InputDecoration(labelText: 'GST / Fleet Tax ID', hintText: '23AACFA0123A1Z5', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
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
