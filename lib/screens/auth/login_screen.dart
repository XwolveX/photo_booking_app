// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../user/user_home_screen.dart';
import '../photographer/photographer_home_screen.dart';
import '../makeuper/makeuper_home_screen.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      _navigateByRole(auth.currentUser!.role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng nhập thất bại'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _navigateByRole(UserRole role) {
    Widget home;
    switch (role) {
      case UserRole.photographer:
        home = const PhotographerHomeScreen();
        break;
      case UserRole.makeuper:
        home = const MakeuperHomeScreen();
        break;
      default:
        home = const UserHomeScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.surface, AppTheme.primary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Header
                _buildHeader(),
                const SizedBox(height: 48),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'example@email.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
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
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                          return null;
                        },
                      ),

                      // Quên mật khẩu
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen()),
                          ),
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(color: AppTheme.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Nút đăng nhập
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) => LoadingButton(
                          isLoading: auth.isLoading,
                          onPressed: _login,
                          label: 'Đăng nhập',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Divider
                _buildDivider(),
                const SizedBox(height: 32),

                // Đăng ký
                _buildRegisterPrompt(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 24),
        const Text(
          'Chào mừng\ntrở lại! 👋',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đăng nhập để tiếp tục',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Chưa có tài khoản?',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildRegisterPrompt() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.secondary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: AppTheme.secondary,
        ),
        child: const Text(
          'Tạo tài khoản mới',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
