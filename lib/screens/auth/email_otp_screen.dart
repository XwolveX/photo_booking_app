// lib/screens/auth/email_otp_screen.dart
// Sau verify email OTP thành công:
//   - Nếu SĐT chưa verify → PhoneVerifyScreen
//   - Nếu SĐT đã verify rồi → Home thẳng

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../user/user_main_screen.dart';
import '../photographer/photographer_main_screen.dart';
import '../makeuper/makeuper_main_screen.dart';
import 'phone_verify_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final String uid;
  final String email;

  const EmailOtpScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen>
    with SingleTickerProviderStateMixin {
  final OtpService _otpService = OtpService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSending = false;
  String? _errorMsg;
  int _resendCountdown = 0;

  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sendOtp();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() { _isSending = true; _errorMsg = null; });
    try {
      await _otpService.sendEmailOtp(uid: widget.uid, email: widget.email);
      if (!mounted) return;
      setState(() => _resendCountdown = 60);
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpValue.length < 6) return;
    setState(() { _isVerifying = true; _errorMsg = null; });

    try {
      await _otpService.verifyEmailOtp(uid: widget.uid, otp: _otpValue);
      await _otpService.markDeviceVerified();
      if (!mounted) return;

      final user = context.read<AuthProvider>().currentUser!;

      // Nếu SĐT chưa verify → sang PhoneVerifyScreen
      if (!user.phoneVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PhoneVerifyScreen()),
        );
      } else {
        _navigateHome(user.role);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
      _shakeCtrl.forward(from: 0);
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _navigateHome(UserRole role) {
    Widget home;
    switch (role) {
      case UserRole.photographer: home = const PhotographerMainScreen(); break;
      case UserRole.makeuper: home = const MakeuperMainScreen(); break;
      default: home = const UserMainScreen();
    }
    Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (_) => home), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppTheme.accent, size: 40),
                ),
                const SizedBox(height: 24),
                Text('Xác minh thiết bị',
                  style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Đăng nhập từ thiết bị mới.\nMã OTP đã được gửi đến',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(widget.email,
                  style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // OTP boxes với shake animation
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (_, child) {
                    final offset = _shakeCtrl.isAnimating
                        ? 10 * (1 - _shakeCtrl.value) * (_shakeCtrl.value % 0.2 < 0.1 ? 1 : -1)
                        : 0.0;
                    return Transform.translate(offset: Offset(offset, 0), child: child);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => _buildBox(i, isDark)),
                  ),
                ),

                const SizedBox(height: 16),

                if (_errorMsg != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMsg!,
                          style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                    ]),
                  ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _isVerifying || _otpValue.length < 6 ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      disabledBackgroundColor: AppTheme.accent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isVerifying
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Xác minh',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),

                if (_isSending)
                  const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)
                else if (_resendCountdown > 0)
                  Text('Gửi lại sau $_resendCountdown giây',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 13))
                else
                  TextButton(
                    onPressed: _sendOtp,
                    child: const Text('Gửi lại mã OTP',
                        style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBox(int index, bool isDark) {
    return SizedBox(
      width: 46, height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accent, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
          else if (val.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          if (_otpValue.length == 6) _verify();
        },
      ),
    );
  }
}
