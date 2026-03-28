// lib/screens/user/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../shared/public_profile_screen.dart';
import '../booking/booking_step1_providers.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  int _tabIndex = 0; // 0=all, 1=photographer, 2=makeuper, 3=service
  bool _isLoading = false;

  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _serviceResults = [];

  // District detection from query
  String? _detectedDistrict;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Bản đồ alias → tên chuẩn trong Firestore
  static const Map<String, String> _districtAliases = {
    'q1': 'Quận 1', 'quan 1': 'Quận 1', 'quận 1': 'Quận 1',
    'q3': 'Quận 3', 'quan 3': 'Quận 3', 'quận 3': 'Quận 3',
    'q4': 'Quận 4', 'quan 4': 'Quận 4', 'quận 4': 'Quận 4',
    'q5': 'Quận 5', 'quan 5': 'Quận 5', 'quận 5': 'Quận 5',
    'q6': 'Quận 6', 'quan 6': 'Quận 6', 'quận 6': 'Quận 6',
    'q7': 'Quận 7', 'quan 7': 'Quận 7', 'quận 7': 'Quận 7',
    'q8': 'Quận 8', 'quan 8': 'Quận 8', 'quận 8': 'Quận 8',
    'q10': 'Quận 10', 'quan 10': 'Quận 10', 'quận 10': 'Quận 10',
    'q11': 'Quận 11', 'quan 11': 'Quận 11', 'quận 11': 'Quận 11',
    'q12': 'Quận 12', 'quan 12': 'Quận 12', 'quận 12': 'Quận 12',
    'thu duc': 'TP. Thủ Đức', 'thủ đức': 'TP. Thủ Đức', 'tp thu duc': 'TP. Thủ Đức',
    'binh thanh': 'Bình Thạnh', 'bình thạnh': 'Bình Thạnh',
    'go vap': 'Gò Vấp', 'gò vấp': 'Gò Vấp',
    'phu nhuan': 'Phú Nhuận', 'phú nhuận': 'Phú Nhuận',
    'tan binh': 'Tân Bình', 'tân bình': 'Tân Bình',
    'tan phu': 'Tân Phú', 'tân phú': 'Tân Phú',
    'binh chanh': 'Bình Chánh', 'bình chánh': 'Bình Chánh',
    'can gio': 'Cần Giờ', 'cần giờ': 'Cần Giờ',
    'cu chi': 'Củ Chi', 'củ chi': 'Củ Chi',
    'hoc mon': 'Hóc Môn', 'hóc môn': 'Hóc Môn',
    'nha be': 'Nhà Bè', 'nhà bè': 'Nhà Bè',
  };

  /// Trích xuất tên quận từ chuỗi query người dùng nhập.
  /// Trả về tên chuẩn (như trong Firestore) hoặc null nếu không tìm thấy.
  String? _extractDistrict(String query) {
    final q = query.toLowerCase().trim();
    // Ưu tiên tìm tên dài nhất khớp trước
    String? found;
    int foundLen = 0;
    for (final alias in _districtAliases.keys) {
      if (q.contains(alias) && alias.length > foundLen) {
        found = _districtAliases[alias];
        foundLen = alias.length;
      }
    }
    return found;
  }

  /// Loại bỏ tên quận khỏi query để tìm keyword dịch vụ thuần túy
  String _stripDistrict(String query, String district) {
    // Tìm alias khớp và xóa khỏi query
    final q = query.toLowerCase().trim();
    for (final entry in _districtAliases.entries) {
      if (entry.value == district && q.contains(entry.key)) {
        return query
            .toLowerCase()
            .replaceFirst(entry.key, '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
    }
    return query;
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _userResults = [];
        _serviceResults = [];
        _query = '';
        _detectedDistrict = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _query = query.trim();
    });

    try {
      final district = _extractDistrict(query);
      final serviceKeyword =
      district != null ? _stripDistrict(query, district) : query.trim().toLowerCase();
      final q = serviceKeyword.toLowerCase();

      setState(() => _detectedDistrict = district);

      // ── Search users (photographer + makeuper) ──────────────
      Query usersQuery = FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['photographer', 'makeuper']);

      final usersSnap = await usersQuery.get();

      final users = usersSnap.docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final name = (data['fullName'] ?? '').toLowerCase();
        final bio = (data['bio'] ?? '').toLowerCase();

        // Kiểm tra keyword dịch vụ (nếu còn sau khi strip district)
        final matchesKeyword = q.isEmpty ||
            name.contains(q) ||
            bio.contains(q);

        // Kiểm tra quận nếu có detect được
        bool matchesDistrict = true;
        if (district != null) {
          final userDistricts = data['districts'];
          if (userDistricts == null || (userDistricts as List).isEmpty) {
            matchesDistrict = false;
          } else {
            matchesDistrict = (userDistricts as List)
                .any((d) => d.toString() == district);
          }
        }

        return matchesKeyword && matchesDistrict;
      }).map((d) => {'uid': d.id, ...(d.data() as Map<String, dynamic>)}).toList();

      // ── Search services ─────────────────────────────────────
      final servicesSnap =
      await FirebaseFirestore.instance.collection('services').get();

      final services = servicesSnap.docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toLowerCase();
        final desc = (data['description'] ?? '').toLowerCase();
        final providerName = (data['providerName'] ?? '').toLowerCase();

        final matchesKeyword = q.isEmpty ||
            name.contains(q) ||
            desc.contains(q) ||
            providerName.contains(q);

        // Lọc service theo quận của provider
        bool matchesDistrict = true;
        if (district != null) {
          final providerDistricts = data['providerDistricts'];
          if (providerDistricts == null ||
              (providerDistricts as List).isEmpty) {
            matchesDistrict = false;
          } else {
            matchesDistrict = (providerDistricts as List)
                .any((d) => d.toString() == district);
          }
        }

        return matchesKeyword && matchesDistrict;
      }).map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();

      if (mounted) {
        setState(() {
          _userResults = users.cast<Map<String, dynamic>>();
          _serviceResults = services.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_tabIndex == 1)
      return _userResults.where((u) => u['role'] == 'photographer').toList();
    if (_tabIndex == 2)
      return _userResults.where((u) => u['role'] == 'makeuper').toList();
    return _userResults;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildSearchBar(isDark),
              if (_query.isNotEmpty) _buildFilterTabs(isDark),
              // District detection chip
              if (_detectedDistrict != null) _buildDistrictChip(isDark),
              Expanded(child: _buildResults(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictChip(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on_rounded,
                  color: AppTheme.secondary, size: 13),
              const SizedBox(width: 4),
              Text(
                'Khu vực: $_detectedDistrict',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setState(() => _detectedDistrict = null);
                  // Re-search without district filter
                  _search(_query);
                },
                child: Icon(Icons.close_rounded,
                    color: AppTheme.secondary, size: 13),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      color: isDark ? AppTheme.surface : Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.inputFill
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm... (vd: chụp ảnh gò vấp)',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: isDark ? Colors.white38 : Colors.grey, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? Colors.white38 : Colors.grey,
                        size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _search('');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                ),
                onChanged: (v) {
                  if (v.trim().length >= 2 || v.trim().isEmpty) _search(v);
                },
                onSubmitted: _search,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _tabs = [
    (Icons.apps_rounded, 'Tất cả'),
    (Icons.camera_alt_rounded, 'Photographer'),
    (Icons.brush_rounded, 'Makeup'),
    (Icons.design_services_rounded, 'Dịch vụ'),
  ];

  Widget _buildFilterTabs(bool isDark) {
    return Container(
      color: isDark ? AppTheme.surface : Colors.white,
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final sel = _tabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: sel
                    ? AppTheme.secondary
                    : (isDark
                    ? AppTheme.inputFill
                    : Colors.grey.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel
                        ? AppTheme.secondary
                        : Colors.transparent,
                    width: 1.5),
              ),
              child: Row(children: [
                Icon(_tabs[i].$1,
                    size: 14,
                    color: sel
                        ? Colors.white
                        : (isDark ? Colors.white54 : Colors.grey)),
                const SizedBox(width: 5),
                Text(_tabs[i].$2,
                    style: TextStyle(
                        color: sel
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.grey),
                        fontSize: 12,
                        fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_query.isEmpty) return _buildSuggestions(isDark);

    final users = _filteredUsers;
    final services = _tabIndex == 3
        ? _serviceResults
        : (_tabIndex == 0 ? _serviceResults : []);
    final hasResults = users.isNotEmpty || services.isNotEmpty;

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.secondary));
    }

    if (!hasResults) return _buildEmpty(isDark);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Users section
        if (users.isNotEmpty) ...[
          _buildSectionHeader(
              isDark,
              _tabIndex == 1
                  ? 'Photographer (${users.length})'
                  : _tabIndex == 2
                  ? 'Makeup Artist (${users.length})'
                  : 'Nhà cung cấp (${users.length})'),
          ...users.map((u) => _UserResultTile(
            user: u,
            isDark: isDark,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PublicProfileScreen(userId: u['uid']))),
          )),
        ],
        // Services section
        if (services.isNotEmpty) ...[
          _buildSectionHeader(isDark, 'Dịch vụ (${services.length})'),
          ...services.map((s) => _ServiceResultTile(
            service: s,
            isDark: isDark,
            onTapProvider: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      PublicProfileScreen(userId: s['providerId'])),
            ),
            onBook: () {
              final isPhoto = s['providerRole'] == 'photographer';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingStep1Screen(
                    preSelectedPhotographer: isPhoto
                        ? {
                      'uid': s['providerId'],
                      'fullName': s['providerName'],
                      'price': s['price'],
                      'role': s['providerRole'],
                      'serviceName': s['name'],
                    }
                        : null,
                    preSelectedMakeuper: !isPhoto
                        ? {
                      'uid': s['providerId'],
                      'fullName': s['providerName'],
                      'price': s['price'],
                      'role': s['providerRole'],
                      'serviceName': s['name'],
                    }
                        : null,
                  ),
                ),
              );
            },
          )),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(title,
          style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildEmpty(bool isDark) {
    final hasDistrictFilter = _detectedDistrict != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            hasDistrictFilter
                ? Icons.location_off_rounded
                : Icons.search_off_rounded,
            size: 56,
            color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasDistrictFilter
                ? 'Không tìm thấy provider tại $_detectedDistrict'
                : 'Không có kết quả',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasDistrictFilter
                ? 'Thử tìm không kèm tên quận hoặc tìm ở khu vực khác'
                : 'Thử từ khóa khác hoặc thêm tên quận\nvd: "chụp ảnh gò vấp"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[400],
              fontSize: 13,
            ),
          ),
          if (hasDistrictFilter) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() => _detectedDistrict = null);
                _search(_query);
              },
              icon: const Icon(Icons.close_rounded, size: 15),
              label: const Text('Bỏ lọc khu vực'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondary,
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    final suggestions = [
      ('chụp ảnh cưới', null),
      ('makeup cô dâu', null),
      ('chụp ảnh gò vấp', 'Gò Vấp'),
      ('makeup quận 1', 'Quận 1'),
      ('chụp ảnh kỷ yếu', null),
      ('makeup bình thạnh', 'Bình Thạnh'),
      ('chụp ảnh sản phẩm', null),
      ('makeup sự kiện', null),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Tìm kiếm phổ biến',
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map((s) => GestureDetector(
            onTap: () {
              _searchCtrl.text = s.$1;
              _search(s.$1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.inputFill : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  s.$2 != null
                      ? Icons.location_on_rounded
                      : Icons.trending_up_rounded,
                  size: 14,
                  color: s.$2 != null
                      ? AppTheme.secondary
                      : (isDark ? Colors.white38 : Colors.grey),
                ),
                const SizedBox(width: 6),
                Text(s.$1,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : AppTheme.lightTextPrimary,
                        fontSize: 13)),
              ]),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}

// ── User result tile ─────────────────────────────────────────
class _UserResultTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onTap;

  const _UserResultTile(
      {required this.user, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPhoto = user['role'] == 'photographer';
    final color =
    isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    final name = user['fullName'] ?? '';
    final bio = user['bio'] ?? '';
    final rating = (user['rating'] as num?)?.toDouble() ?? 0.0;
    final districts = user['districts'] as List? ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.inputFill : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.withOpacity(0.12)),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4), width: 2)),
              child: Icon(
                  isPhoto
                      ? Icons.camera_alt_rounded
                      : Icons.brush_rounded,
                  color: color,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    if (bio.isNotEmpty)
                      Text(bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
                              fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (rating > 0) ...[
                        Icon(Icons.star_rounded,
                            color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1),
                            style: TextStyle(
                                color:
                                isDark ? Colors.white54 : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                      ],
                      // District badges (max 2)
                      ...districts.take(2).map((d) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded,
                                  color: color, size: 9),
                              const SizedBox(width: 2),
                              Text(d.toString(),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ]),
                      )),
                      if (districts.length > 2)
                        Text('+${districts.length - 2}',
                            style: TextStyle(
                                color:
                                isDark ? Colors.white38 : Colors.grey,
                                fontSize: 10)),
                    ]),
                  ]),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : Colors.grey[300]),
          ]),
        ),
      ),
    );
  }
}

