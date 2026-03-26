import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
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
  final _mapCtrl = MapController();
  LatLng _selectedLatLng = const LatLng(10.7769, 106.7009);

  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  String _selectedAddress = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool get _canProceed => _selectedAddress.isNotEmpty;

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(
        const Duration(milliseconds: 500), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json&addressdetails=1&limit=6&countrycodes=vn&accept-language=vi',
      );
      final res =
      await http.get(url, headers: {'User-Agent': 'SnapBookApp/1.0'});
      final data = json.decode(res.body) as List;
      setState(() {
        _suggestions = data.map((item) {
          final displayName = item['display_name'] as String? ?? '';
          final parts = displayName.split(', ');
          return {
            'placeId': item['place_id'].toString(),
            'displayName': displayName,
            'mainText': parts.first,
            'secondaryText': parts.skip(1).take(3).join(', '),
            'lat': double.parse(item['lat'].toString()),
            'lon': double.parse(item['lon'].toString()),
          };
        }).toList();
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } catch (_) {
      setState(() => _suggestions = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    _searchFocus.unfocus();
    final lat = place['lat'] as double;
    final lon = place['lon'] as double;
    final latLng = LatLng(lat, lon);
    setState(() {
      _showSuggestions = false;
      _selectedLatLng = latLng;
      _selectedAddress = place['displayName'] as String;
      _searchCtrl.text = place['mainText'] as String;
    });
    _mapCtrl.move(latLng, 16);
  }

  Future<void> _onMapTap(TapPosition _, LatLng latLng) async {
    _searchFocus.unfocus();
    setState(() {
      _selectedLatLng = latLng;
      _showSuggestions = false;
      _isSearching = true;
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json&accept-language=vi',
      );
      final res =
      await http.get(url, headers: {'User-Agent': 'SnapBookApp/1.0'});
      final data = json.decode(res.body) as Map<String, dynamic>;
      final address = data['display_name'] as String? ??
          '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
      setState(() {
        _selectedAddress = address;
        final parts = address.split(', ');
        _searchCtrl.text = parts.first;
      });
    } catch (_) {
      final fallback =
          '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
      setState(() {
        _selectedAddress = fallback;
        _searchCtrl.text = fallback;
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _searchFocus.unfocus();
        setState(() => _showSuggestions = false);
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.primary : AppTheme.lightBg,
        appBar: _buildAppBar(isDark),
        body: Column(
          children: [
            _buildStepIndicator(isDark),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: _buildSearchBar(isDark),
                      ),
                      Expanded(child: _buildMap(isDark)),
                      _buildNoteField(isDark),
                    ],
                  ),
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    _buildSuggestionsOverlay(isDark),
                ],
              ),
            ),
            _buildNextButton(isDark),
          ],
        ),
      ),
    );
  }

  // ── Step Indicator Helpers ──────────────────────────────────

  Widget _buildStepIndicator(bool isDark) {
    final labels = ['Dịch vụ', 'Ngày giờ', 'Địa điểm', 'Xác nhận'];
    const activeStep = 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _stepCircle(1, activeStep, true, isDark),
              Expanded(child: _stepConnector(true, isDark)),
              _stepCircle(2, activeStep, true, isDark),
              Expanded(child: _stepConnector(true, isDark)),
              _stepCircle(3, activeStep, false, isDark),
              Expanded(child: _stepConnector(false, isDark)),
              _stepCircle(4, activeStep, false, isDark),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _stepLabel(labels[0], 1 == activeStep, isDark, done: true),
              const Expanded(child: SizedBox()),
              _stepLabel(labels[1], 2 == activeStep, isDark, done: true),
              const Expanded(child: SizedBox()),
              _stepLabel(labels[2], 3 == activeStep, isDark),
              const Expanded(child: SizedBox()),
              _stepLabel(labels[3], 4 == activeStep, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepCircle(int step, int active, bool done, bool isDark) {
    final isActive = step == active;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: done
            ? AppTheme.success
            : isActive
            ? AppTheme.secondary
            : (isDark ? AppTheme.inputFill : Colors.grey.withOpacity(0.15)),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppTheme.secondary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
            : Text(
          '$step',
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white38 : Colors.grey),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _stepConnector(bool done, bool isDark) {
    return Container(
      height: 2,
      color: done
          ? AppTheme.success.withOpacity(0.5)
          : (isDark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
    );
  }

  Widget _stepLabel(String label, bool isActive, bool isDark,
      {bool done = false}) {
    return SizedBox(
      width: 28,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: done
              ? AppTheme.success
              : isActive
              ? AppTheme.secondary
              : (isDark ? Colors.white38 : Colors.grey),
          fontSize: 10,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  // ── Other Widgets ───────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            size: 20),
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

  Widget _buildSearchBar(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.inputFill : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: isDark
                      ? Colors.black26
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tìm đường, địa điểm, quận...',
              hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  fontSize: 14),
              prefixIcon: _isSearching
                  ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.secondary),
                  ))
                  : const Icon(Icons.search_rounded,
                  color: AppTheme.secondary, size: 22),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: isDark ? Colors.white38 : Colors.grey,
                      size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                      _selectedAddress = '';
                    });
                  })
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_selectedAddress.isNotEmpty && !_showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_selectedAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey[700],
                          fontSize: 11,
                          height: 1.4)),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionsOverlay(bool isDark) {
    return Positioned(
      top: _selectedAddress.isNotEmpty ? 116 : 68,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2D) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.08),
              indent: 52,
            ),
            itemBuilder: (ctx, i) {
              final s = _suggestions[i];
              return InkWell(
                onTap: () => _selectSuggestion(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppTheme.secondary, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['mainText'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.lightTextPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          if ((s['secondaryText'] as String).isNotEmpty)
                            Text(s['secondaryText'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey,
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.north_west_rounded,
                        color: Colors.grey, size: 13),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _selectedLatLng,
            initialZoom: 14,
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: isDark
                  ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dinhlam2901.booking_app',
            ),
            if (_selectedAddress.isNotEmpty)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLatLng,
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.location_on_rounded,
                        color: AppTheme.secondary, size: 48),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _isSearching
                        ? 'Đang lấy địa chỉ...'
                        : 'Nhấn để ghim vị trí',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isSearching)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.secondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteField(bool isDark) {
    return Container(
      color: isDark ? AppTheme.primary : AppTheme.lightBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _noteCtrl,
        style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontSize: 13),
        decoration: InputDecoration(
          hintText:
          'Ghi chú: phong cách, số người, yêu cầu đặc biệt...',
          hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[400],
              fontSize: 13),
          prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        maxLines: 2,
        maxLength: 300,
      ),
    );
  }

  Widget _buildNextButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
                address: _selectedAddress,
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
            disabledBackgroundColor: isDark
                ? AppTheme.inputFill
                : Colors.grey.withOpacity(0.15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _canProceed
                    ? 'Tiếp theo'
                    : 'Nhấn bản đồ để chọn vị trí',
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