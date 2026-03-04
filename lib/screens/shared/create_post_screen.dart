// lib/screens/shared/create_post_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng điền đầy đủ tiêu đề và nội dung'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().currentUser!;

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'authorName': user.fullName,
        'authorRole': user.role.name,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'coverImageUrl': null,
        'imageUrls': [],
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã đăng bài thành công!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.read<AuthProvider>().currentUser;
    final isPhotographer = user?.role.name == 'photographer';
    final roleColor =
        isPhotographer ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo bài viết mới',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _publish,
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: roleColor, width: 2),
                  ),
                  child: Icon(
                    isPhotographer
                        ? Icons.camera_alt_rounded
                        : Icons.brush_rounded,
                    color: roleColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? '',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isPhotographer ? 'Photographer' : 'Makeup Artist',
                      style: TextStyle(color: roleColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tiêu đề
            Text('Tiêu đề bài viết',
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Tiêu đề hấp dẫn...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : Colors.grey[400],
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: 2,
            ),

            Divider(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 12),

            // Thêm ảnh (placeholder)
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('🖼️ Upload ảnh sẽ có ở bản tiếp theo!')),
              ),
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.inputFill
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: roleColor.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: roleColor, size: 36),
                    const SizedBox(height: 8),
                    Text('Thêm ảnh bìa',
                        style: TextStyle(
                            color: roleColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('JPG, PNG (tối đa 5MB)',
                        style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nội dung
            Text('Nội dung',
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 15,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText:
                    'Chia sẻ câu chuyện, kinh nghiệm, hoặc giới thiệu dịch vụ của bạn...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : Colors.grey[400],
                    fontSize: 15),
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
              minLines: 8,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
