// lib/screens/user/booking_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _roleColor = AppTheme.roleUser;

  static const _statusFilters = [
    _StatusFilter('Tất cả', null, Icons.list_rounded, Colors.blue),
    _StatusFilter('Chờ xác nhận', 'pending', Icons.pending_rounded, Colors.orange),
    _StatusFilter('Đã xác nhận', 'confirmed', Icons.check_circle_rounded, Color(0xFF4CAF50)),
    _StatusFilter('Hoàn thành', 'completed', Icons.done_all_rounded, Colors.blue),
    _StatusFilter('Đã hủy', 'rejected', Icons.cancel_rounded, Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(isDark),
          _buildTabBar(isDark),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _statusFilters.map((filter) {
            return _BookingList(
              uid: uid,
              statusFilter: filter.status,
              filterColor: filter.color,
              isDark: isDark,
            );
          }).toList(),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      title: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _roleColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.calendar_month_rounded, color: _roleColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          'Lịch sử đặt lịch',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
      actions: [
        IconButton(
          icon: Icon(
            context.watch<ThemeProvider>().isDarkMode
                ? Icons.dark_mode
                : Icons.light_mode,
            color: isDark ? Colors.amber : Colors.orange,
          ),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        IconButton(
          icon: Icon(Icons.logout,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary),
          onPressed: () => _logout(context),
        ),
      ],
    );
  }

  SliverPersistentHeader _buildTabBar(bool isDark) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          indicator: BoxDecoration(
            color: _roleColor,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: _statusFilters.map((f) => Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(f.icon, size: 14),
                const SizedBox(width: 5),
                Text(f.label),
              ]),
            ),
          )).toList(),
        ),
        isDark: isDark,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }
}

// ── Booking List per tab ────────────────────────────────────────────────────
class _BookingList extends StatelessWidget {
  final String uid;
  final String? statusFilter;
  final Color filterColor;
  final bool isDark;

  const _BookingList({
    required this.uid,
    required this.statusFilter,
    required this.filterColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    // KEY FIX: Tab "Tất cả" chỉ filter userId, KHÔNG dùng orderBy
    // Tránh lỗi "requires an index" vì chưa có composite index
    // Sort sẽ được thực hiện bằng Dart sau khi nhận data
    Query query;
    if (statusFilter == null) {
      query = FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid);
    } else {
      query = FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Có lỗi xảy ra',
            subtitle: snap.error.toString(),
            color: Colors.red,
            isDark: isDark,
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.roleUser),
          );
        }

        var docs = snap.data?.docs ?? [];

        // Sort bằng Dart (descending by createdAt)
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.inbox_rounded,
            title: 'Chưa có booking nào',
            subtitle: statusFilter == null
                ? 'Hãy đặt lịch ngay để trải nghiệm dịch vụ!'
                : 'Không có booking ở trạng thái này',
            color: filterColor,
            isDark: isDark,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _BookingCard(bookingId: docs[i].id, data: data, isDark: isDark);
          },
        );
      },
    );
  }
}

