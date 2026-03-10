// lib/screens/booking/booking_step1_providers.dart
// Bước 1: Chọn Photographer và/hoặc Makeuper

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'booking_step2_datetime.dart';

class BookingStep1Screen extends StatefulWidget {
  const BookingStep1Screen({super.key});

  @override
  State<BookingStep1Screen> createState() => _BookingStep1ScreenState();
}

class _BookingStep1ScreenState extends State<BookingStep1Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Selected providers
  Map<String, dynamic>? _selectedPhotographer;
  Map<String, dynamic>? _selectedMakeuper;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _selectedPhotographer != null || _selectedMakeuper != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildStepIndicator(isDark),
          _buildTabBar(isDark),
          Expanded(child: _buildProviderList(isDark)),
          _buildSelectedSummary(isDark),
          _buildNextButton(isDark),
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
      title: Text('Đặt lịch',
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17)),
      centerTitle: true,
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(4, (i) {
          final labels = ['Dịch vụ', 'Ngày giờ', 'Địa điểm', 'Xác nhận'];
          final isActive = i == 0;
          final isDone = false;
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
                        border: Border.all(
                          color: isActive
                              ? AppTheme.secondary
                              : isDone
                                  ? AppTheme.success
                                  : Colors.transparent,
                          width: 2,
                        ),
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
                                : (isDark ? Colors.white38 : Colors.grey),
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400)),
                  ],
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isDark
                          ? Colors.white12
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          indicator: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Photographer',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (_selectedPhotographer != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppTheme.success, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.brush_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Makeup',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (_selectedMakeuper != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppTheme.success, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderList(bool isDark) {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _buildRoleList('photographer', isDark),
        _buildRoleList('makeuper', isDark),
      ],
    );
  }

  Widget _buildRoleList(String role, bool isDark) {
    final isPhoto = role == 'photographer';
    final color = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    final selected =
        isPhoto ? _selectedPhotographer : _selectedMakeuper;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child:
                  CircularProgressIndicator(color: color));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isPhoto ? Icons.camera_alt_rounded : Icons.brush_rounded,
                    size: 48, color: color.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('Chưa có ${isPhoto ? 'photographer' : 'makeup artist'}',
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final uid = docs[i].id;
            final isSelected = selected?['uid'] == uid;

            return GestureDetector(
              onTap: () => setState(() {
                if (isPhoto) {
                  _selectedPhotographer =
                      isSelected ? null : {...data, 'uid': uid};
                } else {
                  _selectedMakeuper =
                      isSelected ? null : {...data, 'uid': uid};
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.1)
                      : (isDark ? AppTheme.inputFill : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : (isDark
                              ? Colors.black26
                              : Colors.grey.withOpacity(0.07)),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.withOpacity(0.4), width: 2),
                      ),
                      child: Icon(
                          isPhoto
                              ? Icons.camera_alt_rounded
                              : Icons.brush_rounded,
                          color: color,
                          size: 24),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['fullName'] ?? '',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.lightTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(data['bio'] ?? 'Chưa có mô tả',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey,
                                  fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 13),
                            const SizedBox(width: 3),
                            Text(
                                ((data['rating'] as num?)?.toDouble() ?? 0) > 0
                                    ? (data['rating'] as num)
                                        .toStringAsFixed(1)
                                    : 'Mới',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            // Giá
                            Icon(Icons.monetization_on_outlined,
                                color: color, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              data['price'] != null
                                  ? '${_formatPrice(data['price'] as num)}đ'
                                  : 'Liên hệ',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? color
                              : (isDark ? Colors.white38 : Colors.grey[300]!),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Summary bar khi đã chọn
  Widget _buildSelectedSummary(bool isDark) {
    if (!_canProceed) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.secondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildSummaryText(),
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          // Tổng giá
          if (_totalPrice > 0)
            Text(
              '${_formatPrice(_totalPrice.toInt())}đ',
              style: const TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
        ],
      ),
    );
  }

  String _buildSummaryText() {
    final parts = <String>[];
    if (_selectedPhotographer != null) {
      parts.add(_selectedPhotographer!['fullName'] ?? 'Photographer');
    }
    if (_selectedMakeuper != null) {
      parts.add(_selectedMakeuper!['fullName'] ?? 'Makeup');
    }
    return parts.join(' + ');
  }

  double get _totalPrice {
    double total = 0;
    if (_selectedPhotographer != null) {
      total += (_selectedPhotographer!['price'] as num?)?.toDouble() ?? 0;
    }
    if (_selectedMakeuper != null) {
      total += (_selectedMakeuper!['price'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Widget _buildNextButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _canProceed
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingStep2Screen(
                        selectedPhotographer: _selectedPhotographer,
                        selectedMakeuper: _selectedMakeuper,
                      ),
                    ),
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            disabledBackgroundColor:
                isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: _canProceed ? 4 : 0,
            shadowColor: AppTheme.secondary.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _canProceed ? 'Tiếp theo' : 'Chọn ít nhất 1 dịch vụ',
                style: TextStyle(
                  color: _canProceed
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.grey),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (_canProceed) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(num price) {
    final s = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
