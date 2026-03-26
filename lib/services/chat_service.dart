// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;

  // ── Tạo hoặc lấy chatId giữa 2 user ──────────────────────
  static String _chatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Tạo chat nếu chưa có, trả về chatId
  static Future<String> getOrCreateChat({
    required UserModel me,
    required String otherId,
    required String otherName,
    required String otherRole,
    String? otherAvatar,
  }) async {
    final chatId = _chatId(me.uid, otherId);
    final ref = _db.collection('chats').doc(chatId);
    final snap = await ref.get();

    if (!snap.exists) {
      // user1 = alphabetically first uid
      final sorted = [me.uid, otherId]..sort();
      final isUser1 = me.uid == sorted[0];

      await ref.set({
        'user1Id': sorted[0],
        'user1Name': isUser1 ? me.fullName : otherName,
        'user1Avatar': isUser1 ? me.avatarUrl : otherAvatar,
        'user1Role': isUser1 ? me.role.name : otherRole,
        'user2Id': sorted[1],
        'user2Name': isUser1 ? otherName : me.fullName,
        'user2Avatar': isUser1 ? otherAvatar : me.avatarUrl,
        'user2Role': isUser1 ? otherRole : me.role.name,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadUser1': 0,
        'unreadUser2': 0,
      });
    }
    return chatId;
  }

  // ── Gửi tin nhắn ─────────────────────────────────────────
  static Future<void> sendMessage({
    required String chatId,
    required UserModel sender,
    required String text,
    required String otherUserId,
  }) async {
    if (text.trim().isEmpty) return;

    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final batch = _db.batch();

    // Thêm message
    batch.set(msgRef, {
      'senderId': sender.uid,
      'senderName': sender.fullName,
      'senderAvatar': sender.avatarUrl,
      'text': text.trim(),
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Cập nhật chat doc
    final chatSnap = await chatRef.get();
    final data = chatSnap.data()!;
    final isUser1 = data['user1Id'] == sender.uid;

    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': sender.uid,
      // Tăng unread của người nhận
      if (isUser1) 'unreadUser2': FieldValue.increment(1),
      if (!isUser1) 'unreadUser1': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ── Stream messages ───────────────────────────────────────
  static Stream<QuerySnapshot> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ── Stream danh sách chat của 1 user ──────────────────────
  static Stream<QuerySnapshot> chatsStream(String uid) {
    // Firestore không hỗ trợ OR query trực tiếp nên dùng 2 stream
    // merge ở UI layer. Trả về stream user1
    return _db
        .collection('chats')
        .where('user1Id', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> chatsStream2(String uid) {
    return _db
        .collection('chats')
        .where('user2Id', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  // ── Đánh dấu đã đọc ──────────────────────────────────────
  static Future<void> markAsRead({
    required String chatId,
    required String myId,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final snap = await chatRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final isUser1 = data['user1Id'] == myId;
    await chatRef.update({
      if (isUser1) 'unreadUser1': 0,
      if (!isUser1) 'unreadUser2': 0,
    });
  }

  // ── Tổng unread của 1 user (dùng cho badge) ───────────────
  static Stream<int> totalUnreadStream(String uid) {
    // Merge 2 stream trong service không dễ,
    // dùng cách đơn giản: query cả 2 và tính tổng ở UI
    return _db
        .collection('chats')
        .where('user1Id', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.fold<int>(
            0,
            (sum, doc) =>
                sum + ((doc.data()['unreadUser1'] as int?) ?? 0)));
  }
}
