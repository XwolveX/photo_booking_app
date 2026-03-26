// lib/models/user_model.dart

enum UserRole { user, photographer, makeuper }

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final String? bio;
  final double? rating;
  final int? totalBookings;
  final DateTime createdAt;

  // ── MỚI: trạng thái xác minh SĐT (1 lần duy nhất / tài khoản) ──
  final bool phoneVerified;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.bio,
    this.rating,
    this.totalBookings,
    required this.createdAt,
    this.phoneVerified = false, // default: chưa xác minh
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.name == data['role'],
        orElse: () => UserRole.user,
      ),
      avatarUrl: data['avatarUrl'],
      bio: data['bio'],
      rating: (data['rating'] as num?)?.toDouble(),
      totalBookings: data['totalBookings'],
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      phoneVerified: data['phoneVerified'] ?? false, // ← MỚI
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'rating': rating ?? 0.0,
      'totalBookings': totalBookings ?? 0,
      'createdAt': createdAt,
      'phoneVerified': phoneVerified, // ← MỚI
    };
  }

  // copyWith để cập nhật riêng lẻ
  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? bio,
    bool? phoneVerified,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      rating: rating,
      totalBookings: totalBookings,
      createdAt: createdAt,
      phoneVerified: phoneVerified ?? this.phoneVerified,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.user:
        return 'Khách hàng';
      case UserRole.photographer:
        return 'Photographer';
      case UserRole.makeuper:
        return 'Makeup Artist';
    }
  }
}