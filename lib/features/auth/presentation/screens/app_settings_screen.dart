import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _appSettings = [];
  List<Map<String, dynamic>> _companySettings = [];
  List<Map<String, dynamic>> _roles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSettings() async {
    setState(() {
      _isLoading = true;
    });

    final repo = ref.read(settingsRepositoryProvider);

    final appRes = await repo.getAppSettings(includeInactive: true);
    final compRes = await repo.getCompanySettings(includeInactive: true);
    final roleRes = await repo.getRoles(includeInactive: true);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (appRes is Success<List<Map<String, dynamic>>>) {
          _appSettings = appRes.value;
        }
        if (compRes is Success<List<Map<String, dynamic>>>) {
          _companySettings = compRes.value;
        }
        if (roleRes is Success<List<Map<String, dynamic>>>) {
          _roles = roleRes.value;
        }
      });
    }
  }

  void _showAppSettingDialog([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final id = item != null ? (item['id'] ?? item['settingId'] ?? 0) : 0;
    final settingId = id is int ? id : int.tryParse(id.toString()) ?? 0;

    final keyCtrl = TextEditingController(text: item != null ? (item['key']?.toString() ?? item['settingKey']?.toString() ?? '') : '');
    final valCtrl = TextEditingController(text: item != null ? (item['value']?.toString() ?? item['settingValue']?.toString() ?? '') : '');
    final descCtrl = TextEditingController(text: item != null ? (item['description']?.toString() ?? '') : '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Setting' : 'New Application Setting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              readOnly: isEdit,
              decoration: const InputDecoration(labelText: 'Setting Key', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: valCtrl,
              decoration: const InputDecoration(labelText: 'Setting Value', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.primary),
            onPressed: () async {
              final k = keyCtrl.text.trim();
              final v = valCtrl.text.trim();
              if (k.isEmpty || v.isEmpty) return;
              Navigator.pop(ctx);
              final repo = ref.read(settingsRepositoryProvider);
              final payload = {'key': k, 'settingKey': k, 'value': v, 'settingValue': v, 'description': descCtrl.text.trim()};

              if (isEdit) {
                await repo.updateAppSetting(settingId, payload);
              } else {
                await repo.createAppSetting(payload);
              }
              await _loadAllSettings();
            },
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showCompanySettingDialog([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final id = item != null ? (item['id'] ?? 0) : 0;
    final compId = id is int ? id : int.tryParse(id.toString()) ?? 0;

    final nameCtrl = TextEditingController(text: item != null ? (item['companyName']?.toString() ?? item['name']?.toString() ?? '') : 'Durva Eco-Ware Pvt Ltd');
    final gstinCtrl = TextEditingController(text: item != null ? (item['gstin']?.toString() ?? '') : '27AABCD1234E1Z5');
    final addressCtrl = TextEditingController(text: item != null ? (item['address']?.toString() ?? '') : 'MIDC Industrial Area, Pune');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Company Profile' : 'New Company Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Company Legal Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: gstinCtrl,
              decoration: const InputDecoration(labelText: 'GSTIN Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Registered Address', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(settingsRepositoryProvider);
              final payload = {
                'companyName': nameCtrl.text.trim(),
                'name': nameCtrl.text.trim(),
                'gstin': gstinCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              };
              if (isEdit) {
                await repo.updateCompanySetting(compId, payload);
              } else {
                await repo.createCompanySetting(payload);
              }
              await _loadAllSettings();
            },
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final id = item != null ? (item['id'] ?? item['roleId'] ?? 0) : 0;
    final roleId = id is int ? id : int.tryParse(id.toString()) ?? 0;

    final nameCtrl = TextEditingController(text: item != null ? (item['name']?.toString() ?? item['roleName']?.toString() ?? '') : '');
    final descCtrl = TextEditingController(text: item != null ? (item['description']?.toString() ?? '') : '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Role' : 'Create New Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Role Name (e.g. AUDITOR)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description & Scope', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.primary),
            onPressed: () async {
              final rName = nameCtrl.text.trim();
              if (rName.isEmpty) return;
              Navigator.pop(ctx);
              final repo = ref.read(settingsRepositoryProvider);
              final payload = {'name': rName, 'roleName': rName, 'description': descCtrl.text.trim()};
              if (isEdit) {
                await repo.updateRole(roleId, payload);
              } else {
                await repo.createRole(payload);
              }
              await _loadAllSettings();
            },
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System & App Settings'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAllSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: 'App Config'),
            Tab(icon: Icon(Icons.business), text: 'Company Profile'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'RBAC Roles'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppSettingsTab(),
                _buildCompanySettingsTab(),
                _buildRolesTab(),
              ],
            ),
    );
  }

  Widget _buildAppSettingsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Key'),
        onPressed: () => _showAppSettingDialog(),
      ),
      body: _appSettings.isEmpty
          ? const Center(child: Text('No application settings found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: _appSettings.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final s = _appSettings[index];
                final id = (s['id'] ?? s['settingId'] ?? 0);
                final sId = id is int ? id : int.tryParse(id.toString()) ?? 0;
                final k = (s['key'] ?? s['settingKey'] ?? '').toString();
                final v = (s['value'] ?? s['settingValue'] ?? '').toString();
                final desc = (s['description'] ?? '').toString();

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.settings_suggest_outlined, color: BrandColors.primary),
                    title: Text(k, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Value: $v ${desc.isNotEmpty ? "($desc)" : ""}', style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showAppSettingDialog(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: () async {
                            final repo = ref.read(settingsRepositoryProvider);
                            await repo.deleteAppSetting(sId);
                            await _loadAllSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCompanySettingsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Add Profile'),
        onPressed: () => _showCompanySettingDialog(),
      ),
      body: _companySettings.isEmpty
          ? Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Set Up Company Profile'),
                onPressed: () => _showCompanySettingDialog(),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: _companySettings.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final c = _companySettings[index];
                final id = (c['id'] ?? 0);
                final compId = id is int ? id : int.tryParse(id.toString()) ?? 0;
                final name = (c['companyName'] ?? c['name'] ?? 'Durva Eco-Ware Pvt Ltd').toString();
                final gstin = (c['gstin'] ?? '27AABCD1234E1Z5').toString();
                final address = (c['address'] ?? 'MIDC Industrial Area, Pune').toString();

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.business, color: Color(0xFF1565C0)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text('GSTIN: $gstin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        Text(address, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showCompanySettingDialog(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: () async {
                            final repo = ref.read(settingsRepositoryProvider);
                            await repo.deleteCompanySetting(compId);
                            await _loadAllSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRolesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_moderator),
        label: const Text('New Role'),
        onPressed: () => _showRoleDialog(),
      ),
      body: _roles.isEmpty
          ? const Center(child: Text('No custom roles defined.'))
          : ListView.separated(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: _roles.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final r = _roles[index];
                final id = (r['id'] ?? r['roleId'] ?? 0);
                final roleId = id is int ? id : int.tryParse(id.toString()) ?? 0;
                final name = (r['name'] ?? r['roleName'] ?? 'ROLE').toString();
                final desc = (r['description'] ?? 'System Security Role').toString();

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF3E5F5),
                      child: Icon(Icons.shield_outlined, color: Color(0xFF6A1B9A)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showRoleDialog(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: () async {
                            final repo = ref.read(settingsRepositoryProvider);
                            await repo.deleteRole(roleId);
                            await _loadAllSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
