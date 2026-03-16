// lib/screens/booking/booking_step1_providers.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'booking_step2_datetime.dart';

class BookingStep1Screen extends StatefulWidget {
  final Map<String, dynamic>? preSelectedPhotographer;
  final Map<String, dynamic>? preSelectedMakeuper;

  const BookingStep1Screen({
    super.key,
    this.preSelectedPhotographer,
    this.preSelectedMakeuper,
  });

  @override
  State<BookingStep1Screen> createState() => _BookingStep1ScreenState();
}

class _BookingStep1ScreenState extends State<BookingStep1Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  Map<String, dynamic>? _selectedPhotographer;
  Map<String, dynamic>? _selectedMakeuper;

  final _photoScrollCtrl = ScrollController();
  final _makeupScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedPhotographer = widget.preSelectedPhotographer;
    _selectedMakeuper = widget.preSelectedMakeuper;

    final initialTab = (widget.preSelectedMakeuper != null && widget.preSelectedPhotographer == null) ? 1 : 0;
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _photoScrollCtrl.dispose();
    _makeupScrollCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed => _selectedPhotographer != null || _selectedMakeuper != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: _buildAppBar(isDark),
      body: Column(children: [
        _buildStepIndicator(isDark),
        if (widget.preSelectedPhotographer != null || widget.preSelectedMakeuper != null)
          _buildPreSelectedBanner(isDark),
        _buildTabBar(isDark),
        Expanded(child: _buildProviderList(isDark)),
        _buildSelectedSummary(isDark),
        _buildNextButton(isDark),
      ]),
    );
  }

  // --- Widgets ---

  Widget _buildPreSelectedBanner(bool isDark) {
    final provider = widget.preSelectedPhotographer ?? widget.preSelectedMakeuper!;
    final serviceName = provider['serviceName'] as String? ?? '';
    final isPhoto = (provider['role'] ?? '') == 'photographer';
    final color = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.auto_awesome_rounded, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Dịch vụ "$serviceName" đã được chọn sẵn và cố định.',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Đặt lịch', style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
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
          return Expanded(
            child: Row(children: [
              Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.secondary : (isDark ? AppTheme.inputFill : Colors.grey.withValues(alpha: 0.15)),
                    shape: BoxShape.circle,
                    border: Border.all(color: isActive ? AppTheme.secondary : Colors.transparent, width: 2),
                  ),
                  child: Center(
                    child: Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.grey), fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i], style: TextStyle(color: isActive ? AppTheme.secondary : (isDark ? Colors.white38 : Colors.grey), fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
              ]),
              if (i < 3) Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18), color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2))),
            ]),
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
          color: isDark ? AppTheme.inputFill : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          indicator: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.camera_alt_rounded, size: 16),
              const SizedBox(width: 6),
              const Text('Photographer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              if (_selectedPhotographer != null) ...[const SizedBox(width: 4), const Icon(Icons.check_circle, size: 12, color: AppTheme.success)],
            ])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.brush_rounded, size: 16),
              const SizedBox(width: 6),
              const Text('Makeup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              if (_selectedMakeuper != null) ...[const SizedBox(width: 4), const Icon(Icons.check_circle, size: 12, color: AppTheme.success)],
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderList(bool isDark) {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _buildRoleList('photographer', isDark, _photoScrollCtrl, _selectedPhotographer),
        _buildRoleList('makeuper', isDark, _makeupScrollCtrl, _selectedMakeuper),
      ],
    );
  }

  Widget _buildRoleList(String role, bool isDark, ScrollController scrollCtrl, Map<String, dynamic>? selected) {
    final isPhoto = role == 'photographer';
    final color = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    final preSelectedForThisRole = isPhoto ? widget.preSelectedPhotographer : widget.preSelectedMakeuper;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: role).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: color));
        final docs = snap.data?.docs ?? [];

        final sortedDocs = [...docs];
        if (preSelectedForThisRole != null) {
          sortedDocs.sort((a, b) => a.id == preSelectedForThisRole['uid'] ? -1 : (b.id == preSelectedForThisRole['uid'] ? 1 : 0));
        }

        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: sortedDocs.length,
          itemBuilder: (context, i) {
            final data = sortedDocs[i].data() as Map<String, dynamic>;
            final uid = sortedDocs[i].id;
            final isThisPreSelected = preSelectedForThisRole != null && preSelectedForThisRole['uid'] == uid;

            // SỬA LỖI CÚ PHÁP: Tách logic check ID dịch vụ ra biến riêng
            String? currentSId;
            if (selected != null && selected['uid'] == uid) {
              currentSId = selected['serviceId'] as String?;
            }

            return _ProviderWithServicesCard(
              data: data,
              uid: uid,
              isSelected: selected != null && selected['uid'] == uid,
              selectedServiceId: currentSId,
              isPreSelected: isThisPreSelected,
              isLocked: preSelectedForThisRole != null && !isThisPreSelected,
              color: color,
              isDark: isDark,
              isPhoto: isPhoto,
              preSelectedServiceName: isThisPreSelected ? preSelectedForThisRole['serviceName'] : null,
              onSelect: (price, name, sId, isDeselect) {
                if (preSelectedForThisRole != null) return;
                setState(() {
                  if (isPhoto) {
                    _selectedPhotographer = isDeselect ? null : {
                      ...data, 'uid': uid, 'price': price, 'serviceName': name, 'serviceId': sId
                    };
                  } else {
                    _selectedMakeuper = isDeselect ? null : {
                      ...data, 'uid': uid, 'price': price, 'serviceName': name, 'serviceId': sId
                    };
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  // --- Footer Summary & Buttons ---

  Widget _buildSelectedSummary(bool isDark) {
    if (!_canProceed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_buildSummaryText(), style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        if (_totalPrice > 0) Text('${_formatPrice(_totalPrice.toInt())}đ', style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 14)),
      ]),
    );
  }

  String _buildSummaryText() {
    final parts = <String>[];
    if (_selectedPhotographer != null) parts.add(_selectedPhotographer!['fullName'] ?? 'Photographer');
    if (_selectedMakeuper != null) parts.add(_selectedMakeuper!['fullName'] ?? 'Makeup');
    return parts.join(' + ');
  }

  double get _totalPrice {
    double total = 0;
    if (_selectedPhotographer != null) total += (_selectedPhotographer!['price'] as num?)?.toDouble() ?? 0;
    if (_selectedMakeuper != null) total += (_selectedMakeuper!['price'] as num?)?.toDouble() ?? 0;
    return total;
  }

  Widget _buildNextButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: _canProceed ? () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => BookingStep2Screen(selectedPhotographer: _selectedPhotographer, selectedMakeuper: _selectedMakeuper),
          )) : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_canProceed ? 'Tiếp theo' : 'Chọn ít nhất 1 dịch vụ', style: TextStyle(color: _canProceed ? Colors.white : (isDark ? Colors.white38 : Colors.grey), fontWeight: FontWeight.w700, fontSize: 15)),
            if (_canProceed) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)],
          ]),
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

