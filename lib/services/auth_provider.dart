// lib/services/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'otp_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final OtpService _otpService = OtpService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // Tiện ích nhanh: SĐT đã xác minh chưa?
  bool get isPhoneVerified => _currentUser?.phoneVerified ?? false;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      _currentUser = await _authService.getUserData(firebaseUser.uid);
    }
    _isInitialized = true;
    notifyListeners();
  }

  // ─── ĐĂNG KÝ ───────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── ĐĂNG NHẬP ─────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.login(email: email, password: password);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── ĐĂNG XUẤT (xóa device flag để lần sau phải OTP lại) ───
  Future<void> logout() async {
    await _otpService.clearDeviceVerified(); // ← xóa flag thiết bị
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // ─── QUÊN MẬT KHẨU ─────────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── CẬP NHẬT phoneVerified LOCAL (sau khi verify xong) ────
  void markPhoneVerified() {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(phoneVerified: true);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() => _clearError();
}