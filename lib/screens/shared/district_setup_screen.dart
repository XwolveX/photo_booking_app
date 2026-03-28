// lib/screens/shared/district_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class DistrictSetupScreen extends StatefulWidget {
  final bool isFromPopup;

  const DistrictSetupScreen({super.key, this.isFromPopup = false});

  @override
  State<DistrictSetupScreen> createState() => _DistrictSetupScreenState();
}

class _DistrictSetupScreenState extends State<DistrictSetupScreen> {
  final Set<String> _selected = {};
  bool _isSaving = false;
  bool _isLoading = true;

  static const List<Map<String, dynamic>> _districts = [
    {'name': 'Quận 1', 'group': 'Nội thành'},
    {'name': 'Quận 3', 'group': 'Nội thành'},
    {'name': 'Quận 4', 'group': 'Nội thành'},
    {'name': 'Quận 5', 'group': 'Nội thành'},
    {'name': 'Quận 6', 'group': 'Nội thành'},
    {'name': 'Quận 7', 'group': 'Nội thành'},
    {'name': 'Quận 8', 'group': 'Nội thành'},
    {'name': 'Quận 10', 'group': 'Nội thành'},
    {'name': 'Quận 11', 'group': 'Nội thành'},
    {'name': 'Quận 12', 'group': 'Nội thành'},
    {'name': 'TP. Thủ Đức', 'group': 'TP. Thủ Đức & lân cận'},
    {'name': 'Bình Thạnh', 'group': 'TP. Thủ Đức & lân cận'},
    {'name': 'Gò Vấp', 'group': 'TP. Thủ Đức & lân cận'},
    {'name': 'Phú Nhuận', 'group': 'TP. Thủ Đức & lân cận'},
    {'name': 'Tân Bình', 'group': 'TP. Thủ Đức & lân cận'},
    {'name': 'Tân Phú', 'group': 'TP. Thủ Đức & lân cận'},
    {'name': 'Bình Chánh', 'group': 'Ngoại thành'},
    {'name': 'Cần Giờ', 'group': 'Ngoại thành'},
    {'name': 'Củ Chi', 'group': 'Ngoại thành'},
    {'name': 'Hóc Môn', 'group': 'Ngoại thành'},
    {'name': 'Nhà Bè', 'group': 'Ngoại thành'},
  ];

  static const Map<String, String> _groupEmoji = {
    'Nội thành': '🏙️',
    'TP. Thủ Đức & lân cận': '🌆',
    'Ngoại thành': '🌿',
  };

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final d in _districts) {
      final g = d['group'] as String;
      map.putIfAbsent(g, () => []).add(d);
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null && data['districts'] != null) {
        final existing = List<String>.from(data['districts'] as List);
        setState(() => _selected.addAll(existing));
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn ít nhất 1 khu vực hoạt động'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = context.read<AuthProvider>().currentUser!.uid;
      final districtList = _selected.toList();

      // 1. Cập nhật user document
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'districts': districtList,
        'districtsUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Sync providerDistricts vào tất cả services của provider này
      //    để search_screen có thể filter service theo quận
      final servicesSnap = await FirebaseFirestore.instance
          .collection('services')
          .where('providerId', isEqualTo: uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in servicesSnap.docs) {
        batch.update(doc.reference, {'providerDistricts': districtList});
      }
      await batch.commit();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu khu vực: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;
    final isPhoto = user?.role.name == 'photographer';
    final roleColor =
        isPhoto ? AppTheme.rolePhotographer : AppTheme.roleMakeuper;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        elevation: 0,
        title: Text(
          'Khu vực hoạt động',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
              widget.isFromPopup
                  ? Icons.close_rounded
                  : Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white54 : Colors.grey,
              size: widget.isFromPopup ? 22 : 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: roleColor))
          : Column(
              children: [
                // Header info banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: roleColor.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.location_on_rounded,
                          color: roleColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chọn khu vực bạn hoạt động',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.lightTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Khách hàng tìm "chụp ảnh gò vấp" sẽ thấy bạn',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ]),
                    ),
                  ]),
                ),

                // Selected count + clear
                if (_selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: roleColor.withOpacity(0.3)),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: roleColor, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'Đã chọn ${_selected.length} khu vực',
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ]),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selected.clear()),
                        child: Text(
                          'Bỏ chọn tất cả',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ]),
                  ),

                // District list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children:
                        _grouped.entries.map((entry) {
                      final group = entry.key;
                      final items = entry.value;
                      final emoji = _groupEmoji[group] ?? '📍';

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 16, bottom: 8),
                            child: Text(
                              '$emoji $group',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: items.map((d) {
                              final name = d['name'] as String;
                              final isSelected =
                                  _selected.contains(name);

                              return GestureDetector(
                                onTap: () => setState(() {
                                  if (isSelected) {
                                    _selected.remove(name);
                                  } else {
                                    _selected.add(name);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? roleColor
                                        : (isDark
                                            ? AppTheme.inputFill
                                            : Colors.white),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? roleColor
                                          : (isDark
                                              ? Colors.white
                                                  .withOpacity(0.08)
                                              : Colors.grey
                                                  .withOpacity(
                                                      0.15)),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: roleColor
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(
                                                  0, 3),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected) ...[
                                          const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 13),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.white70
                                                    : AppTheme
                                                        .lightTextPrimary),
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ]),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

      // Save button
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Lưu khu vực (${_selected.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ]),
          ),
        ),
      ),
    );
  }
}
