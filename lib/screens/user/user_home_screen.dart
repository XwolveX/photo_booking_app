// lib/screens/user/user_home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/service_model.dart';
import '../auth/login_screen.dart';
import '../booking/booking_step1_providers.dart';

// ── Banner Widget ─────────────────────────────────────────────
class _BannerSlider extends StatefulWidget {
  const _BannerSlider();
  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  int _index = 0;
  final _ctrl = PageController();
  Timer? _timer;

  final _banners = const [
    {'title': 'Chụp ảnh kỷ niệm\n20% OFF', 'subtitle': 'Ưu đãi cuối tuần',
      'color1': Color(0xFFE94560), 'color2': Color(0xFF0F3460), 'icon': Icons.camera_alt_rounded},
    {'title': 'Makeup cô dâu\ntrọn gói', 'subtitle': 'Từ 800.000đ',
      'color1': Color(0xFFCE93D8), 'color2': Color(0xFF7B1FA2), 'icon': Icons.brush_rounded},
    {'title': 'Booking ngay\nnhận quà', 'subtitle': 'Ưu đãi tháng này',
      'color1': Color(0xFF4FC3F7), 'color2': Color(0xFF0277BD), 'icon': Icons.card_giftcard_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _ctrl.animateToPage((_index + 1) % _banners.length,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() { _timer?.cancel(); _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      SizedBox(
        height: 160,
        child: PageView.builder(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: _banners.length,
          itemBuilder: (context, i) {
            final b = _banners[i];
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [b['color1'] as Color, b['color2'] as Color],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(b['subtitle'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                        const SizedBox(height: 3),
                        Text(b['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.2)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: const Text('Đặt ngay', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ])),
                  Icon(b['icon'] as IconData, color: Colors.white.withOpacity(0.2), size: 70),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_banners.length, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _index == i ? 20 : 6, height: 6,
          decoration: BoxDecoration(
            color: _index == i ? AppTheme.secondary : (isDark ? Colors.white24 : Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      ),
    ]);
  }
}

// ── Main Screen ───────────────────────────────────────────────
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      body: CustomScrollView(slivers: [
        _buildAppBar(isDark, user),
        SliverToBoxAdapter(child: _buildSearchBar(isDark)),
        const SliverToBoxAdapter(child: _BannerSlider()),
        SliverToBoxAdapter(child: _buildFilterTabs(isDark)),
        SliverToBoxAdapter(child: _buildProviderServiceList(isDark)),
        SliverToBoxAdapter(child: _buildPostsFeed(isDark)),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ]),
    );
  }

  Widget _buildAppBar(bool isDark, UserModel? user) {
    return SliverAppBar(
      floating: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      title: Row(children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 8),
        Text('SnapBook', style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800, fontSize: 18)),
      ]),
      actions: [
        IconButton(
          icon: Icon(context.watch<ThemeProvider>().isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.amber : Colors.orange),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        Stack(children: [
          IconButton(icon: Icon(Icons.notifications_outlined,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary), onPressed: () {}),
          Positioned(right: 8, top: 8,
              child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle))),
        ]),
        GestureDetector(
          onTap: () => _logout(context),
          child: Padding(padding: const EdgeInsets.only(right: 12),
            child: Container(width: 34, height: 34,
                decoration: BoxDecoration(color: AppTheme.roleUser.withOpacity(0.15), shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.roleUser.withOpacity(0.4))),
                child: const Icon(Icons.person_rounded, color: AppTheme.roleUser, size: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary),
        decoration: InputDecoration(
          hintText: 'Tìm dịch vụ, photographer, makeup...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear),
              onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    final tabs = ['Tất cả', 'Photographer', 'Makeup Artist'];
    final colors = [Colors.grey, AppTheme.rolePhotographer, AppTheme.roleMakeuper];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Khám phá dịch vụ', style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(children: List.generate(3, (i) {
          final sel = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? colors[i].withOpacity(0.15) : (isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? colors[i] : Colors.transparent, width: 1.5),
                ),
                child: Text(tabs[i], style: TextStyle(
                    color: sel ? colors[i] : (isDark ? Colors.white54 : Colors.grey),
                    fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
              ),
            ),
          );
        })),
      ]),
    );
  }

  Widget _buildProviderServiceList(bool isDark) {
    Query providerQuery = FirebaseFirestore.instance.collection('users');
    if (_selectedFilter == 1) {
      providerQuery = providerQuery.where('role', isEqualTo: 'photographer');
    } else if (_selectedFilter == 2) {
      providerQuery = providerQuery.where('role', isEqualTo: 'makeuper');
    } else {
      providerQuery = providerQuery.where('role', whereIn: ['photographer', 'makeuper']);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: providerQuery.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator(color: AppTheme.secondary)));
        }

        var providers = snap.data?.docs ?? [];
        if (_searchQuery.isNotEmpty) {
          providers = providers.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['fullName'] ?? '').toLowerCase().contains(_searchQuery) ||
                (data['bio'] ?? '').toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (providers.isEmpty) {
          return Padding(padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Không tìm thấy kết quả',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))));
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('${providers.length} nhà cung cấp',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13)),
            ),
            ...providers.map((doc) => _ProviderServiceCard(
              providerId: doc.id,
              providerData: doc.data() as Map<String, dynamic>,
              isDark: isDark,
              searchQuery: _searchQuery,
            )),
          ]),
        );
      },
    );
  }

  Widget _buildPostsFeed(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts')
          .orderBy('createdAt', descending: true).limit(10).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty && snap.connectionState != ConnectionState.waiting) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('📝 Bài viết mới nhất', style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 17, fontWeight: FontWeight.w800))),
          if (snap.connectionState == ConnectionState.waiting)
            const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
          ...docs.map((doc) => _buildPostCard(
              PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id), isDark)),
        ]);
      },
    );
  }

  Widget _buildPostCard(PostModel post, bool isDark) {
    final isPhoto = post.authorRole == 'photographer';
    final color = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.4))),
                  child: Icon(isPhoto ? Icons.camera_alt_rounded : Icons.brush_rounded, color: color, size: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post.authorName, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${isPhoto ? 'Photographer' : 'Makeup Artist'} · ${post.timeAgo}',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
              ])),
            ])),
        Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.title, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 6),
              Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700], fontSize: 13, height: 1.5)),
            ])),
        Divider(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1), height: 1),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Icon(Icons.favorite_border_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 18),
              const SizedBox(width: 5),
              Text('${post.likeCount}', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 18),
              const SizedBox(width: 5),
              Text('${post.commentCount}', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
            ])),
      ]),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }
}

