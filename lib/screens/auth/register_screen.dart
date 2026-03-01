// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import '../user/user_home_screen.dart';
import '../photographer/photographer_home_screen.dart';
import '../makeuper/makeuper_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  int _currentStep = 0; // 0 = thông tin, 1 = chọn role
  UserRole? _selectedRole;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _currentStep = 1);
    _slideController.forward(from: 0);
  }

  Future<void> _register() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn vai trò của bạn'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole!,
    );

    if (!mounted) return;

    if (success) {
      _navigateByRole(_selectedRole!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng ký thất bại'),
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
          child: Column(
            children: [
              // AppBar custom
              _buildTopBar(),

              // Progress indicator
              _buildProgressBar(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _currentStep == 0
                      ? _buildStep1()
                      : SlideTransition(
                          position: _slideAnim,
                          child: _buildStep2(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              if (_currentStep == 1) {
                setState(() => _currentStep = 0);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Spacer(),
          Text(
            'Bước ${_currentStep + 1}/2',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: _currentStep >= 1
                    ? AppTheme.secondary
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: Thông tin cơ bản ──────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Tạo tài khoản\ncủa bạn ✨',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Điền thông tin để bắt đầu',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
        ),
        const SizedBox(height: 32),

        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameCtrl,
                label: 'Họ và tên',
                hint: 'Nguyễn Văn A',
                prefixIcon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ tên';
                  if (v.trim().length < 2) return 'Tên quá ngắn';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'example@email.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _phoneCtrl,
                label: 'Số điện thoại',
                hint: '0912 345 678',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập SĐT';
                  if (v.length < 10) return 'Số điện thoại không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _passwordCtrl,
                label: 'Mật khẩu',
                hint: 'Tối thiểu 6 ký tự',
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
                  if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _confirmCtrl,
                label: 'Xác nhận mật khẩu',
                hint: 'Nhập lại mật khẩu',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                  if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _goToStep2,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tiếp theo'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── STEP 2: Chọn Role ─────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Bạn là ai? 🎯',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn vai trò phù hợp với bạn',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
        ),
        const SizedBox(height: 32),

        // Role cards
        _buildRoleCard(
          role: UserRole.user,
          title: 'Khách hàng',
          subtitle: 'Tìm kiếm & đặt lịch chụp hình, makeup',
          icon: Icons.person_rounded,
          color: AppTheme.roleUser,
          features: ['Đặt lịch photographer', 'Đặt lịch makeup artist', 'Chọn địa điểm', 'Nhắn tin trực tiếp'],
        ),
        const SizedBox(height: 16),

        _buildRoleCard(
          role: UserRole.photographer,
          title: 'Photographer',
          subtitle: 'Nhận booking và thể hiện tài năng nhiếp ảnh',
          icon: Icons.camera_alt_rounded,
          color: AppTheme.rolePhotographer,
          features: ['Quản lý lịch chụp', 'Đăng portfolio', 'Nhận thanh toán', 'Chat với khách'],
        ),
        const SizedBox(height: 16),

        _buildRoleCard(
          role: UserRole.makeuper,
          title: 'Makeup Artist',
          subtitle: 'Nhận booking makeup và trang điểm chuyên nghiệp',
          icon: Icons.brush_rounded,
          color: AppTheme.roleMakeuper,
          features: ['Quản lý lịch hẹn', 'Đăng portfolio makeup', 'Nhận thanh toán', 'Chat với khách'],
        ),
        const SizedBox(height: 32),

        Consumer<AuthProvider>(
          builder: (_, auth, __) => LoadingButton(
            isLoading: auth.isLoading,
            onPressed: _register,
            label: 'Hoàn tất đăng ký',
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Check mark
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),

            // Features (hiển thị khi chọn)
            if (isSelected) ...[
              const SizedBox(height: 16),
              Divider(color: color.withOpacity(0.3), height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.map((f) => _buildFeatureChip(f, color)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
