// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../shared/public_profile_screen.dart';

// ── Danh sách sticker ─────────────────────────────────────────
const List<String> _kStickers = [
  'assets/stickers/2.png',
  'assets/stickers/3.png',
  'assets/stickers/4.png',
  'assets/stickers/5.png',
  'assets/stickers/6.png',
  'assets/stickers/7.png',
  'assets/stickers/8.png',
  'assets/stickers/9.png',
  'assets/stickers/10.png',
];

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
  // myId được lấy 1 lần, không cần rebuild lại
  late final String _myId;
  late final bool _isDark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = context.read<AuthProvider>().currentUser;
      if (me != null) {
        ChatService.markAsRead(chatId: widget.chatId, myId: me.uid);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy myId 1 lần duy nhất — không dùng watch để tránh rebuild
    _myId = context.read<AuthProvider>().currentUser?.uid ?? '';
    _isDark = Theme.of(context).brightness == Brightness.dark;
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

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: widget.otherUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // build() CHỈ gọi 1 lần khi mở màn — các widget con tự quản lý state
    return Scaffold(
      backgroundColor: _isDark ? AppTheme.primary : const Color(0xFFF5F5F5),
      appBar: _ChatAppBar(
        isDark: _isDark,
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
        otherUserAvatar: widget.otherUserAvatar,
        otherUserRole: widget.otherUserRole,
        roleColor: _roleColor(widget.otherUserRole),
        roleLabel: _roleLabel(widget.otherUserRole),
        onProfileTap: _navigateToProfile,
      ),
      body: Column(
        children: [
          // Message list — widget riêng, tự quản lý stream
          Expanded(
            child: _MessageList(
              chatId: widget.chatId,
              myId: _myId,
              isDark: _isDark,
              otherUserRole: widget.otherUserRole,
              roleColor: _roleColor(widget.otherUserRole),
            ),
          ),
          // Input bar — widget riêng, tự quản lý text state + sticker panel
          _InputBar(
            chatId: widget.chatId,
            myId: _myId,
            otherUserId: widget.otherUserId,
            isDark: _isDark,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// AppBar — PreferredSizeWidget riêng, không rebuild cùng body
// ══════════════════════════════════════════════════════════════
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String otherUserRole;
  final Color roleColor;
  final String roleLabel;
  final VoidCallback onProfileTap;

  const _ChatAppBar({
    required this.isDark,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.otherUserRole,
    required this.roleColor,
    required this.roleLabel,
    required this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _avatarFallback() {
    return Container(
      color: roleColor.withOpacity(0.15),
      child: Center(
        child: Text(
          otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
          style: TextStyle(
              color: roleColor, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: onProfileTap,
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withOpacity(0.4), width: 1.5),
            ),
            child: ClipOval(
              child: otherUserAvatar != null
                  ? Image.network(otherUserAvatar!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback())
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherUserName,
                      style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Row(children: [
                    Text(roleLabel,
                        style: TextStyle(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: roleColor, size: 9),
                  ]),
                ]),
          ),
        ]),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded,
              color: isDark ? Colors.white54 : Colors.grey),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Message List — StatefulWidget riêng với AutomaticKeepAlive
// Chỉ rebuild khi stream Firestore có data mới
// ══════════════════════════════════════════════════════════════
class _MessageList extends StatefulWidget {
  final String chatId;
  final String myId;
  final bool isDark;
  final String otherUserRole;
  final Color roleColor;

  const _MessageList({
    required this.chatId,
    required this.myId,
    required this.isDark,
    required this.otherUserRole,
    required this.roleColor,
  });

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList>
    with AutomaticKeepAliveClientMixin {
  final _scrollCtrl = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Hôm nay  $hm';
    if (diff == 1) return 'Hôm qua  $hm';
    return '${dt.day}/${dt.month}/${dt.year}  $hm';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                  color:
                  widget.isDark ? Colors.white24 : Colors.grey[300]),
              const SizedBox(height: 12),
              Text('Bắt đầu cuộc trò chuyện!',
                  style: TextStyle(
                      color: widget.isDark
                          ? Colors.white38
                          : Colors.grey[400],
                      fontSize: 14)),
            ]),
          );
        }

        // Scroll xuống khi có tin nhắn mới
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: docs.length,
          // Dùng itemExtent = null + cacheExtent lớn để tránh rebuild
          cacheExtent: 500,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final senderId = data['senderId'] as String? ?? '';
            final isMe = senderId == widget.myId;
            final type = data['type'] as String? ?? 'text';
            final text = data['text'] as String? ?? '';
            final createdAt =
                (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();

            final isFirstInGroup = index == 0 ||
                (docs[index - 1].data()
                as Map<String, dynamic>)['senderId'] !=
                    senderId;

            final nextCreatedAt = index < docs.length - 1
                ? ((docs[index + 1].data()
            as Map<String, dynamic>)['createdAt']
            as Timestamp?)
                ?.toDate()
                : null;
            final showTime = index == docs.length - 1 ||
                nextCreatedAt == null ||
                createdAt.difference(nextCreatedAt).abs().inMinutes > 5;

            return Column(
              children: [
                if (showTime)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                              color: widget.isDark
                                  ? Colors.white38
                                  : Colors.grey[500],
                              fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                if (type == 'sticker')
                  _StickerBubble(
                    assetPath: text,
                    isMe: isMe,
                    isFirstInGroup: isFirstInGroup,
                  )
                else
                  _MessageBubble(
                    text: text,
                    isMe: isMe,
                    isFirstInGroup: isFirstInGroup,
                    isDark: widget.isDark,
                    senderName: data['senderName'] as String? ?? '',
                    otherRoleColor: widget.roleColor,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Input Bar — StatefulWidget riêng
// Chỉ rebuild khi gõ text hoặc toggle sticker panel
// KHÔNG làm rebuild _MessageList
// ══════════════════════════════════════════════════════════════
class _InputBar extends StatefulWidget {
  final String chatId;
  final String myId;
  final String otherUserId;
  final bool isDark;

  const _InputBar({
    required this.chatId,
    required this.myId,
    required this.otherUserId,
    required this.isDark,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  bool _hasText = false;
  bool _showStickerPanel = false;

  late AnimationController _stickerAnim;
  late Animation<double> _stickerSlide;

  @override
  void initState() {
    super.initState();
    _stickerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _stickerSlide =
        CurvedAnimation(parent: _stickerAnim, curve: Curves.easeOutCubic);

    _msgCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = _msgCtrl.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_onTextChanged);
    _msgCtrl.dispose();
    _stickerAnim.dispose();
    super.dispose();
  }

  void _toggleStickerPanel() {
    if (_showStickerPanel) {
      _stickerAnim.reverse().then((_) {
        if (mounted) setState(() => _showStickerPanel = false);
      });
    } else {
      setState(() => _showStickerPanel = true);
      _stickerAnim.forward();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final me = context.read<AuthProvider>().currentUser;
    if (me == null) return;

    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        sender: me,
        text: text,
        otherUserId: widget.otherUserId,
      );
    } catch (e) {
      debugPrint('send error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendSticker(String asset) async {
    if (_sending) return;
    final me = context.read<AuthProvider>().currentUser;
    if (me == null) return;

    setState(() => _sending = true);
    try {
      await ChatService.sendSticker(
        chatId: widget.chatId,
        sender: me,
        stickerAsset: asset,
        otherUserId: widget.otherUserId,
      );
      _stickerAnim.reverse().then((_) {
        if (mounted) setState(() => _showStickerPanel = false);
      });
    } catch (e) {
      debugPrint('sendSticker error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Input row ───────────────────────────────────────
        Container(
          color: widget.isDark ? AppTheme.surface : Colors.white,
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: Row(children: [
            // Sticker button
            GestureDetector(
              onTap: _toggleStickerPanel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _showStickerPanel
                      ? AppTheme.secondary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _showStickerPanel
                      ? Icons.emoji_emotions_rounded
                      : Icons.emoji_emotions_outlined,
                  color: _showStickerPanel
                      ? AppTheme.secondary
                      : (widget.isDark ? Colors.white54 : Colors.grey[500]),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppTheme.inputFill
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.15)),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  style: TextStyle(
                      color: widget.isDark
                          ? Colors.white
                          : AppTheme.lightTextPrimary,
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nhắn tin...',
                    hintStyle: TextStyle(
                        color: widget.isDark
                            ? Colors.white38
                            : Colors.grey[400],
                        fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onTap: () {
                    if (_showStickerPanel) {
                      _stickerAnim.reverse().then((_) {
                        if (mounted) {
                          setState(() => _showStickerPanel = false);
                        }
                      });
                    }
                  },
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
                    : (widget.isDark
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
                        : (widget.isDark
                        ? Colors.white24
                        : Colors.grey[400]),
                    size: 20),
              ),
            ),
          ]),
        ),

        // ── Sticker panel ───────────────────────────────────
        if (_showStickerPanel)
          SizeTransition(
            sizeFactor: _stickerSlide,
            axisAlignment: -1,
            child: _StickerPanel(
              isDark: widget.isDark,
              onSelect: _sendSticker,
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Sticker Panel — StatelessWidget, không rebuild khi gõ text
// ══════════════════════════════════════════════════════════════
class _StickerPanel extends StatelessWidget {
  final bool isDark;
  final void Function(String asset) onSelect;

  const _StickerPanel({required this.isDark, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      color: isDark ? AppTheme.surface : Colors.white,
      child: Column(children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _kStickers.length,
            itemBuilder: (context, index) {
              final asset = _kStickers[index];
              return GestureDetector(
                onTap: () => onSelect(asset),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🎭', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Sticker Bubble
// ══════════════════════════════════════════════════════════════
class _StickerBubble extends StatelessWidget {
  final String assetPath;
  final bool isMe;
  final bool isFirstInGroup;

  const _StickerBubble({
    required this.assetPath,
    required this.isMe,
    required this.isFirstInGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: 3, top: isFirstInGroup ? 8 : 0),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Image.asset(
              assetPath,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Text('🎭', style: TextStyle(fontSize: 60)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Message Bubble — const constructor để Flutter cache widget
// ══════════════════════════════════════════════════════════════
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
      padding:
      EdgeInsets.only(bottom: 3, top: isFirstInGroup ? 8 : 0),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 4),
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
                      : (isDark ? AppTheme.inputFill : Colors.white),
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
                        : (isDark ? Colors.white : AppTheme.lightTextPrimary),
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