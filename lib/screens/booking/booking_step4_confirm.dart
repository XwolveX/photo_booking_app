// lib/screens/booking/booking_step4_confirm.dart
// Bước 4: Xác nhận booking và lưu Firestore

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class BookingStep4Screen extends StatefulWidget {
  final Map<String, dynamic>? selectedPhotographer;
  final Map<String, dynamic>? selectedMakeuper;
  final DateTime bookingDate;
  final String timeSlot;
  final String address;
  final double latitude;
  final double longitude;
  final String? note;

  const BookingStep4Screen({
    super.key,
    this.selectedPhotographer,
    this.selectedMakeuper,
    required this.bookingDate,
    required this.timeSlot,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.note,
  });

  @override
  State<BookingStep4Screen> createState() => _BookingStep4ScreenState();
}

class _BookingStep4ScreenState extends State<BookingStep4Screen> {
  bool _isLoading = false;

  double get _totalPrice {
    double total = 0;
    if (widget.selectedPhotographer != null) {
      total +=
          (widget.selectedPhotographer!['price'] as num?)?.toDouble() ?? 0;
    }
    if (widget.selectedMakeuper != null) {
      total += (widget.selectedMakeuper!['price'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().currentUser!;

    try {
      final bookingData = {
        'userId': user.uid,
        'userName': user.fullName,
        // Photographer
        'photographerId': widget.selectedPhotographer?['uid'],
        'photographerName': widget.selectedPhotographer?['fullName'],
        'photographerPrice':
            (widget.selectedPhotographer?['price'] as num?)?.toDouble(),
        'photographerStatus':
            widget.selectedPhotographer != null ? 'pending' : null,
        // Makeuper
        'makeuperId': widget.selectedMakeuper?['uid'],
        'makeuperName': widget.selectedMakeuper?['fullName'],
        'makeuperPrice':
            (widget.selectedMakeuper?['price'] as num?)?.toDouble(),
        'makeuperStatus':
            widget.selectedMakeuper != null ? 'pending' : null,
        // Thời gian & địa điểm
        'bookingDate': widget.bookingDate,
        'timeSlot': widget.timeSlot,
        'address': widget.address,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'note': widget.note,
        // Trạng thái tổng
        'status': 'pending',
        'createdAt': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Đặt lịch thành công!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Yêu cầu của bạn đã được gửi.\nVui lòng chờ xác nhận từ ${_providerNames}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Pop về HomeScreen (pop tất cả màn hình booking)
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Về trang chủ',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _providerNames {
    final parts = <String>[];
    if (widget.selectedPhotographer != null) {
      parts.add(widget.selectedPhotographer!['fullName'] ?? 'Photographer');
    }
    if (widget.selectedMakeuper != null) {
      parts.add(widget.selectedMakeuper!['fullName'] ?? 'Makeup Artist');
    }
    return parts.join(' và ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildStepIndicator(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryCard(isDark),
                  const SizedBox(height: 16),
                  _buildInfoNote(isDark),
                ],
              ),
            ),
          ),
          _buildConfirmButton(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Xác nhận booking',
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17)),
      centerTitle: true,
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final labels = ['Dịch vụ', 'Ngày giờ', 'Địa điểm', 'Xác nhận'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i == 3;
          final isDone = i < 3;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.secondary
                            : isDone
                                ? AppTheme.success
                                : (isDark
                                    ? AppTheme.inputFill
                                    : Colors.grey.withOpacity(0.15)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white38
                                            : Colors.grey),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i],
                        style: TextStyle(
                            color: isActive
                                ? AppTheme.secondary
                                : isDone
                                    ? AppTheme.success
                                    : (isDark ? Colors.white38 : Colors.grey),
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400)),
                  ],
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isDone
                          ? AppTheme.success.withOpacity(0.5)
                          : (isDark
                              ? Colors.white12
                              : Colors.grey.withOpacity(0.2)),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiết booking',
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 16),

          // Photographer
          if (widget.selectedPhotographer != null)
            _buildProviderRow(
              isDark,
              icon: Icons.camera_alt_rounded,
              color: AppTheme.rolePhotographer,
              name: widget.selectedPhotographer!['fullName'] ?? '',
              label: 'Photographer',
              price: (widget.selectedPhotographer!['price'] as num?)?.toDouble(),
            ),

          // Makeuper
          if (widget.selectedMakeuper != null) ...[
            if (widget.selectedPhotographer != null) const SizedBox(height: 10),
            _buildProviderRow(
              isDark,
              icon: Icons.brush_rounded,
              color: AppTheme.roleMakeuper,
              name: widget.selectedMakeuper!['fullName'] ?? '',
              label: 'Makeup Artist',
              price: (widget.selectedMakeuper!['price'] as num?)?.toDouble(),
            ),
          ],

          _buildDivider(isDark),

          // Ngày giờ
          _buildInfoRow(isDark,
              icon: Icons.calendar_today_rounded,
              color: AppTheme.secondary,
              label: 'Ngày',
              value:
                  '${widget.bookingDate.day}/${widget.bookingDate.month}/${widget.bookingDate.year}'),
          const SizedBox(height: 10),
          _buildInfoRow(isDark,
              icon: Icons.access_time_rounded,
              color: AppTheme.secondary,
              label: 'Giờ',
              value: widget.timeSlot),

          _buildDivider(isDark),

          // Địa điểm
          _buildInfoRow(isDark,
              icon: Icons.location_on_rounded,
              color: Colors.orange,
              label: 'Địa điểm',
              value: widget.address),

          // Ghi chú
          if (widget.note != null && widget.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(isDark,
                icon: Icons.edit_note_rounded,
                color: Colors.blue,
                label: 'Ghi chú',
                value: widget.note!),
          ],

          _buildDivider(isDark),

          // Tổng tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng thanh toán',
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text(
                _totalPrice > 0
                    ? '${_formatPrice(_totalPrice.toInt())}đ'
                    : 'Thương lượng',
                style: TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRow(bool isDark,
      {required IconData icon,
      required Color color,
      required String name,
      required String label,
      double? price}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3))),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Text(
          price != null && price > 0
              ? '${_formatPrice(price.toInt())}đ'
              : 'Liên hệ',
          style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInfoRow(bool isDark,
      {required IconData icon,
      required Color color,
      required String label,
      required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text('$label:  ',
            style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
          color: isDark ? Colors.white.withOpacity(0.07) : Colors.grey.withOpacity(0.12)),
    );
  }

  Widget _buildInfoNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sau khi bạn xác nhận, $_providerNames sẽ nhận được thông báo và cần chấp nhận booking trong vòng 24 giờ.',
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[700],
                  fontSize: 12,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _confirmBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 6,
            shadowColor: AppTheme.secondary.withOpacity(0.4),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text('Xác nhận đặt lịch',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