// --- Provider Card Component ---

class _ProviderWithServicesCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String uid;
  final bool isSelected;
  final String? selectedServiceId;
  final bool isPreSelected;
  final bool isLocked;
  final Color color;
  final bool isDark;
  final bool isPhoto;
  final String? preSelectedServiceName;
  final void Function(double? price, String? name, String? sId, bool isDeselect) onSelect;

  const _ProviderWithServicesCard({
    required this.data,
    required this.uid,
    required this.isSelected,
    this.selectedServiceId,
    required this.isPreSelected,
    required this.isLocked,
    required this.color,
    required this.isDark,
    required this.isPhoto,
    required this.onSelect,
    this.preSelectedServiceName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCardActive = isSelected || isPreSelected;

    return IgnorePointer(
      ignoring: isLocked,
      child: Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCardActive ? color.withValues(alpha: 0.05) : (isDark ? AppTheme.inputFill : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isCardActive ? color : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2)), width: isCardActive ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(),
            const Divider(height: 1),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').where('providerId', isEqualTo: uid).snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: docs.map((doc) {
                      final s = doc.data() as Map<String, dynamic>;
                      final sName = s['name'] as String? ?? '';
                      final sPrice = (s['price'] as num?)?.toDouble() ?? 0;
                      final sId = doc.id;

                      final bool isThisServiceSelected = (isPreSelected && sName == preSelectedServiceName) || (selectedServiceId == sId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: (isPreSelected && sName == preSelectedServiceName) ? null : () {
                            onSelect(sPrice, sName, sId, (selectedServiceId == sId));
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isThisServiceSelected ? color.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50]),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isThisServiceSelected ? color : Colors.transparent),
                            ),
                            child: Row(children: [
                              Icon(isThisServiceSelected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: isThisServiceSelected ? color : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(child: Text(sName, style: TextStyle(fontSize: 13, fontWeight: isThisServiceSelected ? FontWeight.bold : FontWeight.w500, color: isThisServiceSelected ? color : (isDark ? Colors.white : AppTheme.lightTextPrimary)))),
                              Text('${sPrice.toInt()}đ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isThisServiceSelected ? color : Colors.grey)),
                            ]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(isPhoto ? Icons.camera_alt : Icons.brush, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['fullName'] ?? '', style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontWeight: FontWeight.bold)),
          Text(data['bio'] ?? 'Chưa có mô tả', maxLines: 1, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        if (isPreSelected) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: const Text('ĐÃ CHỌN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}