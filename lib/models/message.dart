// lib/models/message.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    this.type = MessageType.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'],
      text: data['text'] ?? '',
      type: data['type'] == 'image' ? MessageType.image : MessageType.text,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'text': text,
        'type': type.name,
        'createdAt': createdAt,
        'isRead': isRead,
      };
}

class ChatModel {
  final String id;
  // 2 participants
  final String user1Id;
  final String user1Name;
  final String? user1Avatar;
  final String user1Role;
  final String user2Id;
  final String user2Name;
  final String? user2Avatar;
  final String user2Role;
  // Last message preview
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageSenderId;
  // Unread counts per user
  final int unreadUser1;
  final int unreadUser2;

  ChatModel({
    required this.id,
    required this.user1Id,
    required this.user1Name,
    this.user1Avatar,
    required this.user1Role,
    required this.user2Id,
    required this.user2Name,
    this.user2Avatar,
    required this.user2Role,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderId,
    this.unreadUser1 = 0,
    this.unreadUser2 = 0,
  });

  factory ChatModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatModel(
      id: id,
      user1Id: data['user1Id'] ?? '',
      user1Name: data['user1Name'] ?? '',
      user1Avatar: data['user1Avatar'],
      user1Role: data['user1Role'] ?? 'user',
      user2Id: data['user2Id'] ?? '',
      user2Name: data['user2Name'] ?? '',
      user2Avatar: data['user2Avatar'],
      user2Role: data['user2Role'] ?? 'user',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadUser1: data['unreadUser1'] ?? 0,
      unreadUser2: data['unreadUser2'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'user1Id': user1Id,
        'user1Name': user1Name,
        'user1Avatar': user1Avatar,
        'user1Role': user1Role,
        'user2Id': user2Id,
        'user2Name': user2Name,
        'user2Avatar': user2Avatar,
        'user2Role': user2Role,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt,
        'lastMessageSenderId': lastMessageSenderId,
        'unreadUser1': unreadUser1,
        'unreadUser2': unreadUser2,
      };

  // Tiện ích: lấy thông tin của người kia
  String otherUserId(String myId) => user1Id == myId ? user2Id : user1Id;
  String otherUserName(String myId) =>
      user1Id == myId ? user2Name : user1Name;
  String? otherUserAvatar(String myId) =>
      user1Id == myId ? user2Avatar : user1Avatar;
  String otherUserRole(String myId) =>
      user1Id == myId ? user2Role : user1Role;
  int myUnread(String myId) => user1Id == myId ? unreadUser1 : unreadUser2;
}
