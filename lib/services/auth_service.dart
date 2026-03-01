// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // ─── ĐĂNG KÝ ───────────────────────────────────────────────
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      // Tạo tài khoản Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Cập nhật displayName
      await user.updateDisplayName(fullName);

      // Tạo UserModel
      final userModel = UserModel(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
      );

      // Lưu vào Firestore collection 'users'
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── ĐĂNG NHẬP ─────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = await getUserData(credential.user!.uid);
      if (userModel == null) throw Exception('Không tìm thấy thông tin người dùng');

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── ĐĂNG XUẤT ─────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── QUÊN MẬT KHẨU ─────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── LẤY THÔNG TIN USER TỪ FIRESTORE ───────────────────────
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, uid);
  }

  // ─── XỬ LÝ LỖI FIREBASE ────────────────────────────────────
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau';
      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại';
    }
  }
}