// ── Provider Card với services ────────────────────────────────
class _ProviderServiceCard extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic> providerData;
  final bool isDark;
  final String searchQuery;

  const _ProviderServiceCard({
    required this.providerId, required this.providerData,
    required this.isDark, required this.searchQuery,
  });

  @override
  State<_ProviderServiceCard> createState() => _ProviderServiceCardState();
}

class _ProviderServiceCardState extends State<_ProviderServiceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isPhoto = widget.providerData['role'] == 'photographer';
    final color = isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;
    final name = widget.providerData['fullName'] ?? '';
    final bio = widget.providerData['bio'] ?? 'Chưa có mô tả';
    final rating = (widget.providerData['rating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Provider header
        Padding(padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.4), width: 2)),
                  child: Icon(isPhoto ? Icons.camera_alt_rounded : Icons.brush_rounded, color: color, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(name, style: TextStyle(
                      color: widget.isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700, fontSize: 15))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(isPhoto ? 'Photo' : 'Makeup',
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(bio, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: widget.isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                  const SizedBox(width: 3),
                  Text(rating > 0 ? rating.toStringAsFixed(1) : 'Mới',
                      style: TextStyle(color: widget.isDark ? Colors.white60 : Colors.grey[700],
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ])),
            ])),

        // Services
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services')
              .where('providerId', isEqualTo: widget.providerId).snapshots(),
          builder: (context, snap) {
            var services = (snap.data?.docs ?? [])
                .map((d) => ServiceModel.fromFirestore(d.data() as Map<String, dynamic>, d.id))
                .toList();

            if (widget.searchQuery.isNotEmpty) {
              services = services.where((s) =>
              s.name.toLowerCase().contains(widget.searchQuery) ||
                  s.description.toLowerCase().contains(widget.searchQuery)
              ).toList();
            }

            if (snap.connectionState == ConnectionState.waiting) {
              return Padding(padding: const EdgeInsets.all(16),
                  child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color))));
            }

            if (services.isEmpty) {
              return Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      Icon(Icons.inbox_rounded, color: color.withOpacity(0.3), size: 20),
                      const SizedBox(height: 4),
                      Text('Chưa có dịch vụ nào',
                          style: TextStyle(color: widget.isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
                    ]),
                  ));
            }

            final displayed = _expanded ? services : services.take(2).toList();

            return Column(children: [
              Divider(color: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1), height: 1),
              ...displayed.map((s) => _ServiceRow(
                service: s, color: color, isDark: widget.isDark,
                onBook: () => _goToBooking(context, s, isPhoto),
              )),
              if (services.length > 2)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_expanded ? 'Thu gọn' : 'Xem thêm ${services.length - 2} dịch vụ',
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: color, size: 16),
                    ]),
                  ),
                )
              else
                const SizedBox(height: 10),
            ]);
          },
        ),
      ]),
    );
  }

  void _goToBooking(BuildContext context, ServiceModel service, bool isPhoto) {
    final providerMap = {
      'uid': widget.providerId,
      'fullName': widget.providerData['fullName'] ?? '',
      'bio': widget.providerData['bio'] ?? '',
      'price': service.price,
      'rating': widget.providerData['rating'],
      'role': widget.providerData['role'],
      'serviceName': service.name,
    };

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BookingStep1Screen(
        preSelectedPhotographer: isPhoto ? providerMap : null,
        preSelectedMakeuper: !isPhoto ? providerMap : null,
      ),
    ));
  }
}

// ── Service Row ───────────────────────────────────────────────
class _ServiceRow extends StatelessWidget {
  final ServiceModel service;
  final Color color;
  final bool isDark;
  final VoidCallback onBook;

  const _ServiceRow({required this.service, required this.color, required this.isDark, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.design_services_rounded, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(service.name, style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w600, fontSize: 13)),
          Text(service.description, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 11)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(service.formattedPrice,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onBook,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: const Text('Đặt lịch',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }
}