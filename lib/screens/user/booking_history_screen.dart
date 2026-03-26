// lib/screens/user/booking_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';
import '../shared/public_profile_screen.dart';
import '../payment/payment_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  final bool showBackButton;
  const BookingHistoryScreen({super.key,this.showBackButton = false});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final currentUser = context.read<AuthProvider>().currentUser;
    final uid = currentUser?.uid ?? '';
    final role = currentUser?.role.name ?? 'user';
    final color = _colorForRole(role);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: _buildAppBar(isDark, role),
      body: Column(
        children: [
          _buildTabBar(isDark, role, color),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statusFilters.map((filter) {
                return _BookingList(
                  uid: uid,
                  role: role,
                  statusFilter: filter.status,
                  filterColor: filter.color,
                  isDark: isDark,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForRole(String role) {
    switch (role) {
      case 'photographer': return AppTheme.rolePhotographer;
      case 'makeuper': return AppTheme.roleMakeuper;
      default: return AppTheme.roleUser;
    }
  }

  String _titleForRole(String role) {
    switch (role) {
      case 'photographer': return 'Booking của tôi 📸';
      case 'makeuper': return 'Booking của tôi 💄';
      default: return 'Lịch sử đặt lịch';
    }
  }

  PreferredSizeWidget _buildAppBar(bool isDark, String role) {
    final color = _colorForRole(role);
    return AppBar(
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: widget.showBackButton
          ? IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            size: 20),
        onPressed: () => Navigator.pop(context),
      )
          : null,
      title: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.calendar_month_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(_titleForRole(role),
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            )),
      ]),
      actions: [
        IconButton(
          icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: isDark ? Colors.amber : Colors.orange),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark, String role, Color color) {
    return Container(
      color: isDark ? AppTheme.primary : AppTheme.lightBg,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        indicator: BoxDecoration(
          color: color,
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
    );
  }

}

// ── Booking List per tab ──────────────────────────────────────
class _BookingList extends StatelessWidget {
  final String uid;
  final String role;
  final String? statusFilter;
  final Color filterColor;
  final bool isDark;

  const _BookingList({
    required this.uid,
    required this.role,
    required this.statusFilter,
    required this.filterColor,
    required this.isDark,
  });

  String get _queryField {
    switch (role) {
      case 'photographer': return 'photographerId';
      case 'makeuper': return 'makeuperId';
      default: return 'userId';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    Query query;
    if (statusFilter == null) {
      query = FirebaseFirestore.instance
          .collection('bookings')
          .where(_queryField, isEqualTo: uid);
    } else {
      query = FirebaseFirestore.instance
          .collection('bookings')
          .where(_queryField, isEqualTo: uid)
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
          return const Center(child: CircularProgressIndicator(color: AppTheme.roleUser));
        }

        var docs = snap.data?.docs ?? [];
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

// ── Booking Card ──────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final bool isDark;

  const _BookingCard({required this.bookingId, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final paymentStatus = data['paymentStatus'] as String?;
    final statusInfo = _getStatusInfo(status);
    final bookingDate = (data['bookingDate'] as Timestamp?)?.toDate();
    final dateStr = bookingDate != null
        ? '${_weekday(bookingDate.weekday)}, ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'
        : '---';
    final timeSlot = data['timeSlot'] as String? ?? '';
    final photographerName = data['photographerName'] as String?;
    final photographerId = data['photographerId'] as String?;
    final makeuperName = data['makeuperName'] as String?;
    final makeuperId = data['makeuperId'] as String?;
    final address = data['address'] as String? ?? '';
    final note = data['note'] as String?;
    final photographerPrice = (data['photographerPrice'] as num?)?.toInt() ?? 0;
    final makeuperPrice = (data['makeuperPrice'] as num?)?.toInt() ?? 0;
    final totalPrice = photographerPrice + makeuperPrice;

    // Needs payment: confirmed + not paid yet
    final needsPayment = status == 'confirmed' && paymentStatus != 'paid';
    final isPaid = paymentStatus == 'paid';
    // Can complete: paid + status still confirmed
    final canComplete = status == 'confirmed' && isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: needsPayment
              ? Colors.orange.withOpacity(0.5)
              : statusInfo.color.withOpacity(0.3),
          width: needsPayment ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (needsPayment ? Colors.orange : statusInfo.color).withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (needsPayment ? Colors.orange : statusInfo.color).withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Icon(
              needsPayment ? Icons.payment_rounded : statusInfo.icon,
              color: needsPayment ? Colors.orange : statusInfo.color,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              needsPayment ? 'Chờ thanh toán' : statusInfo.label,
              style: TextStyle(
                color: needsPayment ? Colors.orange : statusInfo.color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (isPaid) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_rounded, color: AppTheme.success, size: 10),
                  const SizedBox(width: 3),
                  const Text('Đã thanh toán',
                      style: TextStyle(
                          color: AppTheme.success, fontSize: 9, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
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
            // ── Provider rows ──
            if (photographerName != null)
              _ProviderRow(
                icon: Icons.camera_alt_rounded,
                color: AppTheme.rolePhotographer,
                role: 'Photographer',
                name: photographerName,
                price: photographerPrice,
                isDark: isDark,
                onTap: photographerId != null
                    ? () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(userId: photographerId)))
                    : null,
              ),
            if (photographerName != null && makeuperName != null) const SizedBox(height: 8),
            if (makeuperName != null)
              _ProviderRow(
                icon: Icons.brush_rounded,
                color: AppTheme.roleMakeuper,
                role: 'Makeup Artist',
                name: makeuperName,
                price: makeuperPrice,
                isDark: isDark,
                onTap: makeuperId != null
                    ? () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(userId: makeuperId)))
                    : null,
              ),

            const SizedBox(height: 10),
            Divider(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.12)),
            const SizedBox(height: 8),

            // ── Địa điểm ──
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_rounded, color: Colors.orange, size: 15),
              const SizedBox(width: 6),
              Expanded(child: Text(address,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[700],
                      fontSize: 12, height: 1.4))),
            ]),

            // ── Ghi chú ──
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 15),
                const SizedBox(width: 6),
                Expanded(child: Text(note,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 12, height: 1.4))),
              ]),
            ],

            const SizedBox(height: 12),

            // ── Tổng tiền + nút hành động ──
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tổng tiền',
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(totalPrice > 0 ? '${_formatPrice(totalPrice)}đ' : 'Chưa có giá',
                    style: const TextStyle(
                        color: AppTheme.roleUser,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ]),
              const Spacer(),

              // Action buttons
              if (status == 'pending')
                _OutlineButton(
                  label: 'Hủy booking',
                  color: Colors.red,
                  isDark: isDark,
                  onTap: () => _showCancelDialog(context, bookingId),
                )
              else if (needsPayment)
              // Payment button — most prominent
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          bookingId: bookingId,
                          amount: totalPrice.toDouble(),
                          photographerName: photographerName,
                          makeuperName: makeuperName,
                          bookingDate: dateStr,
                          timeSlot: timeSlot,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.secondary, AppTheme.secondary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.payment_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Thanh toán ngay',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ]),
                  ),
                )
              else if (canComplete)
                  _OutlineButton(
                    label: '✅ Hoàn thành',
                    color: AppTheme.success,
                    isDark: isDark,
                    onTap: () => _showCompleteDialog(context, bookingId,
                        photographerId, makeuperId, totalPrice.toDouble()),
                  )
                else if (status == 'confirmed' && isPaid)
                    _OutlineButton(
                      label: 'Nhắn tin',
                      color: AppTheme.roleUser,
                      isDark: isDark,
                      onTap: () async {
                        final me = context.read<AuthProvider>().currentUser!;
                        final providerId = photographerId ?? makeuperId;
                        final providerName = photographerName ?? makeuperName ?? '';
                        final providerRole = photographerId != null ? 'photographer' : 'makeuper';
                        if (providerId == null) return;
                        try {
                          final chatId = await ChatService.getOrCreateChat(
                            me: me,
                            otherId: providerId,
                            otherName: providerName,
                            otherRole: providerRole,
                          );
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chatId,
                                otherUserId: providerId,
                                otherUserName: providerName,
                                otherUserRole: providerRole,
                              ),
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      },
                    )
                  else if (status == 'completed')
                      _OutlineButton(
                        label: '⭐ Đánh giá',
                        color: Colors.amber,
                        isDark: isDark,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('⭐ Tính năng đánh giá sắp ra mắt!'),
                                behavior: SnackBarBehavior.floating)),
                      ),
            ]),

            // ── Thông báo cần thanh toán ──
            if (needsPayment) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Provider đã xác nhận! Vui lòng thanh toán để booking có hiệu lực.',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey[700],
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ]),
              ),
            ],

            // ── Provider status chips ──
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              _buildProviderStatusChips(),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildProviderStatusChips() {
    final photoStatus = data['photographerStatus'] as String?;
    final makeupStatus = data['makeuperStatus'] as String?;
    final hasPhoto = data['photographerId'] != null;
    final hasMakeup = data['makeuperId'] != null;
    if (!hasPhoto && !hasMakeup) return const SizedBox.shrink();
    return Wrap(spacing: 6, children: [
      if (hasPhoto)
        _StatusChip(
            label: 'Photographer: ${_providerStatusLabel(photoStatus)}',
            color: _providerStatusColor(photoStatus),
            isDark: isDark),
      if (hasMakeup)
        _StatusChip(
            label: 'Makeup: ${_providerStatusLabel(makeupStatus)}',
            color: _providerStatusColor(makeupStatus),
            isDark: isDark),
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
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn hủy booking này không?',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Không',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({'status': 'rejected'});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✅ Đã hủy booking'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Hủy booking',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(
      BuildContext context,
      String bookingId,
      String? photographerId,
      String? makeuperId,
      double amount,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận hoàn thành?',
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn xác nhận đã nhận được dịch vụ và hài lòng?',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppTheme.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sau khi xác nhận, ${_formatPrice(amount.toInt())}đ sẽ được chuyển đến provider.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[700],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Chưa',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _markCompleteAndPayout(
                  context, bookingId, photographerId, makeuperId, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận hoàn thành',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _markCompleteAndPayout(
      BuildContext context,
      String bookingId,
      String? photographerId,
      String? makeuperId,
      double totalAmount,
      ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final bookingRef =
      FirebaseFirestore.instance.collection('bookings').doc(bookingId);

      // Mark booking completed
      batch.update(bookingRef, {
        'status': 'completed',
        'userCompletedAt': FieldValue.serverTimestamp(),
      });

      // Add balance to photographer
      if (photographerId != null) {
        final photoPrice = (data['photographerPrice'] as num?)?.toDouble() ?? 0;
        if (photoPrice > 0) {
          final providerRef =
          FirebaseFirestore.instance.collection('users').doc(photographerId);
          batch.update(providerRef, {
            'balance': FieldValue.increment(photoPrice),
            'totalEarnings': FieldValue.increment(photoPrice),
            'totalBookings': FieldValue.increment(1),
          });

          // Add payout transaction record
          final txRef =
          FirebaseFirestore.instance.collection('transactions').doc();
          batch.set(txRef, {
            'userId': photographerId,
            'bookingId': bookingId,
            'amount': photoPrice,
            'type': 'payout',
            'status': 'completed',
            'description': 'Thanh toán từ booking #${bookingId.substring(0, 8).toUpperCase()}',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Add balance to makeuper
      if (makeuperId != null) {
        final makeupPrice = (data['makeuperPrice'] as num?)?.toDouble() ?? 0;
        if (makeupPrice > 0) {
          final providerRef =
          FirebaseFirestore.instance.collection('users').doc(makeuperId);
          batch.update(providerRef, {
            'balance': FieldValue.increment(makeupPrice),
            'totalEarnings': FieldValue.increment(makeupPrice),
            'totalBookings': FieldValue.increment(1),
          });

          final txRef =
          FirebaseFirestore.instance.collection('transactions').doc();
          batch.set(txRef, {
            'userId': makeuperId,
            'bookingId': bookingId,
            'amount': makeupPrice,
            'type': 'payout',
            'status': 'completed',
            'description': 'Thanh toán từ booking #${bookingId.substring(0, 8).toUpperCase()}',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🎉 Hoàn thành! ${_formatPrice(totalAmount.toInt())}đ đã được chuyển đến provider.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return const _StatusInfo('Đã xác nhận', Icons.check_circle_rounded, Color(0xFF4CAF50));
      case 'completed':
        return const _StatusInfo('Hoàn thành', Icons.done_all_rounded, Colors.blue);
      case 'rejected':
        return const _StatusInfo('Đã hủy', Icons.cancel_rounded, Colors.red);
      default:
        return const _StatusInfo('Chờ xác nhận', Icons.pending_rounded, Colors.orange);
    }
  }

  String _weekday(int w) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[(w - 1).clamp(0, 6)];
  }

  static String _formatPrice(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

// ── Provider Row ──────────────────────────────────────────────
class _ProviderRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String role;
  final String name;
  final int price;
  final bool isDark;
  final VoidCallback? onTap;

  const _ProviderRow({
    required this.icon,
    required this.color,
    required this.role,
    required this.name,
    required this.price,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(name,
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: isDark ? Colors.white38 : Colors.grey),
                ],
              ]),
              Text(role,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w500)),
            ])),
        if (price > 0)
          Text('${_fmt(price)}đ',
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
      ]),
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

// ── Shared Widgets ────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _OutlineButton(
      {required this.label,
        required this.color,
        required this.isDark,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4))),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _StatusChip(
      {required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _EmptyState(
      {required this.icon,
        required this.title,
        required this.subtitle,
        required this.color,
        required this.isDark});

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
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color.withOpacity(0.6), size: 36)),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 13,
                  height: 1.4),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
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