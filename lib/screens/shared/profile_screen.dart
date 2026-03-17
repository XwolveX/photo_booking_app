import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../auth/login_screen.dart';
import '../user/booking_history_screen.dart';
import '../shared/create_post_screen.dart';
import '../shared/tag_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final user = context.read<AuthProvider>().currentUser!;
    _nameCtrl = TextEditingController(text: user.fullName);
    _phoneCtrl = TextEditingController(text: user.phone);
    _bioCtrl = TextEditingController(text: user.bio ?? '');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.photographer:
        return AppTheme.rolePhotographer;
      case UserRole.makeuper:
        return AppTheme.roleMakeuper;
      default:
        return AppTheme.roleUser;
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.photographer:
        return Icons.camera_alt_rounded;
      case UserRole.makeuper:
        return Icons.brush_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Họ tên không được để trống', AppTheme.error);
      return;
    }
    setState(() => _isSaving = true);
    final uid = context.read<AuthProvider>().currentUser!.uid;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      });
      if (mounted) {
        setState(() => _isEditing = false);
        _snack('✅ Đã cập nhật thông tin!', AppTheme.success);
      }
    } catch (e) {
      if (mounted) _snack('Lỗi: $e', AppTheme.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Đăng xuất?',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700)),
        content: Text('Bạn sẽ cần đăng nhập lại để tiếp tục.',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authUser = context.watch<AuthProvider>().currentUser;
    if (authUser == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .snapshots(),
      builder: (context, snap) {
        UserModel user = authUser;
        if (snap.hasData && snap.data!.exists) {
          user = UserModel.fromFirestore(
              snap.data!.data() as Map<String, dynamic>, authUser.uid);
          if (!_isEditing) {
            _nameCtrl.text = user.fullName;
            _phoneCtrl.text = user.phone;
            _bioCtrl.text = user.bio ?? '';
          }
        }

        final color = _roleColor(user.role);

        return Scaffold(
          backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
          floatingActionButton: !_isEditing
              ? FloatingActionButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const CreatePostScreen())),
            backgroundColor: color,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 26),
          )
              : null,
          body: _isEditing
              ? _buildEditView(isDark, user, color)
              : _buildProfileView(isDark, user, color),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // PROFILE VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildProfileView(bool isDark, UserModel user, Color color) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        _buildAppBar(isDark, user, color),
        _buildHeaderInfo(isDark, user, color),
        _buildTabBarSliver(isDark, color, user.uid),
      ],
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PostsGrid(uid: user.uid, color: color, isDark: isDark),
          _TaggedGrid(uid: user.uid, color: color, isDark: isDark),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  SliverAppBar _buildAppBar(bool isDark, UserModel user, Color color) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(user.fullName,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          )),
      actions: [
        // Booking history
        IconButton(
          tooltip: 'Lịch sử booking',
          icon: Stack(clipBehavior: Clip.none, children: [
            Icon(Icons.calendar_month_rounded,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                size: 24),
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark ? AppTheme.primary : AppTheme.lightBg,
                      width: 1.5),
                ),
              ),
            ),
          ]),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const BookingHistoryScreen())),
        ),
        // Tag notifications (badge pending count)
        PendingTagBadge(
          uid: user.uid,
          child: IconButton(
            tooltip: 'Thẻ gắn tag',
            icon: Icon(Icons.person_pin_rounded,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                size: 24),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const TagRequestsScreen())),
          ),
        ),
        // Theme toggle
        IconButton(
          icon: Icon(
            context.watch<ThemeProvider>().isDarkMode
                ? Icons.dark_mode
                : Icons.light_mode,
            color: isDark ? Colors.amber : Colors.orange,
            size: 22,
          ),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        // Menu
        PopupMenuButton<String>(
          icon: Icon(Icons.menu_rounded,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary),
          color: isDark ? AppTheme.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'edit') setState(() => _isEditing = true);
            if (v == 'logout') _confirmLogout();
          },
          itemBuilder: (_) => [
            _menuItem(isDark, 'edit', Icons.edit_rounded,
                'Chỉnh sửa trang cá nhân',
                isDark ? Colors.white70 : AppTheme.lightTextPrimary),
            _menuItem(isDark, 'logout', Icons.logout_rounded,
                'Đăng xuất', AppTheme.error),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      bool isDark, String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(color: color, fontSize: 14,
                fontWeight: value == 'logout' ? FontWeight.w600 : FontWeight.normal)),
      ]),
    );
  }

  // ── Header info ────────────────────────────────────────────
  SliverToBoxAdapter _buildHeaderInfo(
      bool isDark, UserModel user, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar + Stats
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _buildAvatar(user, color, isDark),
            const SizedBox(width: 28),
            Expanded(child: _buildStats(isDark, user, color)),
          ]),
          const SizedBox(height: 12),

          // Name + role badge
          Row(children: [
            Text(user.fullName,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_roleIcon(user.role), color: color, size: 10),
                const SizedBox(width: 3),
                Text(user.roleDisplayName,
                    style: TextStyle(
                        color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),

          // Bio
          const SizedBox(height: 4),
          if (user.bio != null && user.bio!.isNotEmpty)
            Text(user.bio!,
                style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                    fontSize: 13,
                    height: 1.4))
          else
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Text('+ Thêm tiểu sử',
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w500)),
            ),

          // Contact
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.email_outlined,
                size: 11,
                color: isDark ? Colors.white38 : Colors.grey[400]),
            const SizedBox(width: 4),
            Text(user.email,
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[500],
                    fontSize: 12)),
          ]),
          if (user.phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.phone_outlined,
                  size: 11,
                  color: isDark ? Colors.white38 : Colors.grey[400]),
              const SizedBox(width: 4),
              Text(user.phone,
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey[500],
                      fontSize: 12)),
            ]),
          ],
          const SizedBox(height: 12),

          // Action buttons
          _buildActionButtons(isDark, user, color),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Widget _buildAvatar(UserModel user, Color color, bool isDark) {
    return Stack(children: [
      Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppTheme.primary : Colors.white),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: user.avatarUrl != null
                ? Image.network(user.avatarUrl!, fit: BoxFit.cover)
                : Container(
                color: color.withOpacity(0.12),
                child: Icon(_roleIcon(user.role), color: color, size: 38)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: GestureDetector(
          onTap: () => _snack('📷 Upload ảnh sắp ra mắt!', Colors.blue),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDark ? AppTheme.primary : Colors.white, width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6)],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 12),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStats(bool isDark, UserModel user, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(
          user.role == UserRole.user
              ? 'userId'
              : user.role == UserRole.photographer
              ? 'photographerId'
              : 'makeuperId',
          isEqualTo: user.uid)
          .snapshots(),
      builder: (context, bookSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('authorId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, postSnap) {
            final bookings = bookSnap.data?.docs ?? [];
            final posts = postSnap.data?.docs ?? [];
            final completed = bookings
                .where((d) => (d.data() as Map)['status'] == 'completed')
                .length;
            final rating = user.rating ?? 0.0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCol(value: '${posts.length}', label: 'Bài viết', isDark: isDark),
                _StatCol(value: '${bookings.length}', label: 'Booking', isDark: isDark),
                _StatCol(
                  value: completed > 0
                      ? '$completed'
                      : rating > 0
                      ? rating.toStringAsFixed(1)
                      : '—',
                  label: completed > 0 ? 'Hoàn thành' : 'Đánh giá',
                  isDark: isDark,
                  icon: rating > 0 && completed == 0
                      ? Icons.star_rounded
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(bool isDark, UserModel user, Color color) {
    return Row(children: [
      Expanded(
        child: _OutlineBtn(
          label: 'Chỉnh sửa trang cá nhân',
          isDark: isDark,
          onTap: () => setState(() => _isEditing = true),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _OutlineBtn(
          label: '🗓 Lịch sử Booking',
          isDark: isDark,
          color: color,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const BookingHistoryScreen())),
        ),
      ),
      const SizedBox(width: 8),
      _SquareBtn(
        icon: Icons.person_add_alt_1_outlined,
        isDark: isDark,
        onTap: () => _snack('📤 Tính năng sắp ra mắt!', Colors.blue),
      ),
    ]);
  }

  // ── TabBar (Bài viết | Được gắn thẻ) ──────────────────────
  SliverPersistentHeader _buildTabBarSliver(
      bool isDark, Color color, String uid) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabHeaderDelegate(
        bgColor: isDark ? AppTheme.primary : AppTheme.lightBg,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: color,
          unselectedLabelColor: isDark ? Colors.white24 : Colors.grey[300],
          indicatorColor: color,
          indicatorWeight: 1.5,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.15),
          tabs: [
            const Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.grid_view_rounded, size: 17),
                SizedBox(width: 5),
                Text('Bài viết',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
            // Tab "Được gắn thẻ" với badge count
            Tab(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('post_tags')
                    .where('taggedUserId', isEqualTo: uid)
                    .where('status', isEqualTo: 'accepted')
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_pin_rounded, size: 17),
                    const SizedBox(width: 5),
                    const Text('Được gắn thẻ',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // EDIT VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildEditView(bool isDark, UserModel user, Color color) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => setState(() => _isEditing = false),
          child: Text('Hủy',
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontWeight: FontWeight.w600)),
        ),
        leadingWidth: 64,
        title: const Text('Chỉnh sửa trang cá nhân',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.secondary))
                : const Text('Lưu',
                style: TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Avatar editor
          Center(
            child: Stack(children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.4)]),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppTheme.primary : Colors.white),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: user.avatarUrl != null
                        ? Image.network(user.avatarUrl!, fit: BoxFit.cover)
                        : Container(
                        color: color.withOpacity(0.12),
                        child: Icon(_roleIcon(user.role),
                            color: color, size: 44)),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _snack('📷 Upload ảnh sắp ra mắt!', Colors.blue),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? AppTheme.primary : Colors.white,
                          width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () =>
                _snack('📷 Upload ảnh sắp ra mắt!', Colors.blue),
            child: Text('Đổi ảnh đại diện',
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),

          // Editable fields
          _EditCard(isDark: isDark, children: [
            _FieldRow(isDark: isDark, color: color,
                label: 'Họ và tên', controller: _nameCtrl,
                keyboardType: TextInputType.name),
            _Divider(isDark: isDark),
            _FieldRow(isDark: isDark, color: color,
                label: 'Số điện thoại', controller: _phoneCtrl,
                keyboardType: TextInputType.phone),
            _Divider(isDark: isDark),
            _FieldRow(isDark: isDark, color: color,
                label: 'Tiểu sử', controller: _bioCtrl,
                maxLines: 4, hint: 'Giới thiệu bản thân...'),
          ]),
          const SizedBox(height: 16),

          // Read-only
          _EditCard(isDark: isDark, children: [
            _ReadRow(isDark: isDark, label: 'Email',
                value: user.email, note: 'Không thể thay đổi'),
            _Divider(isDark: isDark),
            _ReadRow(isDark: isDark, label: 'Vai trò',
                value: user.roleDisplayName, note: 'Cố định'),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// POSTS GRID (3 col, Instagram-style)
// ══════════════════════════════════════════════════════════
class _PostsGrid extends StatelessWidget {
  final String uid;
  final Color color;
  final bool isDark;

  const _PostsGrid({required this.uid, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: color));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _EmptyGrid(
            icon: Icons.grid_view_rounded,
            title: 'Chưa có bài viết nào',
            subtitle: 'Nhấn + để đăng bài đầu tiên',
            isDark: isDark,
            color: color,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1.5,
            mainAxisSpacing: 1.5,
          ),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final post = PostModel.fromFirestore(
                docs[i].data() as Map<String, dynamic>, docs[i].id);
            return _PostThumbnail(post: post, color: color, isDark: isDark);
          },
        );
      },
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  final PostModel post;
  final Color color;
  final bool isDark;

  const _PostThumbnail(
      {required this.post, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      post.coverImageUrl != null
          ? Image.network(post.coverImageUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.5), Colors.transparent],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 5,
        left: 6,
        child: Row(children: [
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 11),
          const SizedBox(width: 3),
          Text('${post.likeCount}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }

  Widget _placeholder() {
    return Container(
      color: color.withOpacity(0.1),
      child: Icon(Icons.article_rounded,
          color: color.withOpacity(0.3), size: 28),
    );
  }
}

// ══════════════════════════════════════════════════════════
// TAGGED GRID — hiển thị bài accepted
// ══════════════════════════════════════════════════════════
class _TaggedGrid extends StatelessWidget {
  final String uid;
  final Color color;
  final bool isDark;

  const _TaggedGrid(
      {required this.uid, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('post_tags')
          .where('taggedUserId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, tagSnap) {
        if (tagSnap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: color));
        }

        final tagDocs = tagSnap.data?.docs ?? [];
        if (tagDocs.isEmpty) {
          return _EmptyGrid(
            icon: Icons.person_pin_rounded,
            title: 'Chưa có bài nào',
            subtitle: 'Bài viết bạn được gắn thẻ và chấp nhận sẽ xuất hiện ở đây',
            isDark: isDark,
            color: color,
          );
        }

        // Fetch post data for each tag
        final postIds = tagDocs.map((d) => d['postId'] as String).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where(FieldPath.documentId, whereIn: postIds)
              .snapshots(),
          builder: (context, postSnap) {
            final posts = postSnap.data?.docs ?? [];
            if (posts.isEmpty) {
              return _EmptyGrid(
                icon: Icons.person_pin_rounded,
                title: 'Không tìm thấy bài viết',
                subtitle: 'Bài viết có thể đã bị xóa',
                isDark: isDark,
                color: color,
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(1),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1.5,
                mainAxisSpacing: 1.5,
              ),
              itemCount: posts.length,
              itemBuilder: (_, i) {
                final post = PostModel.fromFirestore(
                    posts[i].data() as Map<String, dynamic>, posts[i].id);
                return Stack(fit: StackFit.expand, children: [
                  _PostThumbnail(post: post, color: color, isDark: isDark),
                  // Tag indicator
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_pin_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ]);
              },
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final IconData? icon;

  const _StatCol(
      {required this.value, required this.label, required this.isDark, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.amber, size: 13),
          const SizedBox(width: 2),
        ],
        Text(value,
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
    ]);
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Color? color;

  const _OutlineBtn(
      {required this.label, required this.isDark, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: c != null
              ? c.withOpacity(0.1)
              : (isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: c != null
                  ? c.withOpacity(0.4)
                  : (isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.25))),
        ),
        child: Center(
          child: Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: c ??
                      (isDark ? Colors.white : AppTheme.lightTextPrimary),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _SquareBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _SquareBtn(
      {required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.25)),
        ),
        child: Icon(icon,
            size: 16,
            color: isDark ? Colors.white70 : AppTheme.lightTextPrimary),
      ),
    );
  }
}

class _EmptyGrid extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color color;

  const _EmptyGrid(
      {required this.icon, required this.title, required this.subtitle,
        required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color.withOpacity(0.35), size: 34),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 13,
                  height: 1.5)),
        ]),
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _EditCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final bool isDark;
  final Color color;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;

  const _FieldRow(
      {required this.isDark, required this.color, required this.label,
        required this.controller, this.keyboardType, this.maxLines = 1, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.grey[400],
                  fontSize: 13),
              border: InputBorder.none,
              filled: false,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ReadRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final String? note;

  const _ReadRow(
      {required this.isDark, required this.label, required this.value, this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[500],
                  fontSize: 14)),
        ),
        if (note != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(note!,
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey, fontSize: 10)),
          ),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        indent: 16,
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.withOpacity(0.1));
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color bgColor;

  const _TabHeaderDelegate({required this.child, required this.bgColor});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool _) =>
      Container(color: bgColor, child: child);

  @override
  double get maxExtent => 44;
  @override
  double get minExtent => 44;
  @override
  bool shouldRebuild(_TabHeaderDelegate old) => old.bgColor != bgColor;
}