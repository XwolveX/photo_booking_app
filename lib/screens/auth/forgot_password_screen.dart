// lib/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(_emailCtrl.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() => _sent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đã xảy ra lỗi'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Đồng bộ màu nền với Login và Register
            colors: isDark
                ? const [AppTheme.surface, AppTheme.primary]
                : const [Color(0xFFFFF5F7), Color(0xFFFFE4E9)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                IconButton(
                  // Đổi màu icon theo theme
                  icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 32),

                if (_sent) _buildSuccessState(theme) else _buildFormState(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đặt lại\nmật khẩu 🔑',
          // Dùng textTheme để tự động đổi màu chữ Trắng <-> Đen
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập email đã đăng ký, chúng tôi sẽ gửi link đặt lại mật khẩu',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 40),
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
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => LoadingButton(
                  isLoading: auth.isLoading,
                  onPressed: _sendReset,
                  label: 'Gửi email đặt lại',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.success.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                color: AppTheme.success, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Email đã được gửi!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kiểm tra hộp thư của bạn\nvà làm theo hướng dẫn',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại đăng nhập'),
            ),
          ),
        ],
      ),
    );
  }
}