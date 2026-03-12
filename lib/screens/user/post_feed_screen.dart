// lib/screens/user/post_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/post_model.dart';

class PostFeedScreen extends StatefulWidget {
  const PostFeedScreen({super.key});

  @override
  State<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends State<PostFeedScreen> {
  int _filterIndex = 0; // 0=Tất cả, 1=Photographer, 2=Makeuper

  static const _roleColor = AppTheme.roleUser;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(child: _buildFilterRow(isDark)),
          _buildPostList(isDark),
        ],
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
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: _roleColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.article_rounded, color: _roleColor, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          'Bài viết',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    final filters = ['Tất cả', 'Photographer', 'Makeup Artist'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(filters.length, (i) {
          final sel = _filterIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? _roleColor : (isDark ? AppTheme.inputFill : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? _roleColor : (isDark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Text(
                filters[i],
                style: TextStyle(
                  color: sel ? Colors.white : (isDark ? Colors.white54 : Colors.grey),
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  SliverList _buildPostList(bool isDark) {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true);

    if (_filterIndex == 1) {
      query = query.where('authorRole', isEqualTo: 'photographer');
    } else if (_filterIndex == 2) {
      query = query.where('authorRole', isEqualTo: 'makeuper');
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, _) => StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: _roleColor)),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.article_outlined,
                        size: 48, color: isDark ? Colors.white24 : Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Chưa có bài viết nào',
                        style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final post = PostModel.fromFirestore(
                    doc.data() as Map<String, dynamic>, doc.id);
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

class _PostCard extends StatelessWidget {
  final PostModel post;
  final bool isDark;

  const _PostCard({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final roleColor = post.authorRole == 'photographer'
        ? AppTheme.rolePhotographer
        : AppTheme.roleMakeuper;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Author row
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                post.authorRole == 'photographer'
                    ? Icons.camera_alt_rounded
                    : Icons.brush_rounded,
                color: roleColor, size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  post.authorName,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  post.authorRole == 'photographer' ? 'Photographer' : 'Makeup Artist',
                  style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
            Text(
              post.timeAgo,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey, fontSize: 11),
            ),
          ]),

          const SizedBox(height: 10),

          // Title
          Text(
            post.title,
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700, fontSize: 15, height: 1.3),
          ),
          const SizedBox(height: 6),

          // Content preview
          Text(
            post.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontSize: 13, height: 1.5),
          ),

          const SizedBox(height: 10),

          // Like/comment row
          Row(children: [
            Icon(Icons.favorite_border_rounded,
                size: 16, color: isDark ? Colors.white38 : Colors.grey[400]),
            const SizedBox(width: 4),
            Text('${post.likeCount}',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                    fontSize: 12)),
            const SizedBox(width: 14),
            Icon(Icons.chat_bubble_outline_rounded,
                size: 16, color: isDark ? Colors.white38 : Colors.grey[400]),
            const SizedBox(width: 4),
            Text('${post.commentCount}',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                    fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}
