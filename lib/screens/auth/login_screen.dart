// lib/screens/auth/login_screen.dart
// UI giữ nguyên 100% — chỉ thêm logic OTP sau khi login thành công

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../user/user_main_screen.dart';
import '../photographer/photographer_main_screen.dart';
import '../makeuper/makeuper_main_screen.dart';
import '../../services/theme_provider.dart';
// ── MỚI: thêm 3 import này ──
import '../../services/otp_service.dart';
import 'email_otp_screen.dart';
import 'phone_verify_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // ── MỚI ──
  final OtpService _otpService = OtpService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── CHỈ THAY HÀM NÀY ─────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng nhập thất bại'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final user = auth.currentUser!;

    // Bước 1: kiểm tra thiết bị đã verify email OTP chưa
    final deviceVerified = await _otpService.isDeviceVerified();
    if (!mounted) return;

    if (!deviceVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(uid: user.uid, email: user.email),
        ),
      );
      return;
    }

    // Bước 2: thiết bị ok → kiểm tra SĐT đã verify chưa
    if (!user.phoneVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PhoneVerifyScreen()),
      );
      return;
    }

    // Bước 3: tất cả ok → vào Home
    _navigateByRole(user.role);
  }

  void _navigateByRole(UserRole role) {
    Widget home;
    switch (role) {
      case UserRole.photographer:
        home = const PhotographerMainScreen();
        break;
      case UserRole.makeuper:
        home = const MakeuperMainScreen();
        break;
      default:
        home = const UserMainScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
          (route) => false,
    );
  }

  // ── PHẦN BUILD GIỮ NGUYÊN HOÀN TOÀN ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [AppTheme.surface, AppTheme.primary]
                    : const [Color(0xFFFFF5F7), Color(0xFFFFE4E9)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(isDark),
                      const SizedBox(height: 40),
                      CustomTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                          if (!v.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordCtrl,
                        label: 'Mật khẩu',
                        hint: '••••••••',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (v.length < 6) return 'Ít nhất 6 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen()),
                          ),
                          child: Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                                color: isDark
                                    ? AppTheme.secondary
                                    : AppTheme.pinkAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) => LoadingButton(
                          isLoading: auth.isLoading,
                          onPressed: _login,
                          label: 'Đăng nhập',
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildDivider(isDark),
                      const SizedBox(height: 32),
                      _buildRegisterPrompt(isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 20,
                  color: isDark ? Colors.amber : Colors.orange,
                ),
                Switch(
                  value: isDark,
                  onChanged: (value) => themeProvider.toggleTheme(),
                  activeColor: AppTheme.secondary,
                  inactiveThumbColor: AppTheme.pinkPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Image.asset(
            'assets/icons/smee_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Đăng nhập để tiếp tục',
          style: TextStyle(
            color: (isDark ? Colors.white : AppTheme.lightTextPrimary)
                .withOpacity(0.5),
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    final color =
    (isDark ? Colors.white : AppTheme.lightTextPrimary).withOpacity(0.1);
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Chưa có tài khoản?',
            style: TextStyle(
                color: (isDark ? Colors.white : AppTheme.lightTextPrimary)
                    .withOpacity(0.4),
                fontSize: 16),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }

  Widget _buildRegisterPrompt(bool isDark) {
    final color = isDark ? AppTheme.secondary : AppTheme.pinkAccent;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: color,
        ),
        child: const Text(
          'Tạo tài khoản mới',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}