// lib/screens/user/post_feed_screen.dart
// Feed kiểu Instagram — tap ảnh/tiêu đề → PostDetailScreen
// Double-tap ảnh → Like, single tap ảnh → mở ImageViewer

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/post_model.dart';
import '../../services/auth_provider.dart';
import '../shared/post_Detail_Screen.dart';
import '../shared/image_viewer_screen.dart';

class PostFeedScreen extends StatefulWidget {
  const PostFeedScreen({super.key});

  @override
  State<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends State<PostFeedScreen> {
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.primary : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(child: _buildFilterChips(isDark)),
          _buildPostList(isDark),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      title: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.secondary, Color(0xFFFF6B8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_stories_rounded,
              color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          'Bài viết',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      ('Tất cả', Icons.grid_view_rounded),
      ('Photographer', Icons.camera_alt_rounded),
      ('Makeup', Icons.brush_rounded),
    ];
    final colors = [
      AppTheme.secondary,
      AppTheme.rolePhotographer,
      AppTheme.roleMakeuper,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (i) {
            final sel = _filterIndex == i;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _filterIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? colors[i]
                      : (isDark ? AppTheme.inputFill : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: sel
                      ? [BoxShadow(color: colors[i].withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(filters[i].$2, size: 14,
                      color: sel ? Colors.white : (isDark ? Colors.white54 : Colors.grey)),
                  const SizedBox(width: 6),
                  Text(filters[i].$1,
                      style: TextStyle(
                        color: sel ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      )),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }

  SliverList _buildPostList(bool isDark) {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true);

    if (_filterIndex == 1) query = query.where('authorRole', isEqualTo: 'photographer');
    else if (_filterIndex == 2) query = query.where('authorRole', isEqualTo: 'makeuper');

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, _) => StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Column(children: List.generate(3, (_) => _SkeletonCard(isDark: isDark)));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                child: Column(children: [
                  Container(width: 80, height: 80,
                      decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.auto_stories_rounded, color: AppTheme.secondary.withOpacity(0.5), size: 36)),
                  const SizedBox(height: 16),
                  Text('Chưa có bài viết nào',
                      style: TextStyle(color: isDark ? Colors.white70 : AppTheme.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Các bài viết từ photographer & makeup artist\nsẽ xuất hiện ở đây',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 13, height: 1.5)),
                ]),
              );
            }
            return Column(
              children: docs.map((doc) {
                final post = PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                return _PostCard(post: post, isDark: isDark);
              }).toList(),
            );
          },
        ),
        childCount: 1,
      ),
    );
  }
}

