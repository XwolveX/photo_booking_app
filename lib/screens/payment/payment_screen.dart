// lib/screens/payment/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String? photographerName;
  final String? makeuperName;
  final String bookingDate;
  final String timeSlot;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    this.photographerName,
    this.makeuperName,
    required this.bookingDate,
    required this.timeSlot,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  int _selectedMethod = 0;
  bool _isProcessing = false;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  final _methods = [
    {'icon': Icons.account_balance_wallet_rounded, 'name': 'Ví SMEE', 'detail': 'Số dư: 2.500.000đ', 'color': const Color(0xFFE94560)},
    {'icon': Icons.credit_card_rounded, 'name': 'Thẻ ATM / Visa', 'detail': '•••• •••• •••• 4829', 'color': const Color(0xFF4FC3F7)},
    {'icon': Icons.qr_code_rounded, 'name': 'QR Pay', 'detail': 'Momo, ZaloPay, VNPay', 'color': const Color(0xFF4CAF50)},
    {'icon': Icons.account_balance_rounded, 'name': 'Chuyển khoản', 'detail': 'Ngân hàng nội địa', 'color': const Color(0xFFFF9800)},
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    // Simulate processing
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          bookingId: widget.bookingId,
          amount: widget.amount,
          photographerName: widget.photographerName,
          makeuperName: widget.makeuperName,
          bookingDate: widget.bookingDate,
          timeSlot: widget.timeSlot,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        elevation: 0,
        leading: _isProcessing
            ? const SizedBox.shrink()
            : IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thanh toán',
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: _isProcessing ? _buildProcessing(isDark) : _buildContent(isDark),
    );
  }

  Widget _buildProcessing(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (_, __) => Opacity(
              opacity: _shimmerAnim.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.secondary.withOpacity(0.3),
                      AppTheme.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Đang xử lý thanh toán...',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng không tắt ứng dụng',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 32),
          // Animated dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (_, __) {
                  final delay = i * 0.2;
                  final value = ((_shimmerCtrl.value - delay).clamp(0.0, 1.0));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.secondary.withOpacity(0.3 + value * 0.7),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount card
                _buildAmountCard(isDark),
                const SizedBox(height: 20),

                // Booking summary
                _buildBookingSummary(isDark),
                const SizedBox(height: 20),

                // Payment methods
                Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_methods.length, (i) => _buildMethodTile(i, isDark)),

                const SizedBox(height: 16),
                // Security note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.security_rounded, color: AppTheme.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thanh toán được bảo mật bởi SMEE Pay. Tiền sẽ được giữ trung gian cho đến khi booking hoàn thành.',
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
        ),

        // Pay button
        _buildPayButton(isDark),
      ],
    );
  }

  Widget _buildAmountCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondary, AppTheme.secondary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lock_rounded, color: Colors.white70, size: 14),
            SizedBox(width: 5),
            Text('Tổng thanh toán',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(
            '${_formatPrice(widget.amount.toInt())}đ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tiền sẽ được giữ trung gian cho đến khi hoàn thành',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết booking',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.photographerName != null)
            _summaryRow(isDark, Icons.camera_alt_rounded, AppTheme.rolePhotographer,
                'Photographer', widget.photographerName!),
          if (widget.photographerName != null && widget.makeuperName != null)
            const SizedBox(height: 8),
          if (widget.makeuperName != null)
            _summaryRow(isDark, Icons.brush_rounded, AppTheme.roleMakeuper,
                'Makeup Artist', widget.makeuperName!),
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today_rounded, color: AppTheme.secondary, size: 14),
            const SizedBox(width: 8),
            Text('${widget.bookingDate}  •  ${widget.timeSlot}',
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  Widget _summaryRow(bool isDark, IconData icon, Color color, String role, String name) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name,
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        Text(role, style: TextStyle(color: color, fontSize: 10)),
      ]),
    ]);
  }

  Widget _buildMethodTile(int index, bool isDark) {
    final method = _methods[index];
    final isSelected = _selectedMethod == index;
    final color = method['color'] as Color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMethod = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : (isDark ? AppTheme.inputFill : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.15)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(method['icon'] as IconData, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(method['name'] as String,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(method['detail'] as String,
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontSize: 12)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : (isDark ? Colors.white24 : Colors.grey.withOpacity(0.4)),
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _buildPayButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 6,
            shadowColor: AppTheme.secondary.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Thanh toán  ${_formatPrice(widget.amount.toInt())}đ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
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