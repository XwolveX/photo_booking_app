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
import '../shared/manage_services_screen.dart';

class PhotographerHomeScreen extends StatefulWidget {
  const PhotographerHomeScreen({super.key});

  @override
  State<PhotographerHomeScreen> createState() => _PhotographerHomeScreenState();
}

class _PhotographerHomeScreenState extends State<PhotographerHomeScreen> {
  bool _isOnline = true;
  int _incomeTab = 1;
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark, user?.fullName ?? ''),
          SliverToBoxAdapter(child: _buildStatsRow(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildIncomeCard(isDark)),
          SliverToBoxAdapter(child: _buildSectionTitle('📋 Booking chờ xác nhận', isDark)),
          SliverToBoxAdapter(child: _buildBookingList(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildSectionTitle('🛠️ Dịch vụ của tôi', isDark)),
          SliverToBoxAdapter(child: _buildServicesSection(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildSectionTitle('📅 Lịch trong tuần', isDark)),
          SliverToBoxAdapter(child: _buildWeekCalendar(isDark)),
          SliverToBoxAdapter(child: _buildSectionTitle('📝 Bài viết của tôi', isDark)),
          SliverToBoxAdapter(child: _buildMyPosts(isDark, user?.uid ?? '')),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
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
      flexibleSpace: FlexibleSpaceBar(background: _buildHeader(isDark, name)),
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
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _roleColor, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: _roleColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Studio của bạn 📸',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : AppTheme.lightTextSecondary,
                        fontSize: 12)),
                Text(name,
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
            GestureDetector(
              onTap: () => setState(() => _isOnline = !_isOnline),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: (_isOnline ? AppTheme.success : Colors.grey).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _isOnline ? AppTheme.success : Colors.grey, width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                        color: _isOnline ? AppTheme.success : Colors.grey,
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(_isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                          color: _isOnline ? AppTheme.success : Colors.grey,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text('Quản lý booking &\nbài viết của bạn',
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
        ],
      ),
    );
  }

  // ── Stats ──────────────────────────────────────────────────
  Widget _buildStatsRow(bool isDark, String uid) {
    if (uid.isEmpty) {
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('photographerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final today = DateTime.now();
        final todayCount = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final date = (data['bookingDate'] as Timestamp?)?.toDate();
          return date != null &&
              date.day == today.day &&
              date.month == today.month &&
              date.year == today.year &&
              data['status'] == 'confirmed';
        }).length;
        final pendingCount = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['photographerStatus'] == 'pending';
        }).length;
        final doneCount = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'completed';
        }).length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            _statCard('$todayCount', 'Hôm\nnay', Icons.today_rounded, _roleColor, isDark),
            const SizedBox(width: 8),
            _statCard('$pendingCount', 'Chờ xác\nnhận', Icons.pending_rounded, Colors.orange, isDark),
            const SizedBox(width: 8),
            _statCard('$doneCount', 'Hoàn\nthành', Icons.check_circle_rounded, AppTheme.success, isDark),
            const SizedBox(width: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('authorId', isEqualTo: uid)
                  .snapshots(),
              builder: (_, ps) {
                final postCount = ps.data?.docs.length ?? 0;
                return _statCard('$postCount', 'Bài\nviết', Icons.article_rounded, Colors.blue, isDark);
              },
            ),
          ]),
        );
      },
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
          Text(v, style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 10, height: 1.3)),
        ]),
      ),
    );
  }

  // ── Income Card ────────────────────────────────────────────
  Widget _buildIncomeCard(bool isDark) {
    final tabs = ['Tuần', 'Tháng', 'Năm'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_roleColor, _roleColor.withOpacity(0.7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _roleColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('💰 Thống kê thu nhập',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final sel = _incomeTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _incomeTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20)),
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
          Row(crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: (20 + (i * 5) % 40).toDouble(),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(i == 5 ? 1 : 0.3),
                    borderRadius: BorderRadius.circular(4)),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Text('Sẽ cập nhật khi có booking hoàn thành',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ]),
      ),
    );
  }

  // ── Booking List — REAL FIRESTORE ──────────────────────────
  Widget _buildBookingList(bool isDark, String uid) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('photographerId', isEqualTo: uid)
          .where('photographerStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        // Hiện lỗi thật nếu có
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.4)),
              ),
              child: Text('Lỗi: ${snap.error}',
                  style: const TextStyle(color: AppTheme.error, fontSize: 12)),
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: _roleColor)),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.inputFill : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12)),
              ),
              child: Column(children: [
                Icon(Icons.inbox_rounded, size: 40,
                    color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 10),
                Text('Chưa có booking nào',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Booking mới sẽ hiển thị tại đây',
                    style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.grey[400],
                        fontSize: 12)),
              ]),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildBookingCard(doc.id, data, isDark);
          }).toList(),
        );
      },
    );
  }

  Widget _buildBookingCard(String bookingId, Map<String, dynamic> data, bool isDark) {
    final bookingDate = (data['bookingDate'] as Timestamp?)?.toDate();
    final dateStr = bookingDate != null
        ? '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'
        : '---';
    final timeSlot = data['timeSlot'] as String? ?? '';
    final userName = data['userName'] as String? ?? 'Khách hàng';
    final address = data['address'] as String? ?? '';
    final note = data['note'] as String?;
    final price = (data['photographerPrice'] as num?)?.toDouble() ?? 0;

    // Check xem có cả makeuper không
    final hasMakeuper = data['makeuperId'] != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              const Icon(Icons.pending_rounded, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              const Text('Chờ xác nhận',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700, fontSize: 12)),
              const Spacer(),
              Text('$dateStr  •  $timeSlot',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khách hàng
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: AppTheme.roleUser.withOpacity(0.15),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded,
                        color: AppTheme.roleUser, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(userName,
                          style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Khách hàng',
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
                              fontSize: 11)),
                    ]),
                  ),
                  // Giá
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_formatPrice(price.toInt()),
                        style: const TextStyle(
                            color: _roleColor,
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const Text('đ', style: TextStyle(color: _roleColor, fontSize: 11)),
                  ]),
                ]),

                const SizedBox(height: 10),
                Divider(color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 8),

                // Địa điểm
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.location_on_rounded, color: Colors.orange, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(address,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey[700],
                            fontSize: 12, height: 1.4)),
                  ),
                ]),

                // Ghi chú
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(note,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey[600],
                              fontSize: 12, height: 1.4)),
                    ),
                  ]),
                ],

                // Thông báo nếu có cả makeuper
                if (hasMakeuper) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: AppTheme.roleMakeuper.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.brush_rounded,
                          color: AppTheme.roleMakeuper, size: 12),
                      const SizedBox(width: 5),
                      Text('Có kèm Makeup Artist: ${data['makeuperName'] ?? ''}',
                          style: const TextStyle(
                              color: AppTheme.roleMakeuper,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],

                const SizedBox(height: 14),

                // Nút Accept / Reject
                Row(children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Từ chối',
                      icon: Icons.close_rounded,
                      color: AppTheme.error,
                      isDark: isDark,
                      onTap: () => _showConfirmDialog(
                        context: context,
                        bookingId: bookingId,
                        action: 'reject',
                        isDark: isDark,
                        hasMakeuper: hasMakeuper,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _ActionButton(
                      label: 'Chấp nhận',
                      icon: Icons.check_rounded,
                      color: AppTheme.success,
                      isDark: isDark,
                      filled: true,
                      onTap: () => _showConfirmDialog(
                        context: context,
                        bookingId: bookingId,
                        action: 'accept',
                        isDark: isDark,
                        hasMakeuper: hasMakeuper,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Accept / Reject Logic ──────────────────────────────────
  void _showConfirmDialog({
    required BuildContext context,
    required String bookingId,
    required String action,
    required bool isDark,
    required bool hasMakeuper,
  }) {
    final isAccept = action == 'accept';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAccept ? 'Xác nhận chấp nhận?' : 'Xác nhận từ chối?',
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700),
        ),
        content: Text(
          isAccept
              ? 'Bạn sẽ xác nhận tham gia buổi chụp này.'
              : 'Bạn sẽ từ chối booking này. Khách hàng sẽ được thông báo.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateBookingStatus(
                bookingId: bookingId,
                action: action,
                hasMakeuper: hasMakeuper,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccept ? AppTheme.success : AppTheme.error,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isAccept ? 'Chấp nhận' : 'Từ chối',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus({
    required String bookingId,
    required String action,
    required bool hasMakeuper,
  }) async {
    final isAccept = action == 'accept';
    final docRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);

    try {
      final updateData = <String, dynamic>{
        'photographerStatus': isAccept ? 'confirmed' : 'rejected',
      };

      // Nếu reject → set status tổng thành rejected
      if (!isAccept) {
        updateData['status'] = 'rejected';
      }

      // Nếu accept → check xem makeuper đã confirm chưa
      // Nếu không có makeuper → confirm luôn booking
      if (isAccept && !hasMakeuper) {
        updateData['status'] = 'confirmed';
      }

      // Nếu accept + có makeuper → chỉ update photographerStatus,
      // chờ makeuper confirm thì booking mới thành confirmed

      await docRef.update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAccept
                ? '✅ Đã chấp nhận booking!'
                : '❌ Đã từ chối booking'),
            backgroundColor: isAccept ? AppTheme.success : AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Services Section ───────────────────────────────────────
  Widget _buildServicesSection(bool isDark, String uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('providerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          final services = (snap.data?.docs ?? [])
              .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
              .toList();

          return Column(children: [
            // Danh sách dịch vụ
            if (services.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.inputFill : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _roleColor.withOpacity(0.2)),
                ),
                child: Column(children: [
                  Icon(Icons.design_services_rounded, size: 32, color: _roleColor.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Chưa có dịch vụ nào',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 13)),
                ]),
              )
            else
              ...services.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.inputFill : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _roleColor.withOpacity(0.15)),
                ),
                child: Row(children: [
                  Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: _roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.design_services_rounded, color: _roleColor, size: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['name'] ?? '', style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                    if ((s['description'] ?? '').isNotEmpty)
                      Text(s['description'], maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
                  ])),
                  Text(
                    (s['price'] as num? ?? 0) > 0 ? '${_formatPrice((s['price'] as num).toInt())}đ' : 'Liên hệ',
                    style: TextStyle(color: _roleColor, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ]),
              )),

            const SizedBox(height: 10),
            // Nút quản lý
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManageServicesScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _roleColor.withOpacity(0.3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.settings_rounded, color: _roleColor, size: 16),
                  const SizedBox(width: 6),
                  Text('Quản lý dịch vụ',
                      style: TextStyle(color: _roleColor, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }

  // ── Week Calendar ──────────────────────────────────────────
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
                color: isToday
                    ? _roleColor
                    : (isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Text(days[i],
                    style: TextStyle(
                        color: isToday ? Colors.white : (isDark ? Colors.white54 : Colors.grey),
                        fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${d.day}',
                    style: TextStyle(
                        color: isToday ? Colors.white : (isDark ? Colors.white : AppTheme.lightTextPrimary),
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ── My Posts ───────────────────────────────────────────────
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
                Text('Chưa có bài viết nào',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreatePostScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: _roleColor, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Viết bài đầu tiên',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
            child: Text(post.title,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          Text(post.timeAgo,
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Text(post.content,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey[600],
                fontSize: 12, height: 1.4)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.favorite_border_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey),
          const SizedBox(width: 4),
          Text('${post.likeCount}',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
          const SizedBox(width: 12),
          Icon(Icons.chat_bubble_outline_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey),
          const SizedBox(width: 4),
          Text('${post.commentCount}',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title,
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 16, fontWeight: FontWeight.w700)),
    );
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

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }
}

// ── Reusable Action Button ─────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(filled ? 0 : 0.5)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: filled ? Colors.white : color, size: 17),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: filled ? Colors.white : color,
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}