// lib/screens/payment/payment_success_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String? photographerName;
  final String? makeuperName;
  final String bookingDate;
  final String timeSlot;

  const PaymentSuccessScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    this.photographerName,
    this.makeuperName,
    required this.bookingDate,
    required this.timeSlot,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );

    _playAnimation();
  }

  void _playAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeCtrl.forward();
    // Update Firestore
    _updatePaymentStatus();
  }

  Future<void> _updatePaymentStatus() async {
    if (_saved) return;
    _saved = true;
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'paymentStatus': 'paid',
        'paymentAmount': widget.amount,
        'paidAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Success icon
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.success,
                          AppTheme.success.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        'Thanh toán thành công! 🎉',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tiền đang được giữ trung gian bởi SMEE Pay\nvà sẽ được chuyển cho provider khi hoàn thành',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontSize: 13,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // Amount + Transaction ID
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.inputFill : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.success.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(children: [
                          Text(
                            '${_formatPrice(widget.amount.toInt())}đ',
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đã thanh toán',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.12)),
                          const SizedBox(height: 12),

                          // Transaction details
                          _infoRow(isDark, 'Mã giao dịch',
                              'SMEE${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                          const SizedBox(height: 8),
                          _infoRow(isDark, 'Trạng thái', 'Đang giữ trung gian',
                              valueColor: Colors.orange),
                          const SizedBox(height: 8),
                          if (widget.photographerName != null)
                            _infoRow(isDark, 'Photographer', widget.photographerName!),
                          if (widget.makeuperName != null) ...[
                            const SizedBox(height: 8),
                            _infoRow(isDark, 'Makeup Artist', widget.makeuperName!),
                          ],
                          const SizedBox(height: 8),
                          _infoRow(isDark, 'Thời gian',
                              '${widget.bookingDate}  •  ${widget.timeSlot}'),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // Escrow info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Booking đã có hiệu lực. Sau khi cả hai bên xác nhận hoàn thành, tiền sẽ được chuyển đến provider.',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey[700],
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: AppTheme.secondary.withOpacity(0.4),
                      ),
                      child: const Text(
                        'Về trang chủ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(bool isDark, String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? (isDark ? Colors.white70 : AppTheme.lightTextPrimary),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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