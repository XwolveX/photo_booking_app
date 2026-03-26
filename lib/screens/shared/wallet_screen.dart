// lib/screens/shared/wallet_screen.dart
// Màn hình ví / số dư cho provider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<AuthProvider>().currentUser!;
    final isPhoto = user.role.name == 'photographer';
    final roleColor = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ví của tôi',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final balance = (data?['balance'] as num?)?.toDouble() ?? 0.0;
          final totalEarnings = (data?['totalEarnings'] as num?)?.toDouble() ?? 0.0;
          final totalBookings = (data?['totalBookings'] as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [roleColor, roleColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        const Text('Số dư khả dụng',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('SMEE Pay',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        '${_fmt(balance.toInt())}đ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        _BalanceStat(
                          label: 'Tổng thu nhập',
                          value: '${_fmt(totalEarnings.toInt())}đ',
                        ),
                        const SizedBox(width: 24),
                        _BalanceStat(
                          label: 'Booking HT',
                          value: '$totalBookings',
                        ),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick actions
                Row(children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Rút tiền',
                      color: roleColor,
                      isDark: isDark,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('💳 Tính năng rút tiền sắp ra mắt!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.history_rounded,
                      label: 'Lịch sử',
                      color: Colors.blue,
                      isDark: isDark,
                      onTap: null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'Sao kê',
                      color: Colors.orange,
                      isDark: isDark,
                      onTap: null,
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Recent transactions
                Row(children: [
                  Text(
                    'Lịch sử giao dịch',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, txSnap) {
                    if (txSnap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.secondary)),
                      );
                    }

                    final docs = txSnap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.inputFill : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        child: Column(children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 40,
                              color: isDark ? Colors.white24 : Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            'Chưa có giao dịch nào',
                            style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tiền sẽ được cộng khi user xác nhận hoàn thành',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: isDark ? Colors.white24 : Colors.grey[400],
                                fontSize: 11),
                          ),
                        ]),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.inputFill : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: docs.asMap().entries.map((e) {
                          final i = e.key;
                          final doc = e.value;
                          final txData = doc.data() as Map<String, dynamic>;
                          final amount = (txData['amount'] as num?)?.toDouble() ?? 0;
                          final desc = txData['description'] as String? ?? '';
                          final type = txData['type'] as String? ?? '';
                          final createdAt = (txData['createdAt'] as Timestamp?)?.toDate();

                          final isIncome = type == 'payout';
                          final color = isIncome ? AppTheme.success : Colors.red;

                          return Column(
                            children: [
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  indent: 60,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.08),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isIncome
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.lightTextPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (createdAt != null)
                                          Text(
                                            _formatDate(createdAt),
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.grey,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isIncome ? '+' : '-'}${_fmt(amount.toInt())}đ',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ]),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _fmt(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;

  const _BalanceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.6), fontSize: 11)),
      const SizedBox(height: 3),
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
    ]);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.inputFill : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.1),
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
