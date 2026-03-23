import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/post_model.dart';
import '../../services/auth_provider.dart';
import 'image_viewer_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  final String? heroTag;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.heroTag,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _liked = false;
  int _likeCount = 0;
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  int _currentImageIndex = 0;
  late PageController _imagePageCtrl;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _imagePageCtrl = PageController();
    _checkLiked();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _imagePageCtrl.dispose();
    super.dispose();
  }

  // ── Helper: lấy màu theo role ──────────────────────────────
  Color _getRoleColor(String role) {
    switch (role) {
      case 'photographer':
        return AppTheme.rolePhotographer;
      case 'makeuper':
        return AppTheme.roleMakeuper;
      default:
        return AppTheme.roleUser;
    }
  }

  // ── Helper: lấy label theo role ────────────────────────────
  String _getRoleLabel(String role) {
    switch (role) {
      case 'photographer':
        return 'Photographer';
      case 'makeuper':
        return 'Makeup Artist';
      default:
        return 'Khách hàng';
    }
  }

  // ── Helper: lấy icon theo role ─────────────────────────────
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'photographer':
        return Icons.camera_alt_rounded;
      case 'makeuper':
        return Icons.brush_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // ── Helper: gradient theo role ─────────────────────────────
  List<Color> _getRoleGradient(String role) {
    switch (role) {
      case 'photographer':
        return [AppTheme.secondary, const Color(0xFFFF6B8A)];
      case 'makeuper':
        return [AppTheme.roleMakeuper, const Color(0xFF9C27B0)];
      default:
        return [AppTheme.roleUser, const Color(0xFF0288D1)];
    }
  }

  Future<void> _checkLiked() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.id)
        .collection('likes')
        .doc(uid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;

    final postRef =
    FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    final likeRef = postRef.collection('likes').doc(uid);

    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });

    if (_liked) {
      await likeRef
          .set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      await postRef.update({'likeCount': FieldValue.increment(1)});
    } else {
      await likeRef.delete();
      await postRef.update({'likeCount': FieldValue.increment(-1)});
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    FocusScope.of(context).unfocus();

    final user = context.read<AuthProvider>().currentUser!;
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .add({
        'uid': user.uid,
        'name': user.fullName,
        'avatar': user.avatarUrl,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({'commentCount': FieldValue.increment(1)});
      _commentCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  void _openImageViewer(int index) {
    final allImages = [
      if (widget.post.coverImageUrl != null) widget.post.coverImageUrl!,
      ...widget.post.imageUrls,
    ];
    if (allImages.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ImageViewerScreen(
          imageUrls: allImages,
          initialIndex: index,
          heroTag: index == 0 ? widget.heroTag : null,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final post = widget.post;
    final roleColor = _getRoleColor(post.authorRole);

    // Gộp tất cả ảnh
    final allImages = [
      if (post.coverImageUrl != null) post.coverImageUrl!,
      ...post.imageUrls,
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── AppBar ──
          _buildAppBar(isDark, post, roleColor),

          // ── Content ──
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Image gallery
                if (allImages.isNotEmpty)
                  SliverToBoxAdapter(
                      child: _buildImageGallery(allImages, isDark, post)),

                // Post info
                SliverToBoxAdapter(
                    child: _buildPostInfo(isDark, post, roleColor)),

                // Comments title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Bình luận',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ]),
                  ),
                ),

                // Comments list
                _buildCommentsList(isDark),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // ── Comment Input ──
          _buildCommentInput(isDark),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark, PostModel post, Color roleColor) {
    return Container(
      color: isDark ? AppTheme.surface : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            // Author avatar với gradient đúng role
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getRoleGradient(post.authorRole),
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surface : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: roleColor.withOpacity(0.15),
                  backgroundImage: post.authorAvatar != null
                      ? NetworkImage(post.authorAvatar!)
                      : null,
                  child: post.authorAvatar == null
                      ? Icon(
                    _getRoleIcon(post.authorRole),
                    color: roleColor,
                    size: 14,
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: TextStyle(
                        color:
                        isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    // ← SỬA: dùng _getRoleLabel thay vì hardcode
                    Text(
                      _getRoleLabel(post.authorRole),
                      style: TextStyle(color: roleColor, fontSize: 11),
                    ),
                  ]),
            ),
            IconButton(
              icon: Icon(Icons.more_horiz_rounded,
                  color: isDark ? Colors.white54 : Colors.grey),
              onPressed: () => _showOptions(context, post, isDark),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildImageGallery(
      List<String> allImages, bool isDark, PostModel post) {
    if (allImages.length == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(0),
        child: Hero(
          tag: widget.heroTag ?? post.id,
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              allImages[0],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: isDark
                      ? AppTheme.inputFill
                      : Colors.grey.withOpacity(0.1),
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.secondary, strokeWidth: 2)),
                );
              },
            ),
          ),
        ),
      );
    }

    // Multiple images — PageView with dots
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _imagePageCtrl,
            itemCount: allImages.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _openImageViewer(i),
              child: i == 0 && widget.heroTag != null
                  ? Hero(
                tag: widget.heroTag!,
                child:
                Image.network(allImages[i], fit: BoxFit.cover),
              )
                  : Image.network(allImages[i], fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                allImages.length,
                    (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImageIndex == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i
                        ? Colors.white
                        : Colors.white60,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${allImages.length}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          right: 12,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 14),
              SizedBox(width: 4),
              Text('Nhấn để phóng to',
                  style: TextStyle(color: Colors.white70, fontSize: 10)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPostInfo(bool isDark, PostModel post, Color roleColor) {
    return Container(
      color: isDark ? AppTheme.inputFill.withOpacity(0.3) : Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(children: [
              GestureDetector(
                onTap: _toggleLike,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(_liked),
                    color: _liked
                        ? Colors.red
                        : (isDark ? Colors.white70 : Colors.grey[700]),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    size: 24),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.near_me_outlined,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    size: 24),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.bookmark_border_rounded,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    size: 24),
              ),
            ]),
          ),
          if (_likeCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                '$_likeCount lượt thích',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '${post.authorName}  ',
                  style: TextStyle(
                    color:
                    isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: post.title,
                  style: TextStyle(
                    color:
                    isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Text(
              post.content,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              post.timeAgo.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white24 : Colors.grey[400],
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.1)),
        ],
      ),
    );
  }

  SliverList _buildCommentsList(bool isDark) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, _) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.post.id)
              .collection('comments')
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.secondary, strokeWidth: 2)),
              );
            }

            final docs = snap.data?.docs ?? [];

            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 36,
                          color:
                          isDark ? Colors.white24 : Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có bình luận nào\nHãy là người đầu tiên!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final createdAt =
                (d['createdAt'] as dynamic)?.toDate() as DateTime?;
                final timeStr =
                createdAt != null ? _timeAgo(createdAt) : '';
                final isMe = d['uid'] ==
                    context.read<AuthProvider>().currentUser?.uid;

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor:
                        AppTheme.secondary.withOpacity(0.15),
                        backgroundImage: d['avatar'] != null
                            ? NetworkImage(d['avatar'])
                            : null,
                        child: d['avatar'] == null
                            ? Text(
                          ((d['name'] as String?) ?? '?')[0]
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: '${d['name'] ?? ''}  ',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.lightTextPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: d['text'] ?? '',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[700],
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () async {
                                    await doc.reference.delete();
                                    await FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(widget.post.id)
                                        .update({
                                      'commentCount':
                                      FieldValue.increment(-1)
                                    });
                                  },
                                  child: Text(
                                    'Xóa',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        childCount: 1,
      ),
    );
  }

  Widget _buildCommentInput(bool isDark) {
    final user = context.read<AuthProvider>().currentUser;
    return Container(
      color: isDark ? AppTheme.surface : Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: AppTheme.secondary.withOpacity(0.15),
          backgroundImage: user?.avatarUrl != null
              ? NetworkImage(user!.avatarUrl!)
              : null,
          child: user?.avatarUrl == null
              ? Text(
            (user?.fullName ?? '?')[0].toUpperCase(),
            style: const TextStyle(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.inputFill
                  : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.15),
              ),
            ),
            child: TextField(
              controller: _commentCtrl,
              style: TextStyle(
                  color:
                  isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 14),
              decoration: InputDecoration(
                hintText:
                'Bình luận với tư cách ${user?.fullName ?? ''}...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              maxLines: null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : _sendComment,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: _sending
                ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.send_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }

  void _showOptions(BuildContext context, PostModel post, bool isDark) {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : Colors.white,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white24
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (uid == post.authorId)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                title: const Text('Xóa bài viết',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(post.id)
                      .delete();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ListTile(
              leading: Icon(Icons.share_outlined,
                  color:
                  isDark ? Colors.white : AppTheme.lightTextPrimary),
              title: Text('Chia sẻ',
                  style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}