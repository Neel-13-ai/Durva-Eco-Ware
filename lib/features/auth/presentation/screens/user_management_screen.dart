import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _users = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(userRepositoryProvider);
    final result = await repo.getUsers(includeInactive: true);

    if (mounted) {
      switch (result) {
        case Success<List<Map<String, dynamic>>>(value: final data):
          setState(() {
            _users = data;
            _isLoading = false;
          });
        case Err<List<Map<String, dynamic>>>(failure: final f):
          setState(() {
            _errorMessage = f.message;
            _isLoading = false;
          });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.trim().isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) {
      final name = (u['displayName'] ?? u['fullName'] ?? u['userName'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['roles']?.toString() ?? u['role']?.toString() ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || role.contains(q);
    }).toList();
  }

  void _showUserFormDialog([Map<String, dynamic>? existingUser]) {
    final isEdit = existingUser != null;
    final id = existingUser != null ? (existingUser['id'] ?? existingUser['userId'] ?? 0) : 0;
    final userId = id is int ? id : int.tryParse(id.toString()) ?? 0;

    final nameCtrl = TextEditingController(
      text: existingUser != null ? (existingUser['displayName']?.toString() ?? existingUser['fullName']?.toString() ?? '') : '',
    );
    final emailCtrl = TextEditingController(
      text: existingUser != null ? (existingUser['email']?.toString() ?? existingUser['userName']?.toString() ?? '') : '',
    );
    final passCtrl = TextEditingController();
    String selectedRole = 'USER';
    if (existingUser != null && existingUser['roles'] is List && (existingUser['roles'] as List).isNotEmpty) {
      selectedRole = (existingUser['roles'] as List).first.toString();
    } else if (existingUser != null && existingUser['role'] != null) {
      selectedRole = existingUser['role'].toString();
    }
    bool isActive = existingUser != null ? (existingUser['status']?.toString().toUpperCase() != 'INACTIVE' && existingUser['isActive'] != false) : true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: Spacing.lg,
            left: Spacing.lg,
            right: Spacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit User Account' : 'Create New User',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email / Username',
                    hintText: 'e.g. rahul@durvaeco.com',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!isEdit) ...[
                  const SizedBox(height: Spacing.md),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Initial Password',
                      hintText: 'Minimum 6 characters',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.md),
                DropdownButtonFormField<String>(
                  initialValue: ['ADMIN', 'MANAGER', 'USER', 'OPERATOR'].contains(selectedRole) ? selectedRole : 'USER',
                  decoration: const InputDecoration(
                    labelText: 'Security Role',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrator (Full Access)')),
                    DropdownMenuItem(value: 'MANAGER', child: Text('Plant Manager')),
                    DropdownMenuItem(value: 'OPERATOR', child: Text('Production Operator')),
                    DropdownMenuItem(value: 'USER', child: Text('Standard Staff')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: Spacing.sm),
                SwitchListTile(
                  title: const Text('Account Active'),
                  subtitle: Text(isActive ? 'User can log in' : 'User is deactivated'),
                  value: isActive,
                  activeThumbColor: BrandColors.primary,
                  onChanged: (val) => setModalState(() => isActive = val),
                ),
                const SizedBox(height: Spacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                    ),
                    icon: Icon(isEdit ? Icons.save : Icons.person_add),
                    label: Text(isEdit ? 'Save Changes' : 'Create User'),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      if (name.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      final repo = ref.read(userRepositoryProvider);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      if (isEdit) {
                        final payload = {
                          'id': userId,
                          'displayName': name,
                          'fullName': name,
                          'email': email,
                          'userName': email,
                          'roles': [selectedRole],
                          'role': selectedRole,
                          'status': isActive ? 'ACTIVE' : 'INACTIVE',
                          'isActive': isActive,
                        };
                        final res = await repo.updateUser(userId, payload);
                        if (mounted) {
                          if (res is Success) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('User profile updated successfully')),
                            );
                            await _loadUsers();
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Update failed: ${(res as Err).failure.message}')),
                            );
                          }
                        }
                      } else {
                        final payload = {
                          'displayName': name,
                          'fullName': name,
                          'email': email,
                          'userName': email,
                          'password': passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : 'Durva@123',
                          'roles': [selectedRole],
                          'role': selectedRole,
                          'status': isActive ? 'ACTIVE' : 'INACTIVE',
                          'isActive': isActive,
                        };
                        final res = await repo.createUser(payload);
                        if (mounted) {
                          if (res is Success) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('User account created successfully')),
                            );
                            await _loadUsers();
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Creation failed: ${(res as Err).failure.message}')),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(int userId, String userName) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password for $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'Minimum 6 characters',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.primary),
            onPressed: () async {
              final oldP = oldPassCtrl.text.trim();
              final newP = newPassCtrl.text.trim();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              if (newP.length < 6) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('New password must be at least 6 characters')),
                );
                return;
              }
              Navigator.pop(ctx);
              final repo = ref.read(userRepositoryProvider);
              final res = await repo.changePassword(userId: userId, currentPassword: oldP, newPassword: newP);
              if (mounted) {
                if (res is Success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Password change failed: ${(res as Err).failure.message}')),
                  );
                }
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOrDeactivate(int userId, String userName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Deactivate User'),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate / remove user account "$userName"? This action will revoke their login access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final repo = ref.read(userRepositoryProvider);
              final res = await repo.deleteUser(userId);
              if (mounted) {
                if (res is Success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('User $userName deactivated successfully')),
                  );
                  await _loadUsers();
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Deactivation failed: ${(res as Err).failure.message}')),
                  );
                }
              }
            },
            child: const Text('Deactivate / Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadUsers(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('New User'),
        onPressed: () => _showUserFormDialog(),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or role...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: Spacing.sm),
                            Text('Error: $_errorMessage'),
                            const SizedBox(height: Spacing.md),
                            ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : list.isEmpty
                        ? const Center(
                            child: Text(
                              'No user accounts found',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(Spacing.md),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                            itemBuilder: (context, index) {
                              final u = list[index];
                              final id = (u['id'] ?? u['userId'] ?? 0);
                              final userId = id is int ? id : int.tryParse(id.toString()) ?? 0;
                              final name = (u['displayName'] ?? u['fullName'] ?? u['userName'] ?? 'User #$userId').toString();
                              final email = (u['email'] ?? u['userName'] ?? '').toString();
                              final role = (u['roles'] is List && (u['roles'] as List).isNotEmpty)
                                  ? (u['roles'] as List).join(', ')
                                  : (u['role']?.toString() ?? 'USER');
                              final isActive = u['status']?.toString().toUpperCase() != 'INACTIVE' && u['isActive'] != false;

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Radii.md),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isActive ? BrandColors.primary.withValues(alpha: 0.1) : Colors.grey.shade200,
                                    child: Icon(
                                      Icons.person,
                                      color: isActive ? BrandColors.primary : Colors.grey,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(Radii.pill),
                                        ),
                                        child: Text(
                                          isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? const Color(0xFF2E7D32) : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Role: $role',
                                        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _showUserFormDialog(u);
                                      } else if (action == 'password') {
                                        _showChangePasswordDialog(userId, name);
                                      } else if (action == 'delete') {
                                        _confirmDeleteOrDeactivate(userId, name);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit Profile & Roles'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'password',
                                        child: Row(
                                          children: [
                                            Icon(Icons.lock_reset, size: 18),
                                            SizedBox(width: 8),
                                            Text('Change Password'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_off_outlined, color: Colors.red, size: 18),
                                            SizedBox(width: 8),
                                            Text('Deactivate / Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
