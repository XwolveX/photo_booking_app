// lib/screens/auth/phone_verify_screen.dart
// Hiển thị sau email OTP, nếu tài khoản chưa verify SĐT (1 lần duy nhất)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_provider.dart' as ap;
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../user/user_main_screen.dart';
import '../photographer/photographer_main_screen.dart';
import '../makeuper/makeuper_main_screen.dart';

class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  final OtpService _otpService = OtpService();
  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  // Các bước: 0 = nhập SĐT, 1 = nhập OTP
  int _step = 0;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMsg;
  String? _verificationId;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _otpCtrl) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  /// Chuẩn hoá SĐT: "0901234567" → "+84901234567"
  String _normalizePhone(String phone) {
    phone = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('0')) {
      return '+84${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      return '+84$phone';
    }
    return phone;
  }

  Future<void> _sendSmsOtp() async {
    final rawPhone = _phoneCtrl.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập số điện thoại');
      return;
    }

    final phone = _normalizePhone(rawPhone);
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });

    await _otpService.sendPhoneOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _step = 1;
          _isSending = false;
          _resendCountdown = 60;
        });
        _startCountdown();
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _errorMsg = err;
          _isSending = false;
        });
      },
      onAutoVerified: (credential) async {
        // Android tự verify → đi thẳng luôn
        if (!mounted) return;
        await _doVerify(credential: credential);
      },
    );
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  String get _smsOtp => _otpCtrl.map((c) => c.text).join();

  Future<void> _verifySmsOtp() async {
    if (_smsOtp.length < 6 || _verificationId == null) return;
    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });

    try {
      final uid = context.read<ap.AuthProvider>().currentUser!.uid;
      await _otpService.verifyPhoneOtp(
        uid: uid,
        verificationId: _verificationId!,
        smsCode: _smsOtp,
      );
      if (!mounted) return;
      // Cập nhật local state
      context.read<ap.AuthProvider>().markPhoneVerified();
      _navigateHome();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
        _isVerifying = false;
      });
      for (final c in _otpCtrl) c.clear();
      _otpFocus[0].requestFocus();
    }
  }

  Future<void> _doVerify({required PhoneAuthCredential credential}) async {
    setState(() => _isVerifying = true);
    try {
      final uid = context.read<ap.AuthProvider>().currentUser!.uid;
      await _otpService.verifyPhoneOtp(
        uid: uid,
        verificationId: credential.verificationId ?? '',
        smsCode: credential.smsCode ?? '',
      );
      if (!mounted) return;
      context.read<ap.AuthProvider>().markPhoneVerified();
      _navigateHome();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
        _isVerifying = false;
      });
    }
  }

  void _navigateHome() {
    final role = context.read<ap.AuthProvider>().currentUser!.role;
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
      (_) => false,
    );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android_rounded,
                      color: Colors.green, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Xác minh số điện thoại',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _step == 0
                      ? 'Xác minh 1 lần để bảo vệ tài khoản.\nSau này bạn không cần làm lại bước này.'
                      : 'Nhập mã OTP vừa được gửi đến\nsố điện thoại của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Step indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(active: _step == 0, done: _step > 0),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 2,
                      color: _step > 0
                          ? Colors.green
                          : Colors.grey.withOpacity(0.3),
                    ),
                    const SizedBox(width: 8),
                    _StepDot(active: _step == 1, done: false),
                  ],
                ),
                const SizedBox(height: 36),

                // Content
                if (_step == 0) _buildPhoneStep(isDark),
                if (_step == 1) _buildOtpStep(isDark),

                // Error
                if (_errorMsg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(
                                color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(bool isDark) {
    return Column(
      children: [
        // Input SĐT
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '0901 234 567',
              hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.grey[400]),
              prefixIcon: const Icon(Icons.phone_outlined,
                  color: Colors.green, size: 22),
              prefixText: '+84  ',
              prefixStyle: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendSmsOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.green.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Gửi mã OTP',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(bool isDark) {
    return Column(
      children: [
        // 6 OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (i) => SizedBox(
              width: 46,
              height: 56,
              child: TextField(
                controller: _otpCtrl[i],
                focusNode: _otpFocus[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && i < 5) {
                    _otpFocus[i + 1].requestFocus();
                  } else if (val.isEmpty && i > 0) {
                    _otpFocus[i - 1].requestFocus();
                  }
                  if (_smsOtp.length == 6) _verifySmsOtp();
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isVerifying || _smsOtp.length < 6
                ? null
                : _verifySmsOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.green.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Xác minh',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Gửi lại / Đổi SĐT
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_resendCountdown > 0)
              Text(
                'Gửi lại sau $_resendCountdown giây',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                    fontSize: 13),
              )
            else
              TextButton(
                onPressed: _isSending ? null : _sendSmsOtp,
                child: const Text('Gửi lại',
                    style: TextStyle(color: Colors.green)),
              ),
            const SizedBox(width: 8),
            const Text('·', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() {
                _step = 0;
                _errorMsg = null;
                for (final c in _otpCtrl) c.clear();
              }),
              child: Text('Đổi số',
                  style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[600])),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: done || active ? Colors.green : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
