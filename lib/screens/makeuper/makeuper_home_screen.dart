// lib/screens/makeuper/makeuper_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/manage_services_screen.dart';
import '../shared/wallet_screen.dart';

class MakeuperHomeScreen extends StatefulWidget {
  const MakeuperHomeScreen({super.key});

  @override
  State<MakeuperHomeScreen> createState() => _MakeuperHomeScreenState();
}

class _MakeuperHomeScreenState extends State<MakeuperHomeScreen> {
  bool _isOnline = true;
  int _incomeTab = 1;
  static const _roleColor = AppTheme.roleMakeuper;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark, user?.fullName ?? '', user?.uid ?? ''),
          SliverToBoxAdapter(child: _buildStatsRow(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildIncomeCard(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildSectionTitle('📋 Booking chờ xác nhận', isDark)),
          SliverToBoxAdapter(child: _buildBookingList(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildSectionTitle('💄 Dịch vụ của tôi', isDark)),
          SliverToBoxAdapter(child: _buildServicesSection(isDark, user?.uid ?? '')),
          SliverToBoxAdapter(child: _buildSectionTitle('📅 Lịch trình làm việc', isDark)),
          SliverToBoxAdapter(child: _buildWorkSchedule(isDark, user?.uid ?? '')),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark, String name, String uid) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      actions: [
        _WalletButton(uid: uid, isDark: isDark, roleColor: _roleColor),
        IconButton(
          icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: isDark ? Colors.amber : Colors.orange),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
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
              ? [AppTheme.surface, const Color(0xFF2A1040)]
              : [const Color(0xFFFAF0FF), const Color(0xFFEDD6FF)],
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
              child:
              const Icon(Icons.brush_rounded, color: _roleColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Studio makeup 💄',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : AppTheme.lightTextSecondary,
                            fontSize: 12)),
                    Text(name,
                        style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                  ]),
            ),
            GestureDetector(
              onTap: () => setState(() => _isOnline = !_isOnline),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                    width: 7, height: 7,
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
          ]),
          const SizedBox(height: 14),
          Text('Quản lý booking &\nbài viết của bạn',
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3)),
        ],
      ),
    );
  }

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
          .where('makeuperId', isEqualTo: uid)
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
          return data['makeuperStatus'] == 'pending';
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
                return _statCard('$postCount', 'Bài\nviết',
                    Icons.article_rounded, Colors.blue, isDark);
              },
            ),
          ]),
        );
      },
    );
  }

  Widget _statCard(
      String v, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.inputFill : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(v,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 10,
                  height: 1.3)),
        ]),
      ),
    );
  }

  Widget _buildIncomeCard(bool isDark, String uid) {
    final tabs = ['Tuần', 'Tháng', 'Năm'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: StreamBuilder<DocumentSnapshot>(
        stream: uid.isEmpty
            ? null
            : FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          final userData = snap.data?.data() as Map<String, dynamic>?;
          final balance = (userData?['balance'] as num?)?.toDouble() ?? 0.0;
          final totalEarnings =
              (userData?['totalEarnings'] as num?)?.toDouble() ?? 0.0;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_roleColor, _roleColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: _roleColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text('💰 Ví của tôi',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            final sel = _incomeTab == i;
                            return GestureDetector(
                              onTap: () => setState(() => _incomeTab = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: sel ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(tabs[i],
                                    style: TextStyle(
                                        color: sel
                                            ? _roleColor
                                            : Colors.white.withOpacity(0.8),
                                        fontSize: 11,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.w400)),
                              ),
                            );
                          }),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Số dư khả dụng',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${_formatPrice(balance.toInt())}đ',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800)),
                      ]),
                      const Spacer(),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Tổng thu nhập',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${_formatPrice(totalEarnings.toInt())}đ',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                          7,
                              (i) => Expanded(
                            child: Container(
                              margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                              height: (20 + (i * 5) % 40).toDouble(),
                              decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(i == 5 ? 1 : 0.3),
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                          )),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(
                        balance > 0
                            ? 'Nhấn để xem chi tiết ví →'
                            : 'Tiền sẽ cộng khi user xác nhận hoàn thành',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6), fontSize: 11),
                      ),
                      if (balance > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Rút tiền',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                  ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingList(bool isDark, String uid) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('makeuperId', isEqualTo: uid)
          .where('makeuperStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
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
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.12)),
              ),
              child: Column(children: [
                Icon(Icons.inbox_rounded,
                    size: 40,
                    color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 10),
                Text('Chưa có booking nào',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
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

  Widget _buildBookingCard(
      String bookingId, Map<String, dynamic> data, bool isDark) {
    final bookingDate = (data['bookingDate'] as Timestamp?)?.toDate();
    final dateStr = bookingDate != null
        ? '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'
        : '---';
    final timeSlot = data['timeSlot'] as String? ?? '';
    final userName = data['userName'] as String? ?? 'Khách hàng';
    final address = data['address'] as String? ?? '';
    final note = data['note'] as String?;
    final price = (data['makeuperPrice'] as num?)?.toDouble() ?? 0;
    final hasPhotographer = data['photographerId'] != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              const Icon(Icons.pending_rounded, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              const Text('Chờ xác nhận',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              const Spacer(),
              Text('$dateStr  •  $timeSlot',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.lightTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text('Khách hàng',
                              style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  fontSize: 11)),
                        ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_formatPrice(price.toInt()),
                        style: const TextStyle(
                            color: _roleColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const Text('đ',
                        style: TextStyle(color: _roleColor, fontSize: 11)),
                  ]),
                ]),
                const SizedBox(height: 10),
                Divider(
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.location_on_rounded,
                      color: Colors.orange, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey[700],
                            fontSize: 12,
                            height: 1.4)),
                  ),
                ]),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.edit_note_rounded,
                        color: Colors.blue, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color:
                              isDark ? Colors.white54 : Colors.grey[600],
                              fontSize: 12,
                              height: 1.4)),
                    ),
                  ]),
                ],
                if (hasPhotographer) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: AppTheme.rolePhotographer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.camera_alt_rounded,
                          color: AppTheme.rolePhotographer, size: 12),
                      const SizedBox(width: 5),
                      Text(
                          'Có kèm Photographer: ${data['photographerName'] ?? ''}',
                          style: const TextStyle(
                              color: AppTheme.rolePhotographer,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
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
                        hasPartner: hasPhotographer,
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
                        hasPartner: hasPhotographer,
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

  void _showConfirmDialog({
    required BuildContext context,
    required String bookingId,
    required String action,
    required bool isDark,
    required bool hasPartner,
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
              ? 'Bạn sẽ xác nhận tham gia buổi chụp này. User sẽ cần thanh toán để booking có hiệu lực.'
              : 'Bạn sẽ từ chối booking này. Khách hàng sẽ được thông báo.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateBookingStatus(
                bookingId: bookingId,
                action: action,
                hasPartner: hasPartner,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccept ? AppTheme.success : AppTheme.error,
              minimumSize: Size.zero,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isAccept ? 'Chấp nhận' : 'Từ chối',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus({
    required String bookingId,
    required String action,
    required bool hasPartner,
  }) async {
    final isAccept = action == 'accept';
    final docRef =
    FirebaseFirestore.instance.collection('bookings').doc(bookingId);

    try {
      final updateData = <String, dynamic>{
        'makeuperStatus': isAccept ? 'confirmed' : 'rejected',
      };

      if (!isAccept) {
        updateData['status'] = 'rejected';
      }

      if (isAccept && !hasPartner) {
        updateData['status'] = 'confirmed';
      }

      await docRef.update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAccept
                ? '✅ Đã chấp nhận! Chờ khách hàng thanh toán.'
                : '❌ Đã từ chối booking'),
            backgroundColor: isAccept ? AppTheme.success : AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
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
              .map((d) =>
          {'id': d.id, ...(d.data() as Map<String, dynamic>)})
              .toList();

          return Column(children: [
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
                  Icon(Icons.design_services_rounded,
                      size: 32, color: _roleColor.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Chưa có dịch vụ nào',
                      style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                          fontSize: 13)),
                ]),
              )
            else
              ...services.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.inputFill : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: _roleColor.withOpacity(0.15)),
                ),
                child: Row(children: [
                  Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: _roleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.design_services_rounded,
                          color: _roleColor, size: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'] ?? '',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.lightTextPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            if ((s['description'] ?? '').isNotEmpty)
                              Text(s['description'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey,
                                      fontSize: 11)),
                          ])),
                  Text(
                    (s['price'] as num? ?? 0) > 0
                        ? '${_formatPrice((s['price'] as num).toInt())}đ'
                        : 'Liên hệ',
                    style: TextStyle(
                        color: _roleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ]),
              )),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageServicesScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _roleColor.withOpacity(0.3)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings_rounded, color: _roleColor, size: 16),
                      const SizedBox(width: 6),
                      Text('Quản lý dịch vụ',
                          style: TextStyle(
                              color: _roleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ]),
              ),
            ),
          ]);
        },
      ),
    );
  }

  // ── Work Schedule ──────────────────────────────────────────
  Widget _buildWorkSchedule(bool isDark, String uid) {
    if (uid.isEmpty) return const SizedBox.shrink();
    return _WorkScheduleWidget(
      uid: uid,
      isDark: isDark,
      roleColor: _roleColor,
      roleField: 'makeuperId',
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title,
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
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

}

// ── Wallet Button ──────────────────────────────────────────────
class _WalletButton extends StatelessWidget {
  final String uid;
  final bool isDark;
  final Color roleColor;

  const _WalletButton(
      {required this.uid, required this.isDark, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final balance = (data?['balance'] as num?)?.toDouble() ?? 0.0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WalletScreen()),
          ),
          child: Container(
            margin:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: roleColor, size: 15),
              const SizedBox(width: 5),
              Text(
                balance > 0 ? '${_fmt(balance.toInt())}đ' : 'Ví',
                style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ]),
          ),
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
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Work Schedule Widget (shared, reusable) ───────────────────
class _WorkScheduleWidget extends StatefulWidget {
  final String uid;
  final bool isDark;
  final Color roleColor;
  final String roleField; // 'photographerId' or 'makeuperId'

