import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';
import '../shared/public_profile_screen.dart';
import '../payment/payment_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  final bool showBackButton;
  const BookingHistoryScreen({super.key, this.showBackButton = false});

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
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: Text(
          role == 'user' ? 'Lịch sử booking' : 'Quản lý booking',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: color,
          labelColor: color,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          tabs: _statusFilters
              .map((f) => Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(f.icon, size: 14),
              const SizedBox(width: 4),
              Text(f.label),
            ]),
          ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statusFilters.map((f) {
          return _BookingList(
            uid: uid,
            role: role,
            statusFilter: f.statusValue,
            filterColor: f.color,
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }

  Color _colorForRole(String role) {
    switch (role) {
      case 'photographer':
        return AppTheme.rolePhotographer;
      case 'makeuper':
        return AppTheme.roleMakeuper;
      default:
        return AppTheme.roleUser;
    }
  }
}

// ── Status Filter model ───────────────────────────────────────
class _StatusFilter {
  final String label;
  final String? statusValue;
  final IconData icon;
  final Color color;
  const _StatusFilter(this.label, this.statusValue, this.icon, this.color);
}

// ── Booking List ──────────────────────────────────────────────
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
      case 'photographer':
        return 'photographerId';
      case 'makeuper':
        return 'makeuperId';
      default:
        return 'userId';
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
          return Center(
              child: CircularProgressIndicator(
                  color: role == 'user' ? AppTheme.roleUser : AppTheme.rolePhotographer));
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
                ? (role == 'user'
                ? 'Hãy đặt lịch ngay để trải nghiệm dịch vụ!'
                : 'Chưa có booking nào được giao đến bạn')
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
            return _BookingCard(
              bookingId: docs[i].id,
              data: data,
              isDark: isDark,
              viewerRole: role,
              viewerUid: uid,
            );
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
  final String viewerRole;
  final String viewerUid;

  const _BookingCard({
    required this.bookingId,
    required this.data,
    required this.isDark,
    required this.viewerRole,
    required this.viewerUid,
  });

  // ── helpers ──────────────────────────────────────────────────
  _StatusInfo _getStatusInfo(String s) {
    switch (s) {
      case 'confirmed':
        return _StatusInfo('Đã xác nhận', Icons.check_circle_rounded, const Color(0xFF4CAF50));
      case 'completed':
        return _StatusInfo('Hoàn thành', Icons.done_all_rounded, Colors.blue);
      case 'rejected':
        return _StatusInfo('Đã hủy', Icons.cancel_rounded, Colors.red);
      default:
        return _StatusInfo('Chờ xác nhận', Icons.pending_rounded, Colors.orange);
    }
  }

  String _weekday(int d) {
    const days = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return d < days.length ? days[d] : '';
  }

  String _formatPrice(int p) {
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

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

    final isPaid = paymentStatus == 'paid';
    final needsPayment = status == 'confirmed' && !isPaid;

    // Delivery proofs
    final photoDeliveryLink = data['photoDeliveryLink'] as String?;
    final makeupProofUrl = data['makeupProofImageUrl'] as String?;

    // Provider-side: has this provider submitted their proof?
    final bool isPhotographer = viewerRole == 'photographer';
    final bool isMakeuper = viewerRole == 'makeuper';
    final bool isUser = viewerRole == 'user';

    // For photographer: need to submit link before completing
    final bool photographerNeedsToSubmit = isPhotographer &&
        status == 'confirmed' &&
        isPaid &&
        (photoDeliveryLink == null || photoDeliveryLink.isEmpty);

    final bool photographerReadyToComplete = isPhotographer &&
        status == 'confirmed' &&
        isPaid &&
        photoDeliveryLink != null &&
        photoDeliveryLink.isNotEmpty;

    // For makeuper: need to upload proof photo before completing
    final bool makeuperNeedsToSubmit = isMakeuper &&
        status == 'confirmed' &&
        isPaid &&
        (makeupProofUrl == null || makeupProofUrl.isEmpty);

    final bool makeuperReadyToComplete = isMakeuper &&
        status == 'confirmed' &&
        isPaid &&
        makeupProofUrl != null &&
        makeupProofUrl.isNotEmpty;

    // For user: can complete when photographer has submitted link (or there's no photographer)
    // makeuper completes independently
    final bool userCanComplete = isUser &&
        status == 'confirmed' &&
        isPaid &&
        (photographerId == null ||
            (photoDeliveryLink != null && photoDeliveryLink.isNotEmpty));

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
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, color: AppTheme.success, size: 10),
                  SizedBox(width: 3),
                  Text('Đã thanh toán',
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
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Provider rows (user view) or Customer row (provider view) ──
            if (isUser) ...[
              if (photographerName != null)
                _ProviderRow(
                  icon: Icons.camera_alt_rounded,
                  color: AppTheme.rolePhotographer,
                  role: 'Photographer',
                  name: photographerName,
                  price: photographerPrice,
                  isDark: isDark,
                  onTap: photographerId != null
                      ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(userId: photographerId)),
                  )
                      : null,
                ),
              if (makeuperName != null) ...[
                if (photographerName != null) const SizedBox(height: 8),
                _ProviderRow(
                  icon: Icons.brush_rounded,
                  color: AppTheme.roleMakeuper,
                  role: 'Makeup Artist',
                  name: makeuperName,
                  price: makeuperPrice,
                  isDark: isDark,
                  onTap: makeuperId != null
                      ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(userId: makeuperId)),
                  )
                      : null,
                ),
              ],
            ] else ...[
              // Provider view: show customer name
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: AppTheme.roleUser.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: AppTheme.roleUser, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['userName'] ?? 'Khách hàng',
                        style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const Text('Khách hàng',
                        style: TextStyle(color: AppTheme.roleUser, fontSize: 11)),
                  ]),
                ),
                Text('${_formatPrice(isPhotographer ? photographerPrice : makeuperPrice)}đ',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ]),
            ],

            const SizedBox(height: 12),

            // ── Address ──
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.location_on_rounded,
                  color: isDark ? Colors.white38 : Colors.grey, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(address,
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 12,
                        height: 1.4)),
              ),
            ]),

            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.notes_rounded,
                    color: isDark ? Colors.white38 : Colors.grey, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(note,
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ),
              ]),
            ],

            const SizedBox(height: 12),

            // ── Total ──
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tổng tiền',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey, fontSize: 13)),
              Text('${_formatPrice(totalPrice)}đ',
                  style: const TextStyle(
                      color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 17)),
            ]),

            const SizedBox(height: 14),

            // ═══════════════════════════════════════════════════
            // ── DELIVERY PROOF SECTION ──
            // ═══════════════════════════════════════════════════

            // Photographer delivery link (visible to all if exists)
            if (photoDeliveryLink != null && photoDeliveryLink.isNotEmpty) ...[
              _DeliveryLinkCard(
                link: photoDeliveryLink,
                isDark: isDark,
                isOwner: isPhotographer,
                label: '📸 Album ảnh từ Photographer',
                onChangeLink: isPhotographer && status == 'confirmed'
                    ? () => _showSubmitLinkDialog(context, bookingId, photoDeliveryLink)
                    : null,
              ),
              const SizedBox(height: 8),
            ],

            // Makeuper proof image (visible to all if exists)
            if (makeupProofUrl != null && makeupProofUrl.isNotEmpty) ...[
              _MakeupProofCard(
                imageUrl: makeupProofUrl,
                isDark: isDark,
                isOwner: isMakeuper,
                onChangePhoto: isMakeuper && status == 'confirmed'
                    ? () => _showUploadMakeupProof(context, bookingId)
                    : null,
              ),
              const SizedBox(height: 8),
            ],

            // ═══════════════════════════════════════════════════
            // ── ACTION BUTTONS ──
            // ═══════════════════════════════════════════════════

            // USER SIDE
            if (isUser) ...[
              if (needsPayment)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => PaymentScreen(
                      bookingId: bookingId,
                      amount: totalPrice.toDouble(),
                      photographerName: data['photographerName'] as String?,
                      makeuperName: data['makeuperName'] as String?,
                      bookingDate: dateStr,
                      timeSlot: timeSlot,
                    ))),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 16),
                    label: const Text('Thanh toán ngay',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                )
              else if (userCanComplete) ...[
                // Show note about photo link if photographer present
                if (photographerId != null &&
                    photoDeliveryLink != null &&
                    photoDeliveryLink.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hãy xem album ảnh từ photographer trước khi xác nhận hoàn thành.',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.blueGrey[700],
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                ],
                _OutlineButton(
                  label: '✅ Hoàn thành',
                  color: AppTheme.success,
                  isDark: isDark,
                  onTap: () => _showCompleteDialog(
                      context, bookingId, photographerId, makeuperId, totalPrice.toDouble()),
                ),
              ] else if (status == 'confirmed' && isPaid && photographerId != null &&
                  (photoDeliveryLink == null || photoDeliveryLink.isEmpty)) ...[
                // Waiting for photographer to submit link
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đang chờ photographer gửi link album ảnh...',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.amber[900],
                            fontSize: 11),
                      ),
                    ),
                  ]),
                ),
              ] else if (status == 'confirmed' && isPaid)
                _OutlineButton(
                  label: 'Nhắn tin',
                  color: AppTheme.roleUser,
                  isDark: isDark,
                  onTap: () => _goToChat(context),
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
            ]

            // PHOTOGRAPHER SIDE
            else if (isPhotographer) ...[
              if (photographerNeedsToSubmit) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.rolePhotographer.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.rolePhotographer.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.link_rounded, color: AppTheme.rolePhotographer, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn cần gửi link album ảnh trước khi có thể nhận thanh toán.',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : AppTheme.rolePhotographer,
                            fontSize: 11,
                            height: 1.4),
                      ),
                    ),
                  ]),
                ),
                _OutlineButton(
                  label: '🔗 Gửi link album ảnh',
                  color: AppTheme.rolePhotographer,
                  isDark: isDark,
                  filled: true,
                  onTap: () => _showSubmitLinkDialog(context, bookingId, null),
                ),
              ] else if (photographerReadyToComplete) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.success.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.hourglass_top_rounded, color: AppTheme.success, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Link đã gửi. Đang chờ khách hàng xác nhận hoàn thành để nhận tiền.',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.green[800],
                            fontSize: 11),
                      ),
                    ),
                  ]),
                ),
              ] else if (status == 'confirmed' && !isPaid) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.payments_outlined, color: Colors.orange, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Đang chờ khách hàng thanh toán...',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.orange[900],
                              fontSize: 11)),
                    ),
                  ]),
                ),
              ] else if (status == 'completed')
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.done_all_rounded, color: Colors.blue, size: 14),
                    SizedBox(width: 8),
                    Text('Booking hoàn thành. Tiền đã được cộng vào ví.',
                        style: TextStyle(color: Colors.blue, fontSize: 11)),
                  ]),
                ),
            ]

            // MAKEUPER SIDE
            else if (isMakeuper) ...[
                if (makeuperNeedsToSubmit) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.roleMakeuper.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.roleMakeuper.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.camera_alt_outlined, color: AppTheme.roleMakeuper, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bạn cần chụp ảnh make up làm bằng chứng trước khi hoàn thành.',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : AppTheme.roleMakeuper,
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                  _OutlineButton(
                    label: '📷 Chụp ảnh bằng chứng',
                    color: AppTheme.roleMakeuper,
                    isDark: isDark,
                    filled: true,
                    onTap: () => _showUploadMakeupProof(context, bookingId),
                  ),
                ] else if (makeuperReadyToComplete) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.success.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.hourglass_top_rounded, color: AppTheme.success, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ảnh đã gửi. Nhấn hoàn thành để nhận thanh toán.',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.green[800],
                              fontSize: 11),
                        ),
                      ),
                    ]),
                  ),
                  _OutlineButton(
                    label: '✅ Hoàn thành & Nhận tiền',
                    color: AppTheme.success,
                    isDark: isDark,
                    filled: true,
                    onTap: () => _showMakeuperCompleteDialog(context, bookingId, makeuperId!),
                  ),
                ] else if (status == 'confirmed' && !isPaid) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.payments_outlined, color: Colors.orange, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Đang chờ khách hàng thanh toán...',
                            style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.orange[900],
                                fontSize: 11)),
                      ),
                    ]),
                  ),
                ] else if (status == 'completed')
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      Icon(Icons.done_all_rounded, color: Colors.blue, size: 14),
                      SizedBox(width: 8),
                      Text('Booking hoàn thành. Tiền đã được cộng vào ví.',
                          style: TextStyle(color: Colors.blue, fontSize: 11)),
                    ]),
                  ),
              ],

            // ── Cancel button (user only, pending/needs payment) ──
            if (isUser && (status == 'pending' || needsPayment)) ...[
              const SizedBox(height: 8),
              _OutlineButton(
                label: 'Hủy booking',
                color: Colors.red,
                isDark: isDark,
                onTap: () => _showCancelDialog(context, bookingId),
              ),
            ],

            // ── Provider status chips (user view, pending booking) ──
            if (isUser && status == 'pending') ...[
              const SizedBox(height: 10),
              _buildProviderStatusChips(),
            ],

            // ── Payment warning ──
            if (isUser && needsPayment) ...[
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
                          height: 1.4),
                    ),
                  ),
                ]),
              ),
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
      case 'confirmed':
        return 'Đã xác nhận ✓';
      case 'rejected':
        return 'Từ chối ✗';
      default:
        return 'Chờ xác nhận...';
    }
  }

  Color _providerStatusColor(String? s) {
    switch (s) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // ── Navigate to chat ──────────────────────────────────────
  void _goToChat(BuildContext context) async {
    final me = context.read<AuthProvider>().currentUser!;
    final photographerId = data['photographerId'] as String?;
    final makeuperId = data['makeuperId'] as String?;
    final photographerName = data['photographerName'] as String?;
    final makeuperName = data['makeuperName'] as String?;
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
        Navigator.push(
            context,
            MaterialPageRoute(
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  // ── Photographer: Submit delivery link ────────────────────
  void _showSubmitLinkDialog(BuildContext context, String bookingId, String? existingLink) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: existingLink ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Gửi link album ảnh',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nhập link Google Drive, Dropbox, hoặc bất kỳ link ảnh nào để gửi cho khách hàng.',
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'https://drive.google.com/...',
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400]),
              filled: true,
              fillColor: isDark ? AppTheme.inputFill : Colors.grey[50],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              prefixIcon:
              Icon(Icons.link_rounded, color: AppTheme.rolePhotographer, size: 18),
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
            keyboardType: TextInputType.url,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final link = ctrl.text.trim();
              if (link.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({'photoDeliveryLink': link});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✅ Đã gửi link album ảnh cho khách hàng!'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rolePhotographer,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Gửi link',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Makeuper: Upload proof photo ──────────────────────────
  void _showUploadMakeupProof(BuildContext context, String bookingId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picker = ImagePicker();

    // Let user choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Chụp ảnh bằng chứng make up',
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text('Ảnh này sẽ được lưu làm bằng chứng hoàn thành dịch vụ',
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.roleMakeuper.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.roleMakeuper.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    Icon(Icons.camera_alt_rounded,
                        color: AppTheme.roleMakeuper, size: 28),
                    const SizedBox(height: 8),
                    Text('Chụp ảnh',
                        style: TextStyle(
                            color: AppTheme.roleMakeuper, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Column(children: [
                    Icon(Icons.photo_library_rounded, color: Colors.blue, size: 28),
                    SizedBox(height: 8),
                    Text('Thư viện',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );

    if (source == null || !context.mounted) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked == null || !context.mounted) return;

    // Show uploading indicator
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Đang upload ảnh bằng chứng...')
        ]),
        duration: Duration(seconds: 30),
        behavior: SnackBarBehavior.floating));

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('makeup_proofs/$bookingId/proof_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'makeupProofImageUrl': url});

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Ảnh bằng chứng đã được upload!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Lỗi upload: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  // ── Makeuper: Complete & receive payment ──────────────────
  void _showMakeuperCompleteDialog(
      BuildContext context, String bookingId, String makeuperId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final makeupPrice = (data['makeuperPrice'] as num?)?.toDouble() ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác nhận hoàn thành?',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn xác nhận đã hoàn thành dịch vụ make up. Số tiền ${_formatPrice(makeupPrice.toInt())}đ sẽ được chuyển vào ví của bạn.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeProviderPayout(
                context: context,
                bookingId: bookingId,
                providerId: makeuperId,
                amount: makeupPrice,
                fieldName: 'makeuperCompletedAt',
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Hoàn thành',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Makeuper payout (Cloud Function approach to avoid permission issues) ──
  Future<void> _executeProviderPayout({
    required BuildContext context,
    required String bookingId,
    required String providerId,
    required double amount,
    required String fieldName,
  }) async {
    try {
      // Use a Firestore transaction so security rules can be properly scoped
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc(bookingId);
        final bookingSnap = await tx.get(bookingRef);
        if (!bookingSnap.exists) throw Exception('Booking không tồn tại');

        final bookingData = bookingSnap.data()!;
        final currentStatus = bookingData['status'] as String?;
        if (currentStatus == 'completed') {
          throw Exception('Booking đã hoàn thành trước đó');
        }

        // Mark payout field
        tx.update(bookingRef, {
          fieldName: FieldValue.serverTimestamp(),
          'makeuperPayoutDone': true,
        });
      });

      // Now update balance separately (requires provider to have write access to own doc)
      final providerRef =
      FirebaseFirestore.instance.collection('users').doc(providerId);
      await providerRef.update({
        'balance': FieldValue.increment(amount),
        'totalEarnings': FieldValue.increment(amount),
        'totalBookings': FieldValue.increment(1),
      });

      // Add transaction record
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': providerId,
        'bookingId': bookingId,
        'amount': amount,
        'type': 'payout',
        'status': 'completed',
        'description':
        'Thanh toán từ booking #${bookingId.substring(0, 8).toUpperCase()}',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
            Text('🎉 Hoàn thành! ${_formatPrice(amount.toInt())}đ đã vào ví!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  // ── Cancel booking ────────────────────────────────────────
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
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Hủy booking',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── User: Complete dialog (releases photographer payment) ─
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
        title: Text('Xác nhận hoàn thành?',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bạn xác nhận đã nhận được dịch vụ và hài lòng?',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💰 Tiền sẽ được chuyển đến provider sau khi bạn xác nhận.',
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.green[800],
                  fontSize: 12),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _completeBookingAsUser(
                  context, bookingId, photographerId, makeuperId, amount);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Xác nhận hoàn thành',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── User payout (releases money to providers) ─────────────
  Future<void> _completeBookingAsUser(
      BuildContext context,
      String bookingId,
      String? photographerId,
      String? makeuperId,
      double totalAmount,
      ) async {
    try {
      // Step 1: Update booking status only (user owns booking)
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'completed',
        'userCompletedAt': FieldValue.serverTimestamp(),
      });

      // Step 2: Update each provider's balance (they own their own user doc)
      // This requires Firestore rules to allow providers to read/write own doc.
      // We call a batch but each write targets the provider's own document.
      // NOTE: User cannot write to other users' docs — use Cloud Function for production.
      // For now, we write directly (requires permissive rules on users collection).

      if (photographerId != null) {
        final photoPrice = (data['photographerPrice'] as num?)?.toDouble() ?? 0;
        if (photoPrice > 0) {
          await FirebaseFirestore.instance.collection('users').doc(photographerId).update({
            'balance': FieldValue.increment(photoPrice),
            'totalEarnings': FieldValue.increment(photoPrice),
            'totalBookings': FieldValue.increment(1),
          });
          await FirebaseFirestore.instance.collection('transactions').add({
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

      if (makeuperId != null) {
        final makeupPrice = (data['makeuperPrice'] as num?)?.toDouble() ?? 0;
        if (makeupPrice > 0) {
          // Only pay makeuper if they haven't already been paid (via their own complete button)
          final alreadyPaid = data['makeuperPayoutDone'] == true;
          if (!alreadyPaid) {
            await FirebaseFirestore.instance.collection('users').doc(makeuperId).update({
              'balance': FieldValue.increment(makeupPrice),
              'totalEarnings': FieldValue.increment(makeupPrice),
              'totalBookings': FieldValue.increment(1),
            });
            await FirebaseFirestore.instance.collection('transactions').add({
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
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '🎉 Hoàn thành! ${_formatPrice(totalAmount.toInt())}đ đã được chuyển đến provider.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
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
  }

}

// ── Delivery Link Card ────────────────────────────────────────
class _DeliveryLinkCard extends StatelessWidget {
  final String link;
  final bool isDark;
  final bool isOwner;
  final String label;
  final VoidCallback? onChangeLink;

  const _DeliveryLinkCard({
    required this.link,
    required this.isDark,
    required this.isOwner,
    required this.label,
    this.onChangeLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.rolePhotographer.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.rolePhotographer.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: AppTheme.rolePhotographer,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: Text(link,
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.blueGrey[700],
                    fontSize: 11,
                    decoration: TextDecoration.underline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('📋 Đã copy link vào clipboard'),
                    behavior: SnackBarBehavior.floating));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.rolePhotographer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Copy link',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          if (onChangeLink != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onChangeLink,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_rounded,
                    color: isDark ? Colors.white54 : Colors.grey, size: 14),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ── Makeup Proof Card ─────────────────────────────────────────
class _MakeupProofCard extends StatelessWidget {
  final String imageUrl;
  final bool isDark;
  final bool isOwner;
  final VoidCallback? onChangePhoto;

  const _MakeupProofCard({
    required this.imageUrl,
    required this.isDark,
    required this.isOwner,
    this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.roleMakeuper.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.roleMakeuper.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('💄 Bằng chứng make up',
              style: TextStyle(
                  color: AppTheme.roleMakeuper,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const Spacer(),
          if (onChangePhoto != null)
            GestureDetector(
              onTap: onChangePhoto,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.refresh_rounded,
                      color: isDark ? Colors.white54 : Colors.grey, size: 12),
                  const SizedBox(width: 4),
                  Text('Đổi ảnh',
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () => _showFullImage(context, imageUrl),
            child: Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                color: Colors.grey.withOpacity(0.1),
                child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Nhấn để xem ảnh đầy đủ',
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 10)),
      ]),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────
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

  String _formatPrice(int p) {
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.white30 : Colors.grey, size: 14),
              ],
            ]),
            Text(role, style: TextStyle(color: color, fontSize: 11)),
          ]),
        ),
        Text('${_formatPrice(price)}đ',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ]),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool filled;

  const _OutlineButton({
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(filled ? 0 : 0.5)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: filled ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

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
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Status Info model ─────────────────────────────────────────
class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusInfo(this.label, this.icon, this.color);
}