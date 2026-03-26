// lib/screens/auth/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'email_otp_screen.dart';
import 'phone_verify_screen.dart';
import '../user/user_main_screen.dart';
import '../photographer/photographer_main_screen.dart';
import '../makeuper/makeuper_main_screen.dart';
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
  bool _hasNavigated = false;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── FIX: check OTP trước khi vào Home ────────────────────────
  Future<void> _navigate(AuthProvider authProvider) async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    // Chưa đăng nhập → Login
    if (!authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final user = authProvider.currentUser!;
    final otpService = OtpService();

    // Kiểm tra thiết bị đã verify email OTP chưa
    final deviceVerified = await otpService.isDeviceVerified();
    if (!mounted) return;

    if (!deviceVerified) {
      // Phải xác minh thiết bị qua email OTP
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(uid: user.uid, email: user.email),
        ),
      );
      return;
    }

    // Thiết bị ok → kiểm tra SĐT
    if (!user.phoneVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PhoneVerifyScreen()),
      );
      return;
    }

    // Tất cả ok → vào Home theo role
    final role = user.role;
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => home),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isInitialized && !_hasNavigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigate(authProvider);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.primary,
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
                  Image.asset(
                    'assets/icons/splash_icon.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SMEE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
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