// ── Booking Card ────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final bool isDark;

  const _BookingCard({required this.bookingId, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final statusInfo = _getStatusInfo(status);
    final bookingDate = (data['bookingDate'] as Timestamp?)?.toDate();
    final dateStr = bookingDate != null
        ? '${_weekday(bookingDate.weekday)}, ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'
        : '---';
    final timeSlot = data['timeSlot'] as String? ?? '';
    final photographerName = data['photographerName'] as String?;
    final makeuperName = data['makeuperName'] as String?;
    final address = data['address'] as String? ?? '';
    final note = data['note'] as String?;
    final photographerPrice = (data['photographerPrice'] as num?)?.toInt() ?? 0;
    final makeuperPrice = (data['makeuperPrice'] as num?)?.toInt() ?? 0;
    final totalPrice = photographerPrice + makeuperPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusInfo.color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: statusInfo.color.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: statusInfo.color.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Icon(statusInfo.icon, color: statusInfo.color, size: 15),
            const SizedBox(width: 6),
            Text(statusInfo.label,
                style: TextStyle(color: statusInfo.color, fontWeight: FontWeight.w700, fontSize: 12)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$dateStr  •  $timeSlot',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (photographerName != null) ...[
              _ProviderRow(icon: Icons.camera_alt_rounded, color: AppTheme.rolePhotographer,
                  role: 'Photographer', name: photographerName, price: photographerPrice, isDark: isDark),
              if (makeuperName != null) const SizedBox(height: 8),
            ],
            if (makeuperName != null)
              _ProviderRow(icon: Icons.brush_rounded, color: AppTheme.roleMakeuper,
                  role: 'Makeup Artist', name: makeuperName, price: makeuperPrice, isDark: isDark),

            const SizedBox(height: 10),
            Divider(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.12)),
            const SizedBox(height: 8),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_rounded, color: Colors.orange, size: 15),
              const SizedBox(width: 6),
              Expanded(child: Text(address, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700], fontSize: 12, height: 1.4))),
            ]),

            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 15),
                const SizedBox(width: 6),
                Expanded(child: Text(note, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 12, height: 1.4))),
              ]),
            ],

            const SizedBox(height: 12),

            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tổng tiền', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(totalPrice > 0 ? '${_formatPrice(totalPrice)}đ' : 'Chưa có giá',
                    style: const TextStyle(color: AppTheme.roleUser, fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
              const Spacer(),
              if (status == 'pending')
                _OutlineButton(label: 'Hủy booking', color: Colors.red, isDark: isDark,
                    onTap: () => _showCancelDialog(context, bookingId)),
              if (status == 'confirmed')
                _OutlineButton(label: 'Liên hệ', color: AppTheme.roleUser, isDark: isDark,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('💬 Tính năng chat sắp ra mắt!'), behavior: SnackBarBehavior.floating))),
              if (status == 'completed')
                _OutlineButton(label: '⭐ Đánh giá', color: Colors.amber, isDark: isDark,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('⭐ Tính năng đánh giá sắp ra mắt!'), behavior: SnackBarBehavior.floating))),
            ]),

            if (status == 'pending') ...[
              const SizedBox(height: 10),
              _buildProviderStatusChips(isDark),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildProviderStatusChips(bool isDark) {
    final photoStatus = data['photographerStatus'] as String?;
    final makeupStatus = data['makeuperStatus'] as String?;
    final hasPhoto = data['photographerId'] != null;
    final hasMakeup = data['makeuperId'] != null;
    if (!hasPhoto && !hasMakeup) return const SizedBox.shrink();
    return Wrap(spacing: 6, children: [
      if (hasPhoto) _StatusChip(label: 'Photographer: ${_providerStatusLabel(photoStatus)}',
          color: _providerStatusColor(photoStatus), isDark: isDark),
      if (hasMakeup) _StatusChip(label: 'Makeup: ${_providerStatusLabel(makeupStatus)}',
          color: _providerStatusColor(makeupStatus), isDark: isDark),
    ]);
  }

  String _providerStatusLabel(String? s) {
    switch (s) {
      case 'confirmed': return 'Đã xác nhận ✓';
      case 'rejected': return 'Từ chối ✗';
      default: return 'Chờ xác nhận...';
    }
  }

  Color _providerStatusColor(String? s) {
    switch (s) {
      case 'confirmed': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hủy booking?',
            style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn hủy booking này không?',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Không', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'rejected'});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('✅ Đã hủy booking'), backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Hủy booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'confirmed': return const _StatusInfo('Đã xác nhận', Icons.check_circle_rounded, Color(0xFF4CAF50));
      case 'completed': return const _StatusInfo('Hoàn thành', Icons.done_all_rounded, Colors.blue);
      case 'rejected': return const _StatusInfo('Đã hủy', Icons.cancel_rounded, Colors.red);
      default: return const _StatusInfo('Chờ xác nhận', Icons.pending_rounded, Colors.orange);
    }
  }

  String _weekday(int w) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[(w - 1).clamp(0, 6)];
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _ProviderRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String role;
  final String name;
  final int price;
  final bool isDark;

  const _ProviderRow({required this.icon, required this.color, required this.role,
    required this.name, required this.price, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        Text(role, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ])),
      if (price > 0) Text('${_fmt(price)}đ',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
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

class _OutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4))),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _StatusChip({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _EmptyState({required this.icon, required this.title, required this.subtitle, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color.withOpacity(0.6), size: 36)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate(this.tabBar, {required this.isDark});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: isDark ? AppTheme.primary : AppTheme.lightBg, child: tabBar);
  }

  @override double get maxExtent => 56;
  @override double get minExtent => 56;
  @override bool shouldRebuild(_TabBarDelegate old) => old.isDark != isDark;
}

class _StatusFilter {
  final String label;
  final String? status;
  final IconData icon;
  final Color color;
  const _StatusFilter(this.label, this.status, this.icon, this.color);
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusInfo(this.label, this.icon, this.color);
}