  const _WorkScheduleWidget({
    required this.uid,
    required this.isDark,
    required this.roleColor,
    required this.roleField,
  });

  @override
  State<_WorkScheduleWidget> createState() => _WorkScheduleWidgetState();
}

class _WorkScheduleWidgetState extends State<_WorkScheduleWidget> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  static const _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(widget.roleField, isEqualTo: widget.uid)
          .where('status', whereIn: ['pending', 'confirmed', 'completed'])
          .snapshots(),
      builder: (context, snap) {
        // Build a map: "yyyy-MM-dd" → list of bookings
        final bookingMap = <String, List<Map<String, dynamic>>>{};
        for (final doc in snap.data?.docs ?? []) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['bookingDate'] as Timestamp?)?.toDate();
          if (date == null) continue;
          final key = _dateKey(date);
          bookingMap.putIfAbsent(key, () => []).add({...data, 'id': doc.id});
        }

        final selectedKey = _dateKey(_selectedDay);
        final selectedBookings = bookingMap[selectedKey] ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            // ── Calendar card ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: widget.isDark ? AppTheme.inputFill : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark ? Colors.black26 : Colors.grey.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(children: [
                // Month nav
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(children: [
                    Text(
                      _monthLabel(_focusedMonth),
                      style: TextStyle(
                        color: widget.isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    // Tóm tắt tháng
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where(widget.roleField, isEqualTo: widget.uid)
                          .where('status', whereIn: ['confirmed', 'completed'])
                          .snapshots(),
                      builder: (context, mSnap) {
                        final monthCount = (mSnap.data?.docs ?? []).where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          final date = (data['bookingDate'] as Timestamp?)?.toDate();
                          return date != null &&
                              date.month == _focusedMonth.month &&
                              date.year == _focusedMonth.year;
                        }).length;
                        if (monthCount == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.roleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$monthCount lịch',
                            style: TextStyle(
                              color: widget.roleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded,
                          color: widget.isDark ? Colors.white54 : Colors.grey),
                      onPressed: () => setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                      }),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded,
                          color: widget.isDark ? Colors.white54 : Colors.grey),
                      onPressed: () => setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                      }),
                    ),
                  ]),
                ),

                // Day-of-week header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: _days.map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                          style: TextStyle(
                            color: d == 'CN'
                                ? widget.roleColor
                                : (widget.isDark ? Colors.white38 : Colors.grey),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Calendar grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                  child: _buildGrid(bookingMap),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Selected day schedule ──────────────────────
            _buildDaySchedule(selectedBookings),
          ]),
        );
      },
    );
  }

  Widget _buildGrid(Map<String, List<Map<String, dynamic>>> bookingMap) {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = (firstOfMonth.weekday - 1) % 7;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final day = cellIndex - startOffset + 1;
            if (day < 1 || day > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final key = _dateKey(date);
            final bookings = bookingMap[key] ?? [];
            final hasBooking = bookings.isNotEmpty;
            final confirmedCount = bookings.where((b) => b['status'] == 'confirmed').length;
            final pendingCount = bookings.where((b) => b['status'] == 'pending').length;

            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isSelected = date.year == _selectedDay.year &&
                date.month == _selectedDay.month &&
                date.day == _selectedDay.day;
            final isSunday = date.weekday == 7;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = date),
                child: Container(
                  height: 46,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.roleColor
                        : isToday
                        ? widget.roleColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: widget.roleColor.withOpacity(0.5), width: 1.5)
                        : null,
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isSunday
                                ? widget.roleColor.withOpacity(0.8)
                                : (widget.isDark ? Colors.white : AppTheme.lightTextPrimary),
                            fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        if (hasBooking) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (confirmedCount > 0)
                                Container(
                                  width: 5, height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : AppTheme.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (pendingCount > 0)
                                Container(
                                  width: 5, height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white70 : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    // Badge tổng số booking nếu > 1
                    if (hasBooking && bookings.length > 1)
                      Positioned(
                        top: 3,
                        right: 3,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : widget.roleColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${bookings.length}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : widget.roleColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDaySchedule(List<Map<String, dynamic>> bookings) {
    final dateStr = '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}';
    final weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    final weekdayStr = weekdays[_selectedDay.weekday - 1];

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bookings.isNotEmpty
              ? widget.roleColor.withOpacity(0.3)
              : (widget.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12)),
          width: bookings.isNotEmpty ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark ? Colors.black12 : Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header ngày
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bookings.isNotEmpty
                ? widget.roleColor.withOpacity(0.07)
                : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Icon(
              bookings.isNotEmpty ? Icons.event_available_rounded : Icons.event_outlined,
              color: bookings.isNotEmpty ? widget.roleColor : (widget.isDark ? Colors.white38 : Colors.grey),
              size: 18,
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                weekdayStr,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: widget.roleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
            const Spacer(),
            if (bookings.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${bookings.length} lịch',
                  style: TextStyle(
                    color: widget.roleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ]),
        ),

        if (bookings.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Icon(Icons.free_breakfast_rounded,
                  color: widget.isDark ? Colors.white24 : Colors.grey[300], size: 20),
              const SizedBox(width: 10),
              Text(
                'Không có lịch làm việc',
                style: TextStyle(
                  color: widget.isDark ? Colors.white38 : Colors.grey,
                  fontSize: 13,
                ),
              ),
            ]),
          )
        else
        // Sort by timeSlot
          ...(() {
            final sorted = List<Map<String, dynamic>>.from(bookings);
            sorted.sort((a, b) => (a['timeSlot'] ?? '').compareTo(b['timeSlot'] ?? ''));
            return sorted;
          })().asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            return _buildScheduleItem(b, i, bookings.length);
          }),
      ]),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> data, int index, int total) {
    final timeSlot = data['timeSlot'] as String? ?? '--:--';
    final userName = data['userName'] as String? ?? 'Khách hàng';
    final address = data['address'] as String? ?? '';
    final note = data['note'] as String?;
    final status = data['status'] as String? ?? 'pending';
    final paymentStatus = data['paymentStatus'] as String?;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'confirmed':
        statusColor = paymentStatus == 'paid' ? AppTheme.success : Colors.orange;
        statusIcon = paymentStatus == 'paid'
            ? Icons.check_circle_rounded
            : Icons.payments_outlined;
        statusLabel = paymentStatus == 'paid' ? 'Đã thanh toán' : 'Chờ thanh toán';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all_rounded;
        statusLabel = 'Hoàn thành';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_rounded;
        statusLabel = 'Chờ xác nhận';
    }

    return Column(children: [
      if (index > 0)
        Divider(
          height: 1,
          indent: 16,
          color: widget.isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cột giờ
          Column(children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  timeSlot,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (index < total - 1) ...[
              const SizedBox(height: 4),
              Container(
                width: 1.5,
                height: 20,
                color: widget.isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
              ),
            ],
          ]),
          const SizedBox(width: 12),

          // Nội dung
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    userName,
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, color: statusColor, size: 10),
                    const SizedBox(width: 3),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 5),

              if (address.isNotEmpty)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: widget.isDark ? Colors.white38 : Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ]),

              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.notes_rounded,
                      size: 13, color: Colors.blue.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isDark ? Colors.white38 : Colors.grey[500],
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ]),
              ],

              // Giá
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.monetization_on_outlined,
                    size: 13, color: widget.roleColor.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                      () {
                    final price = widget.roleField == 'photographerId'
                        ? (data['photographerPrice'] as num?)?.toInt() ?? 0
                        : (data['makeuperPrice'] as num?)?.toInt() ?? 0;
                    return price > 0 ? '${_fmtPrice(price)}đ' : 'Chưa có giá';
                  }(),
                  style: TextStyle(
                    color: widget.roleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ],
          )),
        ]),
      ),
    ]);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime d) {
    const months = ['Tháng 1','Tháng 2','Tháng 3','Tháng 4','Tháng 5','Tháng 6',
      'Tháng 7','Tháng 8','Tháng 9','Tháng 10','Tháng 11','Tháng 12'];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _fmtPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}