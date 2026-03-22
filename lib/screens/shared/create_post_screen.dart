import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagSearchCtrl = TextEditingController();

  File? _coverImage;
  final List<File> _extraImages = [];
  final List<Map<String, String>> _taggedUsers = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  // Filter tabs cho tag search
  late TabController _tagTabCtrl;
  static const _tagFilters = [
    ('all', 'Tất cả'),
    ('user', 'Khách hàng'),
    ('photographer', 'Photographer'),
    ('makeuper', 'Makeup Artist'),
  ];

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tagTabCtrl = TabController(length: _tagFilters.length, vsync: this);
    _tagTabCtrl.addListener(() {
      if (!_tagTabCtrl.indexIsChanging) {
        // Re-search với filter mới
        if (_tagSearchCtrl.text.trim().isNotEmpty) {
          _searchUsers(_tagSearchCtrl.text);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagSearchCtrl.dispose();
    _tagTabCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────
  Future<void> _pickCover() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _coverImage = File(picked.path));
  }

  Future<void> _pickExtraImages() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked.isNotEmpty) {
      setState(() {
        for (final p in picked) {
          if (_extraImages.length < 9) _extraImages.add(File(p.path));
        }
      });
    }
  }

  // ── Upload ─────────────────────────────────────────────────
  Future<String?> _uploadImage(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Upload error: $e'); // xem log này
      if (mounted) _snack('Upload lỗi: $e', AppTheme.error);
      return null;
    }
  }

  // ── Tag search (all roles) ─────────────────────────────────
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final myUid = context.read<AuthProvider>().currentUser!.uid;
      final selectedRole = _tagFilters[_tagTabCtrl.index].$1;

      // Build query
      Query q = FirebaseFirestore.instance
          .collection('users')
          .orderBy('fullName')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20);

      // Filter by role if not "all"
      if (selectedRole != 'all') {
        q = FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: selectedRole)
            .orderBy('fullName')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(20);
      }

      final snap = await q.get();

      setState(() {
        _searchResults = snap.docs
            .where((d) => d.id != myUid)
            .map((d) => {
          'uid': d.id,
          'fullName': d['fullName'] as String? ?? '',
          'role': d['role'] as String? ?? 'user',
          'bio': d['bio'] as String? ?? '',
          'rating': d['rating'],
        })
            .toList();
      });
    } catch (_) {
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _addTag(Map<String, dynamic> user) {
    final uid = user['uid'] as String;
    if (_taggedUsers.any((t) => t['uid'] == uid)) return;
    setState(() {
      _taggedUsers.add({
        'uid': uid,
        'fullName': user['fullName'] as String,
        'role': user['role'] as String,
      });
      _tagSearchCtrl.clear();
      _searchResults = [];
    });
  }

  void _removeTag(String uid) =>
      setState(() => _taggedUsers.removeWhere((t) => t['uid'] == uid));

  // ── Publish ────────────────────────────────────────────────
  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _snack('Vui lòng điền tiêu đề và nội dung', AppTheme.error);
      return;
    }
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().currentUser!;

    try {
      // Upload cover
      String? coverUrl;
      if (_coverImage != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        coverUrl = await _uploadImage(
            _coverImage!, 'posts/${user.uid}/${ts}_cover.jpg');
      }

      // Upload extra images
      final List<String> imageUrls = [];
      for (int i = 0; i < _extraImages.length; i++) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final url = await _uploadImage(
            _extraImages[i], 'posts/${user.uid}/${ts}_img$i.jpg');
        if (url != null) imageUrls.add(url);
      }

      // Create post
      final taggedUids = _taggedUsers.map((t) => t['uid']!).toList();
      final postRef =
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'authorName': user.fullName,
        'authorRole': user.role.name,
        'title': title,
        'content': content,
        'coverImageUrl': coverUrl,
        'imageUrls': imageUrls,
        'likeCount': 0,
        'commentCount': 0,
        'taggedUsers': taggedUids,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create post_tag docs
      if (_taggedUsers.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final tag in _taggedUsers) {
          final tagRef =
          FirebaseFirestore.instance.collection('post_tags').doc();
          batch.set(tagRef, {
            'postId': postRef.id,
            'postTitle': title,
            'postCover': coverUrl,
            'taggedUserId': tag['uid'],
            'taggedUserName': tag['fullName'],
            'taggedUserRole': tag['role'],
            'postAuthorId': user.uid,
            'postAuthorName': user.fullName,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      if (mounted) {
        Navigator.pop(context);
        _snack('✅ Đã đăng bài thành công!', AppTheme.success);
      }
    } catch (e) {
      if (mounted) _snack('Lỗi: $e', AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<AuthProvider>().currentUser!;
    final isPhotographer = user.role == UserRole.photographer;
    final isMakeuper = user.role == UserRole.makeuper;
    final isProvider = isPhotographer || isMakeuper;
    final color = isPhotographer
        ? AppTheme.rolePhotographer
        : isMakeuper
        ? AppTheme.roleMakeuper
        : AppTheme.roleUser;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_tagSearchCtrl.text.isEmpty) {
          setState(() => _searchResults = []);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.surface : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isProvider ? 'Đăng portfolio' : 'Chia sẻ trải nghiệm',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Đăng',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              _buildAuthorRow(isDark, user, color, isPhotographer, isMakeuper),
              const SizedBox(height: 20),

              // Cover
              _buildCoverPicker(isDark, color),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: _titleCtrl,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: isProvider
                      ? 'Tiêu đề dự án / buổi chụp...'
                      : 'Tiêu đề bài chia sẻ...',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.grey[400],
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 2,
              ),
              Divider(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 8),

              // Content
              TextField(
                controller: _contentCtrl,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 15,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: isProvider
                      ? 'Mô tả về buổi chụp, phong cách, sản phẩm...'
                      : 'Chia sẻ cảm nhận, trải nghiệm với dịch vụ...',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.grey[400],
                      fontSize: 15),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                minLines: 5,
              ),
              const SizedBox(height: 16),

              // Extra images
              _buildImageStrip(isDark, color),
              const SizedBox(height: 20),

              // ── Tag section ──
              _buildTagSection(isDark, color),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Author row ─────────────────────────────────────────────
  Widget _buildAuthorRow(bool isDark, UserModel user, Color color,
      bool isPhotographer, bool isMakeuper) {
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(
          isPhotographer
              ? Icons.camera_alt_rounded
              : isMakeuper
              ? Icons.brush_rounded
              : Icons.person_rounded,
          color: color,
          size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user.fullName,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            )),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isPhotographer
                ? 'Photographer'
                : isMakeuper
                ? 'Makeup Artist'
                : 'Khách hàng',
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    ]);
  }

  // ── Cover picker ───────────────────────────────────────────
  Widget _buildCoverPicker(bool isDark, Color color) {
    return GestureDetector(
      onTap: _pickCover,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: _coverImage != null ? 220 : 150,
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.inputFill
              : Colors.grey.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
          image: _coverImage != null
              ? DecorationImage(
              image: FileImage(_coverImage!), fit: BoxFit.cover)
              : null,
        ),
        child: _coverImage == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: color, size: 36),
          const SizedBox(height: 8),
          Text('Thêm ảnh bìa',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Nhấn để chọn từ thư viện',
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 12)),
        ])
            : Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => setState(() => _coverImage = null),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Extra image strip ──────────────────────────────────────
  Widget _buildImageStrip(bool isDark, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.photo_library_outlined, color: color, size: 18),
        const SizedBox(width: 6),
        Text('Ảnh thêm (tối đa 9)',
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${_extraImages.length}/9',
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            if (_extraImages.length < 9)
              GestureDetector(
                onTap: _pickExtraImages,
                child: Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.inputFill
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: color, size: 24),
                        const SizedBox(height: 2),
                        Text('Thêm',
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ]),
                ),
              ),
            ..._extraImages.asMap().entries.map((e) {
              return Stack(children: [
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                        image: FileImage(e.value), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 12,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _extraImages.removeAt(e.key)),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ]);
            }),
          ],
        ),
      ),
    ]);
  }

  // ── Tag section ────────────────────────────────────────────
  Widget _buildTagSection(bool isDark, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        Icon(Icons.person_add_alt_1_rounded, color: color, size: 18),
        const SizedBox(width: 6),
        Text('Gắn thẻ người dùng / provider',
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),

      // Tagged chips
      if (_taggedUsers.isNotEmpty) ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _taggedUsers.map((t) {
            final c = _colorFor(t['role']!);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_iconFor(t['role']!), color: c, size: 13),
                const SizedBox(width: 5),
                Text(t['fullName']!,
                    style: TextStyle(
                        color: c,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _removeTag(t['uid']!),
                  child: Icon(Icons.close, color: c, size: 13),
                ),
              ]),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],

      // Role filter tabs
      Container(
        height: 32,
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.inputFill
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: _tagTabCtrl,
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          indicatorPadding: const EdgeInsets.all(3),
          indicator: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
          labelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w400),
          tabs: _tagFilters
              .map((f) => Tab(
            child: Text(f.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ))
              .toList(),
        ),
      ),
      const SizedBox(height: 10),

      // Search field
      Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.inputFill
              : Colors.grey.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.15)),
        ),
        child: TextField(
          controller: _tagSearchCtrl,
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 14),
          onChanged: _searchUsers,
          decoration: InputDecoration(
            hintText: _hintForFilter(),
            hintStyle: TextStyle(
                color: isDark ? Colors.white30 : Colors.grey[400],
                fontSize: 13),
            prefixIcon: _isSearching
                ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.secondary)))
                : Icon(Icons.search_rounded, color: color, size: 20),
            suffixIcon: _tagSearchCtrl.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear_rounded,
                  color: isDark ? Colors.white38 : Colors.grey,
                  size: 18),
              onPressed: () {
                _tagSearchCtrl.clear();
                setState(() => _searchResults = []);
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ),

      // Search results
      if (_searchResults.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A4A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: _searchResults.map((u) {
              final alreadyTagged =
              _taggedUsers.any((t) => t['uid'] == u['uid']);
              final uColor = _colorFor(u['role'] as String);
              final uIcon = _iconFor(u['role'] as String);
              final roleName = _roleNameFor(u['role'] as String);
              final rating =
                  (u['rating'] as num?)?.toDouble() ?? 0.0;

              return InkWell(
                onTap: alreadyTagged ? null : () => _addTag(u),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(children: [
                    // Avatar placeholder
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: uColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: uColor.withOpacity(0.3))),
                      child: Icon(uIcon, color: uColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['fullName'] as String,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.lightTextPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: uColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(roleName,
                                    style: TextStyle(
                                        color: uColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                              if (rating > 0) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 11),
                                const SizedBox(width: 2),
                                Text(rating.toStringAsFixed(1),
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey,
                                        fontSize: 11)),
                              ],
                              if ((u['bio'] as String).isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(u['bio'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey,
                                          fontSize: 11)),
                                ),
                              ],
                            ]),
                          ]),
                    ),
                    const SizedBox(width: 8),
                    if (alreadyTagged)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 20)
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: uColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: uColor.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.add_rounded,
                            color: uColor, size: 16),
                      ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),

      // Empty state when searched but no results
      if (_searchResults.isEmpty &&
          _tagSearchCtrl.text.isNotEmpty &&
          !_isSearching)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Không tìm thấy "${_tagSearchCtrl.text}"',
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 13),
            ),
          ),
        ),
    ]);
  }

  String _hintForFilter() {
    final role = _tagFilters[_tagTabCtrl.index].$1;
    switch (role) {
      case 'photographer':
        return 'Tìm tên Photographer...';
      case 'makeuper':
        return 'Tìm tên Makeup Artist...';
      case 'user':
        return 'Tìm tên khách hàng...';
      default:
        return 'Tìm tên người dùng hoặc provider...';
    }
  }

  Color _colorFor(String role) {
    switch (role) {
      case 'photographer':
        return AppTheme.rolePhotographer;
      case 'makeuper':
        return AppTheme.roleMakeuper;
      default:
        return AppTheme.roleUser;
    }
  }

  IconData _iconFor(String role) {
    switch (role) {
      case 'photographer':
        return Icons.camera_alt_rounded;
      case 'makeuper':
        return Icons.brush_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _roleNameFor(String role) {
    switch (role) {
      case 'photographer':
        return 'Photographer';
      case 'makeuper':
        return 'Makeup Artist';
      default:
        return 'Khách hàng';
    }
  }
}