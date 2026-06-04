import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../config/app_theme.dart';
import '../main.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        UserModel? existingUser = await DatabaseService().getUser(user.uid);

        final updatedUser = (existingUser ?? UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: _nameController.text,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        )).copyWith(
          displayName: _nameController.text,
          age: int.tryParse(_ageController.text),
          emergencyPhone: _phoneController.text,
        );

        await DatabaseService().saveUser(updatedUser);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: AppTheme.dangerCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasWarm,
      body: Stack(
        children: [
          // Decorative gradient orbs for glass depth
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.tealSignal.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.vitalEmerald.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.glassSurface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4),
                        border: Border.all(color: AppTheme.glassBorder, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 24,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.tealWhisper,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_pin_rounded,
                                size: 48,
                                color: AppTheme.tealSignal,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hoàn tất hồ sơ',
                              style: AppTheme.headlineMd,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vui lòng cung cấp thêm thông tin để chúng tôi hỗ trợ bạn tốt nhất.',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodySm.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 32),

                            // Họ tên
                            TextFormField(
                              controller: _nameController,
                              style: AppTheme.bodyMd,
                              decoration: _inputDecoration('Họ và Tên', Icons.person_outline),
                              validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập họ tên' : null,
                            ),
                            const SizedBox(height: 16),

                            // Tuổi
                            TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: AppTheme.bodyMd,
                              decoration: _inputDecoration('Tuổi', Icons.cake_outlined),
                              validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tuổi' : null,
                            ),
                            const SizedBox(height: 16),

                            // SĐT khẩn cấp
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: AppTheme.bodyMd,
                              decoration: _inputDecoration('SĐT Khẩn cấp', Icons.emergency_outlined),
                              validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập SĐT khẩn cấp' : null,
                            ),
                            const SizedBox(height: 32),

                            // Submit Button — Teal pill
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.tealSignal,
                                  foregroundColor: AppTheme.textOnAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'Bắt đầu sử dụng',
                                        style: AppTheme.labelBold.copyWith(
                                          color: AppTheme.textOnAccent,
                                          fontSize: 16,
                                        ),
                                      ),
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
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTheme.bodySm.copyWith(color: AppTheme.mutedSteel),
      prefixIcon: Icon(icon, color: AppTheme.mutedSteel),
      filled: true,
      fillColor: AppTheme.canvasWarm,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.charcoalInk.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.tealSignal, width: 1.5),
      ),
    );
  }
}
