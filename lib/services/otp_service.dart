// lib/services/otp_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── KEY lưu local: thiết bị này đã verify email OTP chưa ────
  static const _kDeviceVerifiedKey = 'device_email_verified';

  // ────────────────────────────────────────────────────────────
  // EMAIL OTP (login lần đầu trên thiết bị / sau logout)
  // ────────────────────────────────────────────────────────────

  /// Kiểm tra thiết bị hiện tại đã từng verify email OTP chưa
  Future<bool> isDeviceVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDeviceVerifiedKey) ?? false;
  }

  /// Đánh dấu thiết bị đã xác minh
  Future<void> markDeviceVerified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDeviceVerifiedKey, true);
  }

  /// Xóa trạng thái thiết bị khi logout → lần đăng nhập sau phải OTP lại
  Future<void> clearDeviceVerified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDeviceVerifiedKey);
  }

  /// Gửi OTP về email thông qua Cloud Function (Nodemailer)
  Future<void> sendEmailOtp({
    required String uid,
    required String email,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendLoginOTP');
      await callable.call({'uid': uid, 'email': email});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Gửi OTP thất bại');
    }
  }

  /// Xác minh OTP email với Cloud Function
  Future<void> verifyEmailOtp({
    required String uid,
    required String otp,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyLoginOTP');
      await callable.call({'uid': uid, 'otp': otp});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Xác minh OTP thất bại');
    }
  }

  // ────────────────────────────────────────────────────────────
  // PHONE VERIFICATION (1 lần / tài khoản — dùng Firebase Phone Auth)
  // ────────────────────────────────────────────────────────────

  /// Gửi OTP SMS đến số điện thoại
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber, // Phải có +84 prefix: "+84901234567"
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) {
        // Android tự động xác minh SMS
        onAutoVerified?.call(credential);
      },
      verificationFailed: (e) {
        if (e.code == 'invalid-phone-number') {
          onError('Số điện thoại không hợp lệ');
        } else if (e.code == 'too-many-requests') {
          onError('Quá nhiều yêu cầu, thử lại sau');
        } else {
          onError(e.message ?? 'Gửi OTP thất bại');
        }
      },
      codeSent: (verificationId, resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Xác minh OTP SMS → link với tài khoản hiện tại → cập nhật Firestore
  Future<void> verifyPhoneOtp({
    required String uid,
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Link phone credential vào tài khoản Firebase Auth hiện tại
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Chưa đăng nhập');

      try {
        await currentUser.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // Nếu số đã linked trước đó thì bỏ qua lỗi provider-already-linked
        if (e.code != 'provider-already-linked' &&
            e.code != 'credential-already-in-use') {
          rethrow;
        }
      }

      // Cập nhật phoneVerified = true trong Firestore
      await _firestore.collection('users').doc(uid).update({
        'phoneVerified': true,
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw Exception('Mã OTP không đúng');
      } else if (e.code == 'session-expired') {
        throw Exception('Mã OTP đã hết hạn, vui lòng gửi lại');
      }
      throw Exception(e.message ?? 'Xác minh thất bại');
    }
  }
}
