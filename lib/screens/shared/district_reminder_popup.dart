// lib/screens/shared/district_reminder_popup.dart
//
// Mixin dùng cho PhotographerMainScreen & MakeuperMainScreen.
// Khi provider vào app mà chưa có trường 'districts' (hoặc rỗng),
// popup sẽ xuất hiện sau 800ms để nhắc nhở.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'district_setup_screen.dart';

/// Gọi hàm này trong initState của MainScreen sau khi có uid.
/// [roleColor] là màu tương ứng với role của provider.
Future<void> checkAndShowDistrictReminder({
  required BuildContext context,
  required String uid,
  required Color roleColor,
  required bool isDark,
}) async {
  if (uid.isEmpty) return;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final districts = data['districts'];
    final hasDistricts =
        districts != null && (districts as List).isNotEmpty;

    if (!hasDistricts && context.mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (context.mounted) {
        _showDistrictPopup(
          context: context,
          roleColor: roleColor,
          isDark: isDark,
        );
      }
    }
  } catch (_) {}
}

void _showDistrictPopup({
  required BuildContext context,
  required Color roleColor,
  required bool isDark,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DistrictReminderDialog(
      roleColor: roleColor,
      isDark: isDark,
    ),
  );
}

class _DistrictReminderDialog extends StatelessWidget {
  final Color roleColor;
  final bool isDark;

  const _DistrictReminderDialog({
    required this.roleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: roleColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top accent bar
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [roleColor, roleColor.withOpacity(0.5)],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on_rounded,
                        color: roleColor, size: 34),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    'Chưa có khu vực hoạt động!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Body
                  Text(
                    'Khách hàng không thể tìm thấy bạn khi tìm kiếm theo khu vực.\n\nHãy cài đặt khu vực hoạt động để được hiển thị kết quả tìm kiếm!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DistrictSetupScreen(
                                isFromPopup: true),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: roleColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        elevation: 0,
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.my_location_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Cài đặt ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Skip
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Để sau',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
