// lib/screens/shared/tag_requests_screen.dart
//
// Màn hình xem & xử lý các yêu cầu gắn thẻ:
//   - Pending → Accept / Reject
//   - Accepted → Ẩn tag (remove from profile)
//   - Hiển thị badge số lượng pending ở ngoài

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class TagRequestsScreen extends StatelessWidget {
  const TagRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.read<AuthProvider>().currentUser!.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.surface : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Bài viết gắn thẻ',
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
          centerTitle: true,
          bottom: TabBar(
            labelColor: AppTheme.secondary,
            unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 2,
            dividerColor: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.15),
            tabs: const [
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã chấp nhận'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TagList(
                uid: uid,
                status: 'pending',
                isDark: isDark),
            _TagList(
                uid: uid,
                status: 'accepted',
                isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _TagList extends StatelessWidget {
  final String uid;
  final String status;
  final bool isDark;

  const _TagList(
      {required this.uid,
      required this.status,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('post_tags')
          .where('taggedUserId', isEqualTo: uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.secondary));
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.08),
                    shape: BoxShape.circle),
                child: Icon(
                  status == 'pending'
                      ? Icons.notifications_none_rounded
                      : Icons.check_circle_outline_rounded,
                  color: AppTheme.secondary.withOpacity(0.4),
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                status == 'pending'
                    ? 'Không có yêu cầu nào'
                    : 'Chưa có bài nào được chấp nhận',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _TagCard(
              tagId: docs[i].id,
              data: data,
              isDark: isDark,
              status: status,
            );
          },
        );
      },
    );
  }
}

class _TagCard extends StatelessWidget {
  final String tagId;
  final Map<String, dynamic> data;
  final bool isDark;
  final String status;

  const _TagCard({
    required this.tagId,
    required this.data,
    required this.isDark,
    required this.status,
  });

  Future<void> _updateStatus(
      BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('post_tags')
          .doc(tagId)
          .update({'status': newStatus});
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

  @override
  Widget build(BuildContext context) {
    final authorName = data['postAuthorName'] as String? ?? '';
    final postTitle = data['postTitle'] as String? ?? 'Bài viết';
    final coverUrl = data['postCover'] as String?;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final timeStr = createdAt != null
        ? _timeAgo(createdAt)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'pending'
              ? Colors.orange.withOpacity(0.35)
              : AppTheme.success.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (status == 'pending' ? Colors.orange : AppTheme.success)
                .withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: coverUrl != null
                  ? Image.network(coverUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(postTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.lightTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'pending'
                            ? Colors.orange.withOpacity(0.12)
                            : AppTheme.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status == 'pending'
                            ? 'Chờ duyệt'
                            : 'Đã hiện',
                        style: TextStyle(
                          color: status == 'pending'
                              ? Colors.orange
                              : AppTheme.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.person_outline_rounded,
                        size: 12,
                        color: isDark
                            ? Colors.white38
                            : Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('$authorName gắn thẻ bạn',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey[600],
                            fontSize: 12)),
                  ]),
                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(timeStr,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey[400],
                            fontSize: 11)),
                  ],
                  const SizedBox(height: 10),

                  // Action buttons
                  if (status == 'pending')
                    Row(children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Từ chối',
                          color: AppTheme.error,
                          filled: false,
                          onTap: () => _updateStatus(context, 'rejected'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _ActionBtn(
                          label: 'Chấp nhận',
                          color: AppTheme.success,
                          filled: true,
                          onTap: () => _updateStatus(context, 'accepted'),
                        ),
                      ),
                    ])
                  else if (status == 'accepted')
                    _ActionBtn(
                      label: 'Ẩn khỏi trang cá nhân',
                      color: AppTheme.error,
                      filled: false,
                      onTap: () => _updateStatus(context, 'rejected'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: isDark
          ? AppTheme.inputFill
          : Colors.grey.withOpacity(0.1),
      child: Icon(Icons.image_outlined,
          color: isDark ? Colors.white24 : Colors.grey[300],
          size: 24),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: filled ? color : color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: filled ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ── Helper: pending count badge ────────────────────────────
// Dùng trong profile_screen để hiện badge

class PendingTagBadge extends StatelessWidget {
  final String uid;
  final Widget child;

  const PendingTagBadge(
      {super.key, required this.uid, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('post_tags')
          .where('taggedUserId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) return child;
        return Stack(clipBehavior: Clip.none, children: [
          child,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
