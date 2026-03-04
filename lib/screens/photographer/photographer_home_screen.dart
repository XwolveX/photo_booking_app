// lib/screens/photographer/photographer_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/post_model.dart';
import '../auth/login_screen.dart';
import '../shared/create_post_screen.dart';

class PhotographerHomeScreen extends StatefulWidget {
  const PhotographerHomeScreen({super.key});

  @override
  State<PhotographerHomeScreen> createState() =>
      _PhotographerHomeScreenState();
}

class _PhotographerHomeScreenState extends State<PhotographerHomeScreen> {
  bool _isOnline = true;
  int _incomeTab = 1; // 0=Tuần, 1=Tháng, 2=Năm
  static const _roleColor = AppTheme.rolePhotographer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen())),
        backgroundColor: _roleColor,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Viết bài',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark, user?.fullName ?? ''),
          SliverToBoxAdapter(child: _buildStatsRow(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildIncomeCard(isDark)),
          SliverToBoxAdapter(child: _buildSectionTitle('📋 Booking chờ xác nhận', isDark)),
          SliverToBoxAdapter(child: _buildBookingList(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildSectionTitle('📅 Lịch trong tuần', isDark)),
          SliverToBoxAdapter(child: _buildWeekCalendar(isDark)),
          SliverToBoxAdapter(child: _buildSectionTitle('📝 Bài viết của tôi', isDark)),
          SliverToBoxAdapter(child: _buildMyPosts(isDark, user?.uid ?? '')),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark, String name) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: isDark ? Colors.amber : Colors.orange),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        IconButton(
          icon: Icon(Icons.logout,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary),
          onPressed: () => _logout(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(isDark, name),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.surface, const Color(0xFF1A1040)]
              : [const Color(0xFFFFF0F3), const Color(0xFFFFCDD5)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _roleColor, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: _roleColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Studio của bạn 📸',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : AppTheme.lightTextSecondary,
                            fontSize: 12)),
                    Text(name,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
              // Online/Offline
              GestureDetector(
                onTap: () => setState(() => _isOnline = !_isOnline),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: (_isOnline ? AppTheme.success : Colors.grey)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _isOnline ? AppTheme.success : Colors.grey,
                        width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: _isOnline ? AppTheme.success : Colors.grey,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(_isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                            color: _isOnline ? AppTheme.success : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Quản lý booking &\nbài viết của bạn',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3,
              )),
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────
  Widget _buildStatsRow(bool isDark, String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        _statCard('0', 'Hôm\nnay', Icons.today_rounded, _roleColor, isDark),
        const SizedBox(width: 8),
        _statCard('0', 'Chờ xác\nnhận', Icons.pending_rounded, Colors.orange, isDark),
        const SizedBox(width: 8),
        _statCard('0', 'Hoàn\nthành', Icons.check_circle_rounded, AppTheme.success, isDark),
        const SizedBox(width: 8),
        _statCard('0', 'Bài\nviết', Icons.article_rounded, Colors.blue, isDark),
      ]),
    );
  }

  Widget _statCard(String v, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.inputFill : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(v, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 10, height: 1.3)),
        ]),
      ),
    );
  }

  // ── Income Card ───────────────────────────────────────────
  Widget _buildIncomeCard(bool isDark) {
    final tabs = ['Tuần', 'Tháng', 'Năm'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_roleColor, _roleColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _roleColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('💰 Thống kê thu nhập',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            // Tab switcher
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final sel = _incomeTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _incomeTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(tabs[i],
                          style: TextStyle(
                              color: sel ? _roleColor : Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  );
                }),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('0 đ',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            _incomeTab == 0 ? 'Tuần này' : _incomeTab == 1 ? 'Tháng này' : 'Năm nay',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Bar chart placeholder
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: (20 + (i * 5) % 40).toDouble(),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(i == 5 ? 1 : 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('Sẽ cập nhật khi có booking hoàn thành',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ]),
      ),
    );
  }

  // ── Booking List ──────────────────────────────────────────
  Widget _buildBookingList(bool isDark, String uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.inputFill : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12)),
        ),
        child: Column(children: [
          Icon(Icons.inbox_rounded, size: 40, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 10),
          Text('Chưa có booking nào', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Booking mới sẽ hiển thị tại đây', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400], fontSize: 12)),
        ]),
      ),
    );
  }

  // ── Week Calendar ─────────────────────────────────────────
  Widget _buildWeekCalendar(bool isDark) {
    final now = DateTime.now();
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final today = now.weekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(7, (i) {
          final isToday = i == today;
          final d = now.subtract(Duration(days: today - i));
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isToday ? _roleColor : (isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Text(days[i], style: TextStyle(color: isToday ? Colors.white : (isDark ? Colors.white54 : Colors.grey), fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${d.day}', style: TextStyle(color: isToday ? Colors.white : (isDark ? Colors.white : AppTheme.lightTextPrimary), fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ── My Posts ──────────────────────────────────────────────
  Widget _buildMyPosts(bool isDark, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.inputFill : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _roleColor.withOpacity(0.2)),
              ),
              child: Column(children: [
                Icon(Icons.edit_note_rounded, size: 40, color: _roleColor.withOpacity(0.4)),
                const SizedBox(height: 10),
                Text('Chưa có bài viết nào', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: _roleColor, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Viết bài đầu tiên', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final post = PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
            return _buildPostCard(post, isDark);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _roleColor.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(post.title, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          Text(post.timeAgo, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 12, height: 1.4)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.favorite_border_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey),
          const SizedBox(width: 4),
          Text('${post.likeCount}', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
          const SizedBox(width: 12),
          Icon(Icons.chat_bubble_outline_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey),
          const SizedBox(width: 4),
          Text('${post.commentCount}', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }
}