// ── Post Card ──────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final PostModel post;
  final bool isDark;
  const _PostCard({required this.post, required this.isDark});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> with SingleTickerProviderStateMixin {
  bool _liked = false;
  bool _showHeart = false;
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_heartCtrl);
    _heartOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartCtrl);
    _heartCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _showHeart = false);
    });
    _checkLiked();
  }

  @override
  void dispose() { _heartCtrl.dispose(); super.dispose(); }

  Future<void> _checkLiked() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('posts').doc(widget.post.id).collection('likes').doc(uid).get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    final likeRef = postRef.collection('likes').doc(uid);
    setState(() {
      _liked = !_liked;
      if (_liked) { _showHeart = true; _heartCtrl.forward(from: 0); }
    });
    if (_liked) {
      await likeRef.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      await postRef.update({'likeCount': FieldValue.increment(1)});
    } else {
      await likeRef.delete();
      await postRef.update({'likeCount': FieldValue.increment(-1)});
    }
  }

  void _doubleTapLike() {
    if (!_liked) _toggleLike();
    setState(() { _showHeart = true; _heartCtrl.forward(from: 0); });
  }

  void _openViewer(int index) {
    final allImages = [
      if (widget.post.coverImageUrl != null) widget.post.coverImageUrl!,
      ...widget.post.imageUrls,
    ];
    if (allImages.isEmpty) return;
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => ImageViewerScreen(
        imageUrls: allImages, initialIndex: index,
        heroTag: 'post_img_${widget.post.id}',
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  void _openDetail() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PostDetailScreen(
          post: widget.post, heroTag: 'post_img_${widget.post.id}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = widget.isDark;
    final isPhoto = post.authorRole == 'photographer';
    final roleColor = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    final hasImage = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppTheme.inputFill.withOpacity(0.5) : Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header → detail
        GestureDetector(onTap: _openDetail, child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isPhoto
                    ? [AppTheme.secondary, const Color(0xFFFF6B8A)]
                    : [AppTheme.roleMakeuper, const Color(0xFF9C27B0)]),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: isDark ? AppTheme.inputFill : Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: roleColor.withOpacity(0.15),
                  backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
                  child: post.authorAvatar == null
                      ? Icon(isPhoto ? Icons.camera_alt_rounded : Icons.brush_rounded, color: roleColor, size: 16)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.authorName,
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(isPhoto ? 'Photographer' : 'Makeup Artist',
                    style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ])),
            GestureDetector(
              onTap: () => _showOptions(context, post, isDark),
              child: Padding(padding: const EdgeInsets.all(8),
                  child: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.white54 : Colors.grey)),
            ),
          ]),
        )),

        // Image: single tap = viewer, double tap = like
        if (hasImage)
          GestureDetector(
            onTap: () => _openViewer(0),
            onDoubleTap: _doubleTapLike,
            child: Stack(alignment: Alignment.center, children: [
              Hero(
                tag: 'post_img_${post.id}',
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(post.coverImageUrl!, fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                            color: isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.1),
                            child: Center(child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
                                color: AppTheme.secondary, strokeWidth: 2)));
                      },
                      errorBuilder: (_, __, ___) => Container(
                          height: 300,
                          color: isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.1),
                          child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40)))),
                ),
              ),
              if (_showHeart)
                AnimatedBuilder(animation: _heartCtrl, builder: (_, __) =>
                    Opacity(opacity: _heartOpacity.value,
                        child: Transform.scale(scale: _heartScale.value,
                            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 90,
                                shadows: [Shadow(color: Colors.black38, blurRadius: 20)])))),
              if (post.imageUrls.isNotEmpty)
                Positioned(top: 10, right: 10,
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.collections_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text('${post.imageUrls.length + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]))),
              Positioned(bottom: 10, right: 10,
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(10)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 13),
                        SizedBox(width: 3),
                        Text('Phóng to', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ]))),
            ]),
          ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(children: [
            GestureDetector(onTap: _toggleLike,
                child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Padding(padding: const EdgeInsets.all(8),
                        child: Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            key: ValueKey(_liked),
                            color: _liked ? Colors.red : (isDark ? Colors.white70 : Colors.grey[700]), size: 26)))),
            GestureDetector(onTap: _openDetail,
                child: Padding(padding: const EdgeInsets.all(8),
                    child: Icon(Icons.chat_bubble_outline_rounded,
                        color: isDark ? Colors.white70 : Colors.grey[700], size: 24))),
            Padding(padding: const EdgeInsets.all(8),
                child: Icon(Icons.near_me_outlined, color: isDark ? Colors.white70 : Colors.grey[700], size: 24)),
            const Spacer(),
            Padding(padding: const EdgeInsets.all(8),
                child: Icon(Icons.bookmark_border_rounded, color: isDark ? Colors.white70 : Colors.grey[700], size: 24)),
          ]),
        ),

        // Like count realtime
        StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').doc(post.id).snapshots(),
            builder: (context, snap) {
              final count = (snap.data?.data() as Map<String, dynamic>?)?['likeCount'] ?? post.likeCount;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text('$count lượt thích',
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          fontSize: 13, fontWeight: FontWeight.w700)));
            }),

        // Caption → detail
        GestureDetector(onTap: _openDetail,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: RichText(
                    maxLines: 4, overflow: TextOverflow.ellipsis,
                    text: TextSpan(children: [
                      TextSpan(text: '${post.authorName}  ',
                          style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      TextSpan(text: post.title,
                          style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const TextSpan(text: '\n'),
                      TextSpan(text: post.content,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 13, height: 1.5)),
                    ])))),

        // Comment count → detail
        StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').doc(post.id).collection('comments').snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return GestureDetector(onTap: _openDetail,
                  child: Padding(padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                      child: Text('Xem tất cả $count bình luận',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 13))));
            }),

        // Time
        Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(post.timeAgo.toUpperCase(),
                style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400], fontSize: 10, letterSpacing: 0.5))),

        Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
      ]),
    );
  }

  void _showOptions(BuildContext context, PostModel post, bool isDark) {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
        builder: (_) => Container(
          decoration: BoxDecoration(
              color: isDark ? AppTheme.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            if (uid == post.authorId)
              ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Xóa bài viết', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
                  }),
            ListTile(
                leading: Icon(Icons.share_outlined, color: isDark ? Colors.white : AppTheme.lightTextPrimary),
                title: Text('Chia sẻ', style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context)),
            const SizedBox(height: 8),
          ])),
        ));
  }
}

// ── Skeleton ────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});
  @override State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? Colors.white : Colors.grey;
    return AnimatedBuilder(animation: _anim, builder: (_, __) => Opacity(opacity: _anim.value,
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: base.withOpacity(0.15)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 120, height: 12, decoration: BoxDecoration(color: base.withOpacity(0.15), borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 6),
              Container(width: 70, height: 10, decoration: BoxDecoration(color: base.withOpacity(0.1), borderRadius: BorderRadius.circular(6))),
            ]),
          ])),
          AspectRatio(aspectRatio: 1, child: Container(color: base.withOpacity(0.1))),
          const SizedBox(height: 12),
        ])));
  }
}