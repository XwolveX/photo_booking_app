// lib/screens/shared/public_profile_screen.dart
// Trang profile công khai của người dùng khác

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../chat/chat_screen.dart';
import 'post_Detail_Screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String? heroTag;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.heroTag,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _chatLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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

  Future<void> _openChat(UserModel other) async {
    final me = context.read<AuthProvider>().currentUser;
    if (me == null) return;
    if (me.uid == other.uid) return;

    setState(() => _chatLoading = true);
    try {
      final chatId = await ChatService.getOrCreateChat(
        me: me,
        otherId: other.uid,
        otherName: other.fullName,
        otherRole: other.role.name,
        otherAvatar: other.avatarUrl,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserId: other.uid,
              otherUserName: other.fullName,
              otherUserAvatar: other.avatarUrl,
              otherUserRole: other.role.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = context.read<AuthProvider>().currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Không tìm thấy người dùng')),
          );
        }

        final user = UserModel.fromFirestore(
            snap.data!.data() as Map<String, dynamic>, widget.userId);
        final color = _roleColor(user.role);
        final isMe = myUid == widget.userId;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildAppBar(isDark, user, color),
              _buildHeaderInfo(isDark, user, color, isMe),
              _buildTabBarSliver(isDark, color),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _PostsGrid(uid: user.uid, color: color, isDark: isDark),
                _ServicesList(uid: user.uid, color: color, isDark: isDark, user: user, onChat: () => _openChat(user)),
              ],
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(bool isDark, UserModel user, Color color) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(user.fullName,
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17)),
      actions: [
        IconButton(
          icon: Icon(Icons.more_horiz_rounded,
              color: isDark ? Colors.white54 : Colors.grey),
          onPressed: () {},
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildHeaderInfo(
      bool isDark, UserModel user, Color color, bool isMe) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar + Stats
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Avatar
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
            const SizedBox(width: 28),
            // Stats
            Expanded(child: _buildStats(isDark, user, color)),
          ]),
          const SizedBox(height: 12),

          // Name + role badge
          Row(children: [
            Text(user.fullName,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 15,
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
            // Rating
            if ((user.rating ?? 0) > 0) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(user.rating!.toStringAsFixed(1),
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ]),

          // Bio
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(user.bio!,
                style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                    fontSize: 13,
                    height: 1.4)),
          ],

          const SizedBox(height: 12),

          // Action buttons (chỉ hiện khi không phải mình)
          if (!isMe)
            Row(children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _chatLoading
                      ? null
                      : () async {
                    final me = context.read<AuthProvider>().currentUser;
                    if (me != null) await _openChat(user);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Center(
                      child: _chatLoading
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.chat_bubble_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        const Text('Nhắn tin',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text('Theo dõi',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              ),
            ]),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Widget _buildStats(bool isDark, UserModel user, Color color) {
    // Chỉ query posts (public) — không query bookings của người khác (permission denied)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, postSnap) {
        final posts = postSnap.data?.docs.length ?? 0;
        final rating = user.rating ?? 0.0;
        final totalBookings = user.totalBookings ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatCol(value: '$posts', label: 'Bài viết', isDark: isDark),
            _StatCol(value: '$totalBookings', label: 'Booking', isDark: isDark),
            _StatCol(
              value: rating > 0 ? rating.toStringAsFixed(1) : '—',
              label: 'Đánh giá',
              isDark: isDark,
              icon: rating > 0 ? Icons.star_rounded : null,
            ),
          ],
        );
      },
    );
  }

  SliverPersistentHeader _buildTabBarSliver(bool isDark, Color color) {
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
          tabs: const [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.grid_view_rounded, size: 17),
                SizedBox(width: 5),
                Text('Bài viết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.design_services_rounded, size: 17),
                SizedBox(width: 5),
                Text('Dịch vụ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Column ──────────────────────────────────────────────
class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final IconData? icon;

  const _StatCol({required this.value, required this.label, required this.isDark, this.icon});

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

// ── Posts Grid ────────────────────────────────────────────────
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.grid_view_rounded, size: 48, color: color.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('Chưa có bài viết nào',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
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
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: post),
                  )),
              child: Stack(fit: StackFit.expand, children: [
                post.coverImageUrl != null
                    ? Image.network(post.coverImageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: color.withOpacity(0.1),
                        child: Icon(Icons.article_rounded,
                            color: color.withOpacity(0.3), size: 28)))
                    : Container(
                    color: color.withOpacity(0.1),
                    child: Icon(Icons.article_rounded,
                        color: color.withOpacity(0.3), size: 28)),
                Positioned(
                  bottom: 0, left: 0, right: 0,
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
                  bottom: 5, left: 6,
                  child: Row(children: [
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 11),
                    const SizedBox(width: 3),
                    Text('${post.likeCount}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

// ── Services List ─────────────────────────────────────────────
class _ServicesList extends StatelessWidget {
  final String uid;
  final Color color;
  final bool isDark;
  final UserModel user;
  final VoidCallback onChat;

  const _ServicesList({
    required this.uid,
    required this.color,
    required this.isDark,
    required this.user,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('providerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: color));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.design_services_rounded, size: 48, color: color.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('Chưa có dịch vụ nào',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final name = data['name'] as String? ?? '';
            final desc = data['description'] as String? ?? '';
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            final priceStr = price > 0
                ? '${_fmt(price.toInt())}đ'
                : 'Liên hệ';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.inputFill : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.design_services_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
                              fontSize: 12,
                              height: 1.4)),
                    ],
                    const SizedBox(height: 6),
                    Text(priceStr,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w800, fontSize: 15)),
                  ]),
                ),
                const SizedBox(width: 8),
                // Nút nhắn tin
                GestureDetector(
                  onTap: onChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Hỏi giá',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  String _fmt(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

// ── Tab Header Delegate ───────────────────────────────────────
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