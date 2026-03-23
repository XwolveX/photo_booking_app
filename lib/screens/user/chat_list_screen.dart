// lib/screens/user/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/message.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.roleUser.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: AppTheme.roleUser, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            'Tin nhắn',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]),
      ),
      body: me == null
          ? const SizedBox.shrink()
          : _ChatListBody(uid: me.uid, isDark: isDark),
    );
  }
}

class _ChatListBody extends StatelessWidget {
  final String uid;
  final bool isDark;

  const _ChatListBody({required this.uid, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Merge 2 stream (user1 và user2) bằng cách dùng StreamBuilder lồng nhau
    return StreamBuilder<QuerySnapshot>(
      stream: ChatService.chatsStream(uid),
      builder: (context, snap1) {
        return StreamBuilder<QuerySnapshot>(
          stream: ChatService.chatsStream2(uid),
          builder: (context, snap2) {
            if (snap1.connectionState == ConnectionState.waiting ||
                snap2.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.secondary));
            }

            // Gộp và sort theo lastMessageAt
            final docs1 = snap1.data?.docs ?? [];
            final docs2 = snap2.data?.docs ?? [];
            final all = [...docs1, ...docs2];
            all.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = (aData['lastMessageAt'] as Timestamp?)
                  ?.toDate() ??
                  DateTime(0);
              final bTime = (bData['lastMessageAt'] as Timestamp?)
                  ?.toDate() ??
                  DateTime(0);
              return bTime.compareTo(aTime);
            });

            if (all.isEmpty) {
              return _buildEmpty(isDark);
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: all.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 80,
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
              ),
              itemBuilder: (context, i) {
                final data =
                    all[i].data() as Map<String, dynamic>;
                final chat = ChatModel.fromFirestore(data, all[i].id);
                return _ChatTile(
                  chat: chat,
                  myId: uid,
                  isDark: isDark,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.roleUser.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                color: AppTheme.roleUser.withOpacity(0.5), size: 44),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đặt lịch và nhắn tin với\nPhotographer & Makeup Artist',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Chat Tile ─────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String myId;
  final bool isDark;

  const _ChatTile(
      {required this.chat, required this.myId, required this.isDark});

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

  @override
  Widget build(BuildContext context) {
    final otherName = chat.otherUserName(myId);
    final otherAvatar = chat.otherUserAvatar(myId);
    final otherRole = chat.otherUserRole(myId);
    final otherId = chat.otherUserId(myId);
    final unread = chat.myUnread(myId);
    final roleColor = _roleColor(otherRole);
    final isLastFromMe = chat.lastMessageSenderId == myId;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.id,
            otherUserId: otherId,
            otherUserName: otherName,
            otherUserAvatar: otherAvatar,
            otherUserRole: otherRole,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Avatar
          Stack(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: roleColor.withOpacity(0.4), width: 1.5),
              ),
              child: ClipOval(
                child: otherAvatar != null
                    ? Image.network(otherAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _fallback(roleColor, otherName))
                    : _fallback(roleColor, otherName),
              ),
            ),
            // Role badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: roleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark ? AppTheme.primary : Colors.white,
                      width: 1.5),
                ),
                child: Icon(
                  otherRole == 'photographer'
                      ? Icons.camera_alt_rounded
                      : otherRole == 'makeuper'
                          ? Icons.brush_rounded
                          : Icons.person_rounded,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      otherName,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppTheme.lightTextPrimary,
                        fontWeight: unread > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    _timeLabel(chat.lastMessageAt),
                    style: TextStyle(
                      color: unread > 0
                          ? AppTheme.secondary
                          : (isDark ? Colors.white38 : Colors.grey),
                      fontSize: 11,
                      fontWeight: unread > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  if (isLastFromMe)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.done_all_rounded,
                          size: 14,
                          color:
                              isDark ? Colors.white38 : Colors.grey[400]),
                    ),
                  Expanded(
                    child: Text(
                      chat.lastMessage.isEmpty
                          ? 'Bắt đầu cuộc trò chuyện'
                          : chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread > 0
                            ? (isDark
                                ? Colors.white70
                                : AppTheme.lightTextPrimary)
                            : (isDark ? Colors.white38 : Colors.grey),
                        fontSize: 13,
                        fontWeight: unread > 0
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _fallback(Color color, String name) {
    return Container(
      color: color.withOpacity(0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff == 1) return 'Hôm qua';
    if (diff < 7) return '${dt.day}/${dt.month}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
