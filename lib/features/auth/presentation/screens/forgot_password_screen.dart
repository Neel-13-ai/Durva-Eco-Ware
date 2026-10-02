import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/core/result/result.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _usernameOrEmailCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() {
        _statusMessage = 'New password and confirmation do not match.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    final repo = ref.read(userRepositoryProvider);
    final userIdentifier = _usernameOrEmailCtrl.text.trim();
    final currentPass = _currentPassCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();

    // If numerical ID, use it, else lookup/pass 1
    final userId = int.tryParse(userIdentifier) ?? 1;

    final result = await repo.changePassword(
      userId: userId,
      currentPassword: currentPass,
      newPassword: newPass,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        switch (result) {
          case Success():
            _isSuccess = true;
            _statusMessage = 'Password has been reset successfully! You can now log in with your new password.';
          case Err(failure: final f):
            _isSuccess = false;
            _statusMessage = 'Password reset failed: ${f.message}. If you forgot your current password, please contact the System Administrator.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon & Title
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Color(0xFF1B5E20),
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Forgot / Reset Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your username or user ID along with your temporary PIN or current password to establish a new password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // Status Alert Banner if any
                      if (_statusMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isSuccess ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                color: _isSuccess ? const Color(0xFF2E7D32) : Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _statusMessage!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: _isSuccess ? const Color(0xFF1B5E20) : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Username or Email
                      const Text(
                        'Username or Email',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameOrEmailCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. superadmin or user@durvaeco.com',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Username or Email is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Current / Temp Password
                      const Text(
                        'Current / Temporary Password',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _currentPassCtrl,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          hintText: 'Enter current or temp password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.isEmpty) ? 'Current password is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      const Text(
                        'New Password',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _newPassCtrl,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          hintText: 'Minimum 6 characters',
                          prefixIcon: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF64748B)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'New password is required';
                          if (val.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      const Text(
                        'Confirm New Password',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Re-enter new password',
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF64748B)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Confirmation is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Reset Password',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Back to Login link
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF1B5E20)),
                          label: const Text(
                            'Back to Sign In',
                            style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Divider(height: 32),

                      // Administrator Support Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.headset_mic_outlined, color: Color(0xFF1565C0), size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need Help from Admin?',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Contact Plant IT Administrator at admin@durvaeco.com to request an instant password reset.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
