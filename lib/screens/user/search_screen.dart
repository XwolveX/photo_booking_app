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

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

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
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _query = query.trim();
    });

    try {
      final q = query.trim().toLowerCase();

      // Search users (photographer + makeuper)
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['photographer', 'makeuper'])
          .get();

      final users = usersSnap.docs
          .where((d) {
            final data = d.data();
            final name = (data['fullName'] ?? '').toLowerCase();
            final bio = (data['bio'] ?? '').toLowerCase();
            return name.contains(q) || bio.contains(q);
          })
          .map((d) => {'uid': d.id, ...d.data()})
          .toList();

      // Search services
      final servicesSnap = await FirebaseFirestore.instance
          .collection('services')
          .get();

      final services = servicesSnap.docs
          .where((d) {
            final data = d.data();
            final name = (data['name'] ?? '').toLowerCase();
            final desc = (data['description'] ?? '').toLowerCase();
            final providerName = (data['providerName'] ?? '').toLowerCase();
            return name.contains(q) || desc.contains(q) || providerName.contains(q);
          })
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

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
    if (_tabIndex == 1) return _userResults.where((u) => u['role'] == 'photographer').toList();
    if (_tabIndex == 2) return _userResults.where((u) => u['role'] == 'makeuper').toList();
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
              Expanded(child: _buildResults(isDark)),
            ],
          ),
        ),
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
                color: isDark ? AppTheme.inputFill : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onChanged: (v) {
                  if (v.trim().length >= 2) {
                    _search(v);
                  } else if (v.isEmpty) {
                    setState(() {
                      _userResults = [];
                      _serviceResults = [];
                      _query = '';
                    });
                  }
                },
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm photographer, makeup, dịch vụ...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.secondary),
                          ),
                        )
                      : const Icon(Icons.search_rounded,
                          color: AppTheme.secondary, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              color: isDark ? Colors.white38 : Colors.grey,
                              size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _userResults = [];
                              _serviceResults = [];
                              _query = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    final tabs = [
      ('Tất cả', Icons.apps_rounded),
      ('Photo', Icons.camera_alt_rounded),
      ('Makeup', Icons.brush_rounded),
      ('Dịch vụ', Icons.design_services_rounded),
    ];
    return Container(
      color: isDark ? AppTheme.surface : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = _tabIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? AppTheme.secondary
                        : (isDark ? Colors.white24 : Colors.grey.withOpacity(0.3)),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(tabs[i].$2,
                      size: 13,
                      color: sel
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey)),
                  const SizedBox(width: 5),
                  Text(tabs[i].$1,
                      style: TextStyle(
                          color: sel
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.grey),
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_query.isEmpty) return _buildSuggestions(isDark);

    final users = _filteredUsers;
    final services = _tabIndex == 3 ? _serviceResults : (_tabIndex == 0 ? _serviceResults : []);
    final hasResults = users.isNotEmpty || services.isNotEmpty;

    if (!_isLoading && !hasResults) {
      return _buildEmpty(isDark);
    }

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
                      : 'Người dùng (${users.length})'),
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

  Widget _buildSuggestions(bool isDark) {
    final suggestions = [
      'Chụp ảnh cưới',
      'Makeup cô dâu',
      'Chụp ảnh kỷ yếu',
      'Makeup sự kiện',
      'Chụp ảnh sản phẩm',
      'Makeup hàng ngày',
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
                      _searchCtrl.text = s;
                      _search(s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.inputFill
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.trending_up_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.grey),
                        const SizedBox(width: 6),
                        Text(s,
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

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded,
            size: 56, color: isDark ? Colors.white24 : Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Không tìm thấy "$_query"',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Thử tìm kiếm với từ khóa khác',
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey,
                fontSize: 13)),
      ]),
    );
  }
}

// ── User Result Tile ──────────────────────────────────────────
class _UserResultTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onTap;

  const _UserResultTile(
      {required this.user, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPhoto = user['role'] == 'photographer';
    final color = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    final name = user['fullName'] ?? '';
    final bio = user['bio'] ?? '';
    final rating = (user['rating'] as num?)?.toDouble() ?? 0.0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: user['avatarUrl'] != null
                ? ClipOval(
                    child: Image.network(user['avatarUrl'], fit: BoxFit.cover))
                : Icon(
                    isPhoto ? Icons.camera_alt_rounded : Icons.brush_rounded,
                    color: color,
                    size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(name,
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(isPhoto ? 'Photographer' : 'Makeup Artist',
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 12)),
              ],
              if (rating > 0) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 12),
                  const SizedBox(width: 3),
                  Text(rating.toStringAsFixed(1),
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: isDark ? Colors.white24 : Colors.grey[300]),
        ]),
      ),
    );
  }
}

// ── Service Result Tile ───────────────────────────────────────
class _ServiceResultTile extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool isDark;
  final VoidCallback onBook;

  const _ServiceResultTile(
      {required this.service, required this.isDark, required this.onBook});

  String _formatPrice(num price) {
    if (price <= 0) return 'Liên hệ';
    final s = price.toInt().toString();
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
    final color = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    final name = service['name'] ?? '';
    final desc = service['description'] ?? '';
    final providerName = service['providerName'] ?? '';
    final price = (service['price'] as num?) ?? 0;

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
            child: Icon(Icons.design_services_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
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
              Row(children: [
                Icon(isPhoto ? Icons.camera_alt_rounded : Icons.brush_rounded,
                    size: 11, color: color),
                const SizedBox(width: 4),
                Text(providerName,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_formatPrice(price),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onBook,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: const Text('Đặt lịch',
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
