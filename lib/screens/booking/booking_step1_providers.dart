// lib/screens/booking/booking_step1_providers.dart
// Bước 1: Chọn Photographer và/hoặc Makeuper
// Hỗ trợ preSelected từ màn hình Khám phá dịch vụ

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'booking_step2_datetime.dart';

class BookingStep1Screen extends StatefulWidget {
  // Provider được chọn sẵn từ màn hình trước (nếu có)
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

  // ScrollController để auto-scroll đến item được chọn sẵn
  final _photoScrollCtrl = ScrollController();
  final _makeupScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo với provider được chọn sẵn
    _selectedPhotographer = widget.preSelectedPhotographer;
    _selectedMakeuper = widget.preSelectedMakeuper;

    // Mở tab đúng theo provider được chọn sẵn
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
        // Hiện banner "đã chọn sẵn" nếu có preSelected
        if (widget.preSelectedPhotographer != null || widget.preSelectedMakeuper != null)
          _buildPreSelectedBanner(isDark),
        _buildTabBar(isDark),
        Expanded(child: _buildProviderList(isDark)),
        _buildSelectedSummary(isDark),
        _buildNextButton(isDark),
      ]),
    );
  }

  // Banner thông báo đã chọn sẵn từ dịch vụ
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
            serviceName.isNotEmpty
                ? 'Đã chọn dịch vụ "$serviceName" — bạn có thể thêm dịch vụ khác bên dưới'
                : 'Đã chọn sẵn ${provider['fullName']} — bạn có thể thêm dịch vụ khác',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
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
        icon: Icon(Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Đặt lịch', style: TextStyle(
          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          fontWeight: FontWeight.w700, fontSize: 17)),
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
                    child: Text('${i + 1}', style: TextStyle(
                        color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.grey),
                        fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i], style: TextStyle(
                    color: isActive ? AppTheme.secondary : (isDark ? Colors.white38 : Colors.grey),
                    fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
              ]),
              if (i < 3) Expanded(child: Container(
                height: 2, margin: const EdgeInsets.only(bottom: 18),
                color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
              )),
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
              const SizedBox(width: 4),
              Container(
                width: _selectedPhotographer != null ? 8 : 0,
                height: _selectedPhotographer != null ? 8 : 0,
                decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
              ),
            ])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.brush_rounded, size: 16),
              const SizedBox(width: 6),
              const Text('Makeup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Container(
                width: _selectedMakeuper != null ? 8 : 0,
                height: _selectedMakeuper != null ? 8 : 0,
                decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
              ),
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
    final preSelectedUid = isPhoto
        ? (widget.preSelectedPhotographer != null ? widget.preSelectedPhotographer!['uid'] as String? : null)
        : (widget.preSelectedMakeuper != null ? widget.preSelectedMakeuper!['uid'] as String? : null);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: role).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: color));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(isPhoto ? Icons.camera_alt_rounded : Icons.brush_rounded,
                size: 48, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Chưa có ${isPhoto ? 'photographer' : 'makeup artist'}',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
          ]));
        }

        // Sắp xếp: provider được preSelect lên đầu
        final sortedDocs = [...docs];
        if (preSelectedUid != null) {
          sortedDocs.sort((a, b) {
            if (a.id == preSelectedUid) return -1;
            if (b.id == preSelectedUid) return 1;
            return 0;
          });
        }

        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: sortedDocs.length,
          itemBuilder: (context, i) {
            final data = sortedDocs[i].data() as Map<String, dynamic>;
            final uid = sortedDocs[i].id;
            final isSelected = selected?['uid'] == uid;
            final isPreSelected = uid == preSelectedUid;

            return _ProviderWithServicesCard(
              data: data,
              uid: uid,
              isSelected: isSelected,
              isPreSelected: isPreSelected,
              color: color,
              isDark: isDark,
              isPhoto: isPhoto,
              preSelectedServiceName: isPreSelected
                  ? (isPhoto
                  ? (widget.preSelectedPhotographer != null ? widget.preSelectedPhotographer!['serviceName'] as String? : null)
                  : (widget.preSelectedMakeuper != null ? widget.preSelectedMakeuper!['serviceName'] as String? : null))
                  : null,
              onSelect: (double? servicePrice, String? serviceName, bool isDeselect) {
                setState(() {
                  if (isPhoto) {
                    if (isDeselect) {
                      _selectedPhotographer = null;
                    } else {
                      _selectedPhotographer = {...data, 'uid': uid, if (servicePrice != null) 'price': servicePrice};
                    }
                  } else {
                    if (isDeselect) {
                      _selectedMakeuper = null;
                    } else {
                      _selectedMakeuper = {...data, 'uid': uid, if (servicePrice != null) 'price': servicePrice};
                    }
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedSummary(bool isDark) {
    if (!_canProceed) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
        Expanded(child: Text(_buildSummaryText(),
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 13, fontWeight: FontWeight.w600))),
        if (_totalPrice > 0)
          Text('${_formatPrice(_totalPrice.toInt())}đ',
              style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 14)),
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
            builder: (_) => BookingStep2Screen(
              selectedPhotographer: _selectedPhotographer,
              selectedMakeuper: _selectedMakeuper,
            ),
          )) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            disabledBackgroundColor: isDark ? AppTheme.inputFill : Colors.grey.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: _canProceed ? 4 : 0,
            shadowColor: AppTheme.secondary.withValues(alpha: 0.4),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_canProceed ? 'Tiếp theo' : 'Chọn ít nhất 1 dịch vụ',
                style: TextStyle(
                    color: _canProceed ? Colors.white : (isDark ? Colors.white38 : Colors.grey),
                    fontWeight: FontWeight.w700, fontSize: 15)),
            if (_canProceed) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
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

// ── Provider Card với danh sách services ─────────────────────
class _ProviderWithServicesCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String uid;
  final bool isSelected;
  final bool isPreSelected;
  final Color color;
  final bool isDark;
  final bool isPhoto;
  final String? preSelectedServiceName;
  final void Function(double? servicePrice, String? serviceName, bool isDeselect) onSelect;

  const _ProviderWithServicesCard({
    required this.data,
    required this.uid,
    required this.isSelected,
    required this.isPreSelected,
    required this.color,
    required this.isDark,
    required this.isPhoto,
    required this.onSelect,
    this.preSelectedServiceName,
  });

  @override
  State<_ProviderWithServicesCard> createState() => _ProviderWithServicesCardState();
}

class _ProviderWithServicesCardState extends State<_ProviderWithServicesCard> {
  // Dịch vụ đang được chọn trong card này (null = chọn provider không chọn service cụ thể)
  String? _selectedServiceId;
  double? _selectedServicePrice;
  String? _selectedServiceName;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedServiceName != null && widget.isPreSelected) {
      _selectedServiceName = widget.preSelectedServiceName;
    }
  }

  @override
  void didUpdateWidget(_ProviderWithServicesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi provider này bị deselect từ bên ngoài (user chọn provider khác)
    // → reset service selection trong card này
    if (oldWidget.isSelected && !widget.isSelected) {
      _selectedServiceId = null;
      _selectedServicePrice = null;
      _selectedServiceName = null;
    }
  }

  String _fmt(num price) {
    final s = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final isDark = widget.isDark;
    final data = widget.data;
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isSelected ? color.withValues(alpha: 0.08) : (isDark ? AppTheme.inputFill : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? color
              : (widget.isPreSelected
              ? color.withValues(alpha: 0.4)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.12))),
          width: widget.isSelected ? 2 : (widget.isPreSelected ? 1.5 : 1),
        ),
        boxShadow: [BoxShadow(
          color: widget.isSelected ? color.withValues(alpha: 0.12) : (isDark ? Colors.black26 : Colors.grey.withValues(alpha: 0.06)),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Provider header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(widget.isPhoto ? Icons.camera_alt_rounded : Icons.brush_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(data['fullName'] ?? '',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w700, fontSize: 15))),
                if (widget.isPreSelected && !widget.isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('Gợi ý', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(data['bio'] ?? 'Chưa có mô tả', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                const SizedBox(width: 3),
                Text(rating > 0 ? rating.toStringAsFixed(1) : 'Mới',
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ])),
          ]),
        ),

        // ── Danh sách services ──
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('services')
              .where('providerId', isEqualTo: widget.uid)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color))),
              );
            }
            if (docs.isEmpty) return const SizedBox.shrink();

            return Column(children: [
              Divider(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1), height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dịch vụ',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ...docs.map((doc) {
                      final s = doc.data() as Map<String, dynamic>;
                      final sId = doc.id;
                      final sName = s['name'] as String? ?? '';
                      final sPrice = (s['price'] as num?)?.toDouble() ?? 0;
                      final sDesc = s['description'] as String? ?? '';
                      final isServiceSelected = _selectedServiceId == sId ||
                          (widget.preSelectedServiceName == sName && _selectedServiceId == null);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              final alreadySelected = _selectedServiceId == sId ||
                                  (widget.preSelectedServiceName == sName && _selectedServiceId == null);
                              setState(() {
                                if (alreadySelected) {
                                  // Untick → bỏ chọn service và provider
                                  _selectedServiceId = null;
                                  _selectedServicePrice = null;
                                  _selectedServiceName = null;
                                } else {
                                  // Chọn service mới
                                  _selectedServiceId = sId;
                                  _selectedServicePrice = sPrice;
                                  _selectedServiceName = sName;
                                }
                              });
                              widget.onSelect(
                                alreadySelected ? null : sPrice,
                                alreadySelected ? null : sName,
                                alreadySelected, // isDeselect
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isServiceSelected
                                    ? color.withValues(alpha: 0.12)
                                    : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isServiceSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
                                ),
                              ),
                              child: Row(children: [
                                Icon(Icons.design_services_rounded,
                                    color: isServiceSelected ? color : (isDark ? Colors.white38 : Colors.grey),
                                    size: 16),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(sName,
                                      style: TextStyle(
                                          color: isServiceSelected ? color : (isDark ? Colors.white : AppTheme.lightTextPrimary),
                                          fontWeight: isServiceSelected ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 13)),
                                  if (sDesc.isNotEmpty)
                                    Text(sDesc, maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: isDark ? Colors.white30 : Colors.grey, fontSize: 11)),
                                ])),
                                const SizedBox(width: 8),
                                Text(
                                  sPrice > 0 ? '${_fmt(sPrice)}đ' : 'Liên hệ',
                                  style: TextStyle(
                                      color: isServiceSelected ? color : (isDark ? Colors.white54 : Colors.grey[600]),
                                      fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    color: isServiceSelected ? color : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isServiceSelected ? color : (isDark ? Colors.white30 : Colors.grey[300]!),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isServiceSelected
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 10)
                                      : null,
                                ),
                              ]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ]);
          },
        ),
      ]),
    );
  }
}