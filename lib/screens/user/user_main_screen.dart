// lib/screens/user/user_main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'user_home_screen.dart';
import 'post_feed_screen.dart';
import 'booking_history_screen.dart';
import 'chat_list_screen.dart';
import '../booking/booking_step1_providers.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;

  static const _roleColor = AppTheme.roleUser;

  final List<Widget> _screens = const [
    UserHomeScreen(),
    BookingStep1Screen(hideBackButton: true), // ← ẩn nút back khi vào từ nav
    PostFeedScreen(),
    BookingHistoryScreen(),
    ChatListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNav(isDark),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
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
                icon: Icons.home_rounded,
                iconOutlined: Icons.home_outlined,
                label: 'Trang chủ',
                index: 0,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.calendar_today_rounded,
                iconOutlined: Icons.calendar_today_outlined,
                label: 'Booking',
                index: 1,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.article_rounded,
                iconOutlined: Icons.article_outlined,
                label: 'Bài viết',
                index: 2,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.calendar_month_rounded,
                iconOutlined: Icons.calendar_month_outlined,
                label: 'Lịch sử',
                index: 3,
                currentIndex: _currentIndex,
                color: _roleColor,
                isDark: isDark,
                onTap: _onTap,
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                iconOutlined: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
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

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }
}

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
                curve: Curves.easeOut,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.12)
                      : Colors.transparent,
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
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white38 : Colors.grey[400]),
                  fontSize: 10,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w400,
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