// ── Service result tile ──────────────────────────────────────
class _ServiceResultTile extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool isDark;
  final VoidCallback onBook;
  final VoidCallback onTapProvider;

  const _ServiceResultTile(
      {required this.service,
        required this.isDark,
        required this.onBook,
        required this.onTapProvider});

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  @override
  Widget build(BuildContext context) {
    final isPhoto = service['providerRole'] == 'photographer';
    final color =
    isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    final name = service['name'] ?? '';
    final desc = service['description'] ?? '';
    final providerName = service['providerName'] ?? '';
    final price = (service['price'] as num?) ?? 0;
    final providerDistricts =
        service['providerDistricts'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.inputFill : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.12)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child:
            Icon(Icons.design_services_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  if (desc.isNotEmpty)
                    Text(desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontSize: 11)),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: onTapProvider,
                    child: Row(children: [
                      Icon(isPhoto
                          ? Icons.camera_alt_rounded
                          : Icons.brush_rounded,
                          color: color,
                          size: 11),
                      const SizedBox(width: 4),
                      Text(providerName,
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey[600],
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                              decorationColor: isDark
                                  ? Colors.white38
                                  : Colors.grey[400])),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: isDark ? Colors.white38 : Colors.grey[400]),
                      if (providerDistricts.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_rounded,
                            color: isDark ? Colors.white38 : Colors.grey,
                            size: 11),
                        const SizedBox(width: 2),
                        Text(
                          providerDistricts.take(1).join(', ') +
                              (providerDistricts.length > 1
                                  ? ' +${providerDistricts.length - 1}'
                                  : ''),
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey[500],
                              fontSize: 11),
                        ),
                      ],
                    ]),
                  ),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              price > 0 ? _fmt(price.toInt()) : 'Liên hệ',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onBook,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Đặt ngay',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}