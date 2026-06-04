import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../config/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isLoginTab = true;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      // AuthWrapper sẽ tự động xử lý route
    } catch (e) {
      _showError('Lỗi đăng nhập Google: $e');
    }
  }

  void _submitPhoneAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isLoginTab) {
        await _authService.signInWithPhoneAndPassword(
          _phoneController.text.trim(),
          _passwordController.text,
        );
      } else {
        await _authService.registerWithPhoneAndPassword(
          _phoneController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      _showError(errorMsg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: AppTheme.bodySm.copyWith(color: AppTheme.textOnAccent)),
          backgroundColor: AppTheme.dangerCoral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasWarm,
      body: Stack(
        children: [
          // Decorative gradient orbs — provide color for glass to frost over
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.tealSignal.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.vitalEmerald.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildGlassCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// App logo and title section — left-aligned feel within centered layout.
  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/app_icon.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        Text(
          'VPC SmartWheel',
          style: AppTheme.headlineLg.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Điều khiển và Giám sát thông minh',
          style: AppTheme.bodySm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Main card with Liquid Glass effect containing tabs and form.
  Widget _buildGlassCard() {
    return ClipRRect(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabs(),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTheme.bodyMd,
                      decoration: _inputDecoration('Số điện thoại', Icons.phone_android),
                      validator: (val) => val == null || val.length < 9 ? 'SĐT không hợp lệ' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTheme.bodyMd,
                      decoration: _inputDecoration(
                        'Mật khẩu',
                        Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.mutedSteel,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => val == null || val.length < 6 ? 'Mật khẩu phải từ 6 ký tự' : null,
                    ),
                    if (!_isLoginTab) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: AppTheme.bodyMd,
                        decoration: _inputDecoration(
                          'Nhập lại mật khẩu',
                          Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.mutedSteel,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                          if (val != _passwordController.text) return 'Mật khẩu không khớp';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Primary CTA — Teal pill button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitPhoneAuth,
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
                                height: 24, width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isLoginTab ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ',
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
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.charcoalInk.withValues(alpha: 0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'HOẶC',
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.charcoalInk.withValues(alpha: 0.1))),
                ],
              ),
              const SizedBox(height: 24),

              // Google sign-in button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 36, color: AppTheme.charcoalInk),
                  label: Text(
                    'Tiếp tục với Google',
                    style: AppTheme.labelBold.copyWith(fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.charcoalInk.withValues(alpha: 0.1)),
                    backgroundColor: AppTheme.pureSurface.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab switcher with active teal pill indicator.
  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.canvasWarm.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem('Đăng nhập', isActive: _isLoginTab, onTap: () {
            setState(() {
              _isLoginTab = true;
              _formKey.currentState?.reset();
            });
          }),
          _buildTabItem('Đăng ký', isActive: !_isLoginTab, onTap: () {
            setState(() {
              _isLoginTab = false;
              _formKey.currentState?.reset();
            });
          }),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, {required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.transitionFast,
          curve: AppTheme.premiumCurve,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.tealSignal : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: isActive
                ? [BoxShadow(color: AppTheme.tealSignal.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.labelBold.copyWith(
                color: isActive ? AppTheme.textOnAccent : AppTheme.mutedSteel,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTheme.bodySm.copyWith(color: AppTheme.mutedSteel, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: AppTheme.mutedSteel),
      suffixIcon: suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.dangerCoral, width: 1.5),
      ),
    );
  }
}
