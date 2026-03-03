// lib/screens/auth/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import '../user/user_home_screen.dart';
import '../photographer/photographer_home_screen.dart';
import '../makeuper/makeuper_home_screen.dart';
import '../../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    // Sau 2.5s → điều hướng
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final role = authProvider.currentUser?.role;
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => home),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lấy theme hiện tại
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Nền tự động đổi: Navy hoặc Hồng Pastel
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      // Màu Primary tự đổi (Đỏ hồng ở Dark, Hồng nhạt ở Light)
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      // Màu Icon tương phản với nền nút
                      color: isDark ? Colors.white : Colors.black87,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // TÊN APP
                  Text(
                    'SnapBook',
                    style: theme.textTheme.displayMedium?.copyWith(
                      // Tự lấy màu textPrimary từ AppTheme
                      color: theme.textTheme.displayMedium?.color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // SLOGAN
                  Text(
                    'Kết nối - Sáng tạo - Tỏa sáng',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      // Tự lấy màu textSecondary (Mờ hơn)
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}