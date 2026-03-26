// lib/screens/photographer/photographer_main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import 'photographer_home_screen.dart';
import '../user/post_feed_screen.dart';
import '../user/booking_history_screen.dart';
import '../user/chat_list_screen.dart';
import '../shared/profile_screen.dart';

class PhotographerMainScreen extends StatefulWidget {
  const PhotographerMainScreen({super.key});

  @override
  State<PhotographerMainScreen> createState() => _PhotographerMainScreenState();
}

class _PhotographerMainScreenState extends State<PhotographerMainScreen> {
  int _currentIndex = 0;
  static const _roleColor = AppTheme.rolePhotographer;

  final List<Widget> _screens = const [
    PhotographerHomeScreen(),   // 0 — Trang chủ / Dashboard
    PostFeedScreen(),           // 1 — Bài viết
    BookingHistoryScreen(),      // 2 — Lịch sử booking
    ChatListScreen(),           // 3 — Chat
    ProfileScreen(),            // 4 — Tôi
  ];

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.watch<AuthProvider>().currentUser?.uid ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
        body: IndexedStack(
          index: _currentIndex == 2 ? 0 : _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNav(isDark, uid),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, String uid) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.12),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                iconOutlined: Icons.dashboard_outlined,
                label: 'Dashboard',
                index: 0,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.auto_stories_rounded,
                iconOutlined: Icons.auto_stories_outlined,
                label: 'Bài viết',
                index: 1,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.history_rounded,
                iconOutlined: Icons.history_outlined,
                label: 'Lịch sử',
                index: 2,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
              _ChatNavItem(
                uid: uid,
                index: 3,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                iconOutlined: Icons.person_outline_rounded,
                label: 'Tôi',
                index: 4,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chat nav item với unread badge ────────────────────────────
class _ChatNavItem extends StatelessWidget {
  final String uid;
  final int index;
  final int currentIndex;
  final Color color;
  final bool isDark;
  final void Function(int) onTap;

  const _ChatNavItem({
    required this.uid,
    required this.index,
    required this.currentIndex,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                      color: isSelected
                          ? color
                          : (isDark ? Colors.white38 : Colors.grey[400]),
                      size: 24,
                    ),
                  ),
                  // Unread badge
                  if (uid.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .where('user1Id', isEqualTo: uid)
                            .snapshots(),
                        builder: (context, snap1) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('chats')
                                .where('user2Id', isEqualTo: uid)
                                .snapshots(),
                            builder: (context, snap2) {
                              int total = 0;
                              for (final doc in snap1.data?.docs ?? []) {
                                final d = doc.data() as Map<String, dynamic>;
                                total += (d['unreadUser1'] as int?) ?? 0;
                              }
                              for (final doc in snap2.data?.docs ?? []) {
                                final d = doc.data() as Map<String, dynamic>;
                                total += (d['unreadUser2'] as int?) ?? 0;
                              }
                              if (total == 0) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: const BoxDecoration(
                                  color: AppTheme.secondary,
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Text(
                                  total > 99 ? '99+' : '$total',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? color : (isDark ? Colors.white38 : Colors.grey[400]),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
                child: const Text('Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Nav Item ─────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconOutlined;
  final String label;
  final int index;
  final int currentIndex;
  final Color color;
  final bool isDark;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.iconOutlined,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isSelected ? icon : iconOutlined,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white38 : Colors.grey[400]),
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? color : (isDark ? Colors.white38 : Colors.grey[400]),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}