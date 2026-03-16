// lib/models/service_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String providerId;
  final String providerName;
  final String providerRole; // 'photographer' | 'makeuper'
  final String name;         // Tên dịch vụ
  final String description;  // Mô tả
  final double price;        // Giá
  final String? imageUrl;
  final DateTime createdAt;

  ServiceModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerRole,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.createdAt,
  });

  factory ServiceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ServiceModel(
      id: id,
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      providerRole: data['providerRole'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'providerId': providerId,
    'providerName': providerName,
    'providerRole': providerRole,
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'createdAt': createdAt,
  };

  String get formattedPrice {
    if (price <= 0) return 'Liên hệ';
    final s = price.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return '${buffer.toString()}đ';
  }
}