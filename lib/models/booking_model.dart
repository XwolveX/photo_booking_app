// lib/models/booking_model.dart

enum BookingStatus { pending, confirmed, rejected, completed, cancelled }

class BookingModel {
  final String id;
  final String userId;
  final String userName;

  // Provider(s) — có thể có cả 2
  final String? photographerId;
  final String? photographerName;
  final double? photographerPrice;

  final String? makeuperId;
  final String? makeuperName;
  final double? makeuperPrice;

  // Thời gian
  final DateTime bookingDate;
  final String timeSlot; // e.g. "09:00"

  // Địa điểm
  final String address;
  final double? latitude;
  final double? longitude;

  // Ghi chú
  final String? note;

  // Trạng thái
  final BookingStatus status;
  final DateTime createdAt;

  // Provider reject/confirm riêng
  final String? photographerStatus; // 'pending' | 'confirmed' | 'rejected'
  final String? makeuperStatus;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.photographerId,
    this.photographerName,
    this.photographerPrice,
    this.makeuperId,
    this.makeuperName,
    this.makeuperPrice,
    required this.bookingDate,
    required this.timeSlot,
    required this.address,
    this.latitude,
    this.longitude,
    this.note,
    required this.status,
    required this.createdAt,
    this.photographerStatus,
    this.makeuperStatus,
  });

  double get totalPrice =>
      (photographerPrice ?? 0) + (makeuperPrice ?? 0);

  String get statusLabel {
    switch (status) {
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.rejected:
        return 'Đã từ chối';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }

  factory BookingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BookingModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      photographerId: data['photographerId'],
      photographerName: data['photographerName'],
      photographerPrice: (data['photographerPrice'] as num?)?.toDouble(),
      makeuperId: data['makeuperId'],
      makeuperName: data['makeuperName'],
      makeuperPrice: (data['makeuperPrice'] as num?)?.toDouble(),
      bookingDate: (data['bookingDate'] as dynamic).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      note: data['note'],
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (data['createdAt'] as dynamic).toDate(),
      photographerStatus: data['photographerStatus'],
      makeuperStatus: data['makeuperStatus'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'photographerId': photographerId,
        'photographerName': photographerName,
        'photographerPrice': photographerPrice,
        'makeuperId': makeuperId,
        'makeuperName': makeuperName,
        'makeuperPrice': makeuperPrice,
        'bookingDate': bookingDate,
        'timeSlot': timeSlot,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'note': note,
        'status': status.name,
        'createdAt': createdAt,
        'photographerStatus': photographerId != null ? 'pending' : null,
        'makeuperStatus': makeuperId != null ? 'pending' : null,
      };
}
