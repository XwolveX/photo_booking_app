// lib/screens/shared/manage_services_screen.dart
// Màn hình quản lý dịch vụ cho Photographer & Makeuper

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/service_model.dart';

class ManageServicesScreen extends StatelessWidget {
  const ManageServicesScreen({super.key});

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
        title: Text('Dịch vụ của tôi',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showServiceDialog(context, isDark, roleColor, user.uid, isPhoto),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Thêm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('providerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: roleColor));
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState(context, isDark, roleColor, user.uid, isPhoto);
          }

          final services = docs
              .map((d) => ServiceModel.fromFirestore(d.data() as Map<String, dynamic>, d.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, i) => _ServiceCard(
              service: services[i],
              roleColor: roleColor,
              isDark: isDark,
              onEdit: () => _showServiceDialog(
                  context, isDark, roleColor, user.uid, isPhoto, service: services[i]),
              onDelete: () => _confirmDelete(context, isDark, services[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color color, String uid, bool isPhoto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.design_services_rounded, color: color.withOpacity(0.5), size: 40),
          ),
          const SizedBox(height: 20),
          Text('Chưa có dịch vụ nào',
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            isPhoto
                ? 'Thêm các gói chụp ảnh để khách hàng dễ dàng đặt lịch với bạn'
                : 'Thêm các gói makeup để khách hàng dễ dàng đặt lịch với bạn',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => _showServiceDialog(context, isDark, color, uid, isPhoto),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Thêm dịch vụ đầu tiên',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // Dialog thêm / sửa dịch vụ
  void _showServiceDialog(
      BuildContext context,
      bool isDark,
      Color roleColor,
      String uid,
      bool isPhoto, {
        ServiceModel? service,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(
        isDark: isDark,
        roleColor: roleColor,
        providerId: uid,
        isPhoto: isPhoto,
        existing: service,
      ),
    );
  }

  void _confirmDelete(BuildContext context, bool isDark, ServiceModel service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xóa dịch vụ?',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc muốn xóa "${service.name}" không? Hành động này không thể hoàn tác.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('services').doc(service.id).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('🗑️ Đã xóa dịch vụ'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Service Card ──────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final Color roleColor;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.roleColor,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: roleColor.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: roleColor.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.design_services_rounded, color: roleColor, size: 24),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(service.name,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.w700, fontSize: 15)),
            if (service.description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(service.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12, height: 1.4)),
            ],
            const SizedBox(height: 6),
            Text(service.formattedPrice,
                style: TextStyle(color: roleColor, fontWeight: FontWeight.w800, fontSize: 15)),
          ])),
          // Actions
          Column(children: [
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_rounded, color: roleColor, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Form Sheet (thêm / sửa) ───────────────────────────────────
class _ServiceFormSheet extends StatefulWidget {
  final bool isDark;
  final Color roleColor;
  final String providerId;
  final bool isPhoto;
  final ServiceModel? existing;

  const _ServiceFormSheet({
    required this.isDark,
    required this.roleColor,
    required this.providerId,
    required this.isPhoto,
    this.existing,
  });

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _isLoading = false;

  // Gợi ý nhanh theo role
  late final List<String> _quickNames;

  @override
  void initState() {
    super.initState();
    _quickNames = widget.isPhoto
        ? ['Chụp ảnh cưới', 'Chụp ảnh kỷ yếu', 'Chụp ảnh sản phẩm', 'Chụp ảnh sự kiện', 'Chụp ảnh cá nhân', 'Chụp ảnh gia đình']
        : ['Makeup cô dâu', 'Makeup dự tiệc', 'Makeup hàng ngày', 'Makeup chụp hình', 'Makeup sân khấu', 'Gội đầu & tạo kiểu'];

    // Nếu đang sửa → điền sẵn data
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _descCtrl.text = widget.existing!.description;
      _priceCtrl.text = widget.existing!.price > 0 ? widget.existing!.price.toInt().toString() : '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vui lòng nhập tên dịch vụ'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().currentUser!;
      final price = double.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0;

      final data = {
        'providerId': widget.providerId,
        'providerName': user.fullName,
        'providerRole': user.role.name,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': price,
        'createdAt': widget.existing?.createdAt ?? DateTime.now(),
      };

      if (widget.existing != null) {
        // Sửa
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.existing!.id)
            .update(data);
      } else {
        // Thêm mới
        await FirebaseFirestore.instance.collection('services').add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.existing != null ? '✅ Đã cập nhật dịch vụ' : '✅ Đã thêm dịch vụ mới'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle bar
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white24 : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        const SizedBox(height: 20),

        // Title
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: widget.roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded, color: widget.roleColor, size: 18),
          ),
          const SizedBox(width: 10),
          Text(isEdit ? 'Chỉnh sửa dịch vụ' : 'Thêm dịch vụ mới',
              style: TextStyle(
                  color: widget.isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 20),

        // Quick select tên dịch vụ
        if (!isEdit) ...[
          Text('Gợi ý nhanh', style: TextStyle(
              color: widget.isDark ? Colors.white54 : Colors.grey,
              fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _quickNames.map((name) => GestureDetector(
              onTap: () => setState(() => _nameCtrl.text = name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _nameCtrl.text == name
                      ? widget.roleColor.withOpacity(0.15)
                      : (widget.isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _nameCtrl.text == name ? widget.roleColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(name, style: TextStyle(
                    color: _nameCtrl.text == name
                        ? widget.roleColor
                        : (widget.isDark ? Colors.white60 : Colors.grey[600]),
                    fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Tên dịch vụ
        _buildLabel('Tên dịch vụ *'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _nameCtrl,
          hint: 'VD: Chụp ảnh cưới, Makeup cô dâu...',
          icon: Icons.design_services_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),

        // Mô tả
        _buildLabel('Mô tả'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _descCtrl,
          hint: 'Mô tả chi tiết về dịch vụ...',
          icon: Icons.description_rounded,
          maxLines: 2,
        ),
        const SizedBox(height: 14),

        // Giá
        _buildLabel('Giá (đ)'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _priceCtrl,
          hint: 'VD: 500000 (để trống = Liên hệ)',
          icon: Icons.monetization_on_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),

        // Nút lưu
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.roleColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor: widget.roleColor.withOpacity(0.4),
            ),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(isEdit ? 'Lưu thay đổi' : 'Thêm dịch vụ',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(
        color: widget.isDark ? Colors.white70 : Colors.grey[700],
        fontSize: 13, fontWeight: FontWeight.w600));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(color: widget.isDark ? Colors.white : AppTheme.lightTextPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: widget.isDark ? Colors.white30 : Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: widget.roleColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}