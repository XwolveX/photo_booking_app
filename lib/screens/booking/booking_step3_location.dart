// lib/screens/booking/booking_step3_location.dart
// Bước 3: Chọn địa điểm

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_theme.dart';
import 'booking_step4_confirm.dart';

class BookingStep3Screen extends StatefulWidget {
  final Map<String, dynamic>? selectedPhotographer;
  final Map<String, dynamic>? selectedMakeuper;
  final DateTime bookingDate;
  final String timeSlot;

  const BookingStep3Screen({
    super.key,
    this.selectedPhotographer,
    this.selectedMakeuper,
    required this.bookingDate,
    required this.timeSlot,
  });

  @override
  State<BookingStep3Screen> createState() => _BookingStep3ScreenState();
}

class _BookingStep3ScreenState extends State<BookingStep3Screen> {
  GoogleMapController? _mapController;
  LatLng _selectedLatLng =
      const LatLng(10.7769, 106.7009); // Mặc định: TP.HCM
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _mapReady = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  bool get _canProceed => _addressCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildStepIndicator(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMapCard(isDark),
                  const SizedBox(height: 16),
                  _buildAddressField(isDark),
                  const SizedBox(height: 16),
                  _buildNoteField(isDark),
                ],
              ),
            ),
          ),
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
      title: Text('Địa điểm',
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17)),
      centerTitle: true,
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final labels = ['Dịch vụ', 'Ngày giờ', 'Địa điểm', 'Xác nhận'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i == 2;
          final isDone = i < 2;
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
                                : isDone
                                    ? AppTheme.success
                                    : (isDark ? Colors.white38 : Colors.grey),
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400)),
                  ],
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isDone
                          ? AppTheme.success.withOpacity(0.5)
                          : (isDark
                              ? Colors.white12
                              : Colors.grey.withOpacity(0.2)),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMapCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn vị trí trên bản đồ',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Nhấn vào bản đồ để ghim vị trí chụp hình/makeup',
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLatLng,
                zoom: 14,
              ),
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                setState(() => _mapReady = true);
                // Đặt style dark nếu cần
                if (Theme.of(context).brightness == Brightness.dark) {
                  ctrl.setMapStyle(_darkMapStyle);
                }
              },
              onTap: (latLng) {
                setState(() => _selectedLatLng = latLng);
                // Tự động điền địa chỉ gần đúng (sẽ dùng Geocoding API sau)
                _addressCtrl.text =
                    '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
              },
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedLatLng,
                  infoWindow: const InfoWindow(title: 'Địa điểm chụp hình'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRose),
                ),
              },
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),
        // Tọa độ đã chọn
        if (_mapReady)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppTheme.secondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_selectedLatLng.latitude.toStringAsFixed(5)}, ${_selectedLatLng.longitude.toStringAsFixed(5)}',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddressField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Địa chỉ cụ thể *',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressCtrl,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary),
          decoration: InputDecoration(
            hintText: 'VD: 123 Nguyễn Huệ, Quận 1, TP.HCM',
            prefixIcon: const Icon(Icons.location_on_rounded,
                color: AppTheme.secondary),
            suffixIcon: _addressCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _addressCtrl.clear();
                      setState(() {});
                    })
                : null,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildNoteField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ghi chú thêm',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Yêu cầu đặc biệt, phong cách, số người, ...',
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary),
          decoration: const InputDecoration(
            hintText: 'VD: Chụp ảnh cưới, cần 2 bộ trang phục, phong cách vintage...',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
          maxLines: 3,
          maxLength: 300,
        ),
        const SizedBox(height: 16),
      ],
    );
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
                      builder: (_) => BookingStep4Screen(
                        selectedPhotographer: widget.selectedPhotographer,
                        selectedMakeuper: widget.selectedMakeuper,
                        bookingDate: widget.bookingDate,
                        timeSlot: widget.timeSlot,
                        address: _addressCtrl.text.trim(),
                        latitude: _selectedLatLng.latitude,
                        longitude: _selectedLatLng.longitude,
                        note: _noteCtrl.text.trim().isEmpty
                            ? null
                            : _noteCtrl.text.trim(),
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
                _canProceed ? 'Tiếp theo' : 'Nhập địa chỉ',
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
}

// Dark map style
const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#383838"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
]
''';
