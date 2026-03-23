// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String otherUserRole;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.otherUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final has = _msgCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    // Đánh dấu đã đọc khi mở chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = context.read<AuthProvider>().currentUser;
      if (me != null) {
        ChatService.markAsRead(chatId: widget.chatId, myId: me.uid);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final me = context.read<AuthProvider>().currentUser!;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        sender: me,
        text: text,
        otherUserId: widget.otherUserId,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'photographer':
        return AppTheme.rolePhotographer;
      case 'makeuper':
        return AppTheme.roleMakeuper;
      default:
        return AppTheme.roleUser;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'photographer':
        return 'Photographer';
      case 'makeuper':
        return 'Makeup Artist';
      default:
        return 'Khách hàng';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = context.read<AuthProvider>().currentUser!;
    final roleColor = _roleColor(widget.otherUserRole);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : const Color(0xFFF8F9FA),
      appBar: _buildAppBar(isDark, roleColor),
      body: Column(children: [
        Expanded(child: _buildMessageList(isDark, me.uid)),
        _buildInput(isDark),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color roleColor) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: roleColor.withOpacity(0.4), width: 1.5),
          ),
          child: ClipOval(
            child: widget.otherUserAvatar != null
                ? Image.network(widget.otherUserAvatar!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(roleColor))
                : _avatarFallback(roleColor),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherUserName,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            Text(_roleLabel(widget.otherUserRole),
                style: TextStyle(
                    color: roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded,
              color: isDark ? Colors.white54 : Colors.grey),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _avatarFallback(Color color) {
    return Container(
      color: color.withOpacity(0.15),
      child: Center(
        child: Text(
          widget.otherUserName.isNotEmpty
              ? widget.otherUserName[0].toUpperCase()
              : '?',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMessageList(bool isDark, String myId) {
    return StreamBuilder<QuerySnapshot>(
      stream: ChatService.messagesStream(widget.chatId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.secondary));
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: isDark ? Colors.white24 : Colors.grey[300]),
              const SizedBox(height: 12),
              Text('Bắt đầu cuộc trò chuyện!',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text('Gửi tin nhắn đầu tiên',
                  style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.grey[400],
                      fontSize: 13)),
            ]),
          );
        }

        // Scroll xuống khi có tin mới
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final senderId = data['senderId'] as String? ?? '';
            final isMe = senderId == myId;
            final text = data['text'] as String? ?? '';
            final createdAt =
                (data['createdAt'] as Timestamp?)?.toDate();

            // Kiểm tra xem có cần hiển thị timestamp không
            bool showTime = false;
            if (i == 0) {
              showTime = true;
            } else {
              final prevData =
                  docs[i - 1].data() as Map<String, dynamic>;
              final prevTime =
                  (prevData['createdAt'] as Timestamp?)?.toDate();
              if (prevTime != null && createdAt != null) {
                showTime = createdAt
                        .difference(prevTime)
                        .inMinutes >
                    10;
              }
            }

            // Group: cùng sender liên tiếp
            bool isFirstInGroup = true;
            if (i > 0) {
              final prevData =
                  docs[i - 1].data() as Map<String, dynamic>;
              isFirstInGroup = prevData['senderId'] != senderId;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTime && createdAt != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey[500],
                              fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                _MessageBubble(
                  text: text,
                  isMe: isMe,
                  isFirstInGroup: isFirstInGroup,
                  isDark: isDark,
                  senderName: data['senderName'] as String? ?? '',
                  otherRoleColor:
                      _roleColor(widget.otherUserRole),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInput(bool isDark) {
    return Container(
      color: isDark ? AppTheme.surface : Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(children: [
        // Text field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.inputFill
                  : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.15)),
            ),
            child: TextField(
              controller: _msgCtrl,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhắn tin...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _hasText
                ? AppTheme.secondary
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.15)),
            shape: BoxShape.circle,
            boxShadow: _hasText
                ? [
                    BoxShadow(
                        color: AppTheme.secondary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: GestureDetector(
            onTap: _hasText ? _send : null,
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(Icons.send_rounded,
                    color: _hasText
                        ? Colors.white
                        : (isDark ? Colors.white24 : Colors.grey[400]),
                    size: 20),
          ),
        ),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;

    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Hôm nay  $hm';
    if (diff == 1) return 'Hôm qua  $hm';
    return '${dt.day}/${dt.month}/${dt.year}  $hm';
  }
}

// ── Message Bubble ────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isDark;
  final String senderName;
  final Color otherRoleColor;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.isFirstInGroup,
    required this.isDark,
    required this.senderName,
    required this.otherRoleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 3,
        top: isFirstInGroup ? 8 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 4),
          // Bubble
          GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Đã sao chép'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppTheme.secondary
                      : (isDark
                          ? AppTheme.inputFill
                          : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : (isDark
                            ? Colors.white
                            : AppTheme.lightTextPrimary),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
