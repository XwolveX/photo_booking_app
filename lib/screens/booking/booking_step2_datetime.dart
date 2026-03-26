import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'booking_step3_location.dart';

class BookingStep2Screen extends StatefulWidget {
  final Map<String, dynamic>? selectedPhotographer;
  final Map<String, dynamic>? selectedMakeuper;

  const BookingStep2Screen({
    super.key,
    this.selectedPhotographer,
    this.selectedMakeuper,
  });

  @override
  State<BookingStep2Screen> createState() => _BookingStep2ScreenState();
}

class _BookingStep2ScreenState extends State<BookingStep2Screen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  final DateTime _firstDay = DateTime.now().add(const Duration(days: 1));
  final DateTime _lastDay = DateTime.now().add(const Duration(days: 90));

  final List<String> _timeSlots = [
    '07:00', '08:00', '09:00', '10:00', '11:00',
    '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00',
  ];

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
                  _buildCalendar(isDark),
                  const SizedBox(height: 20),
                  _buildTimeSlots(isDark),
                ],
              ),
            ),
          ),
          _buildNextButton(isDark),
        ],
      ),
    );
  }

  // ── Step Indicator Helpers ──────────────────────────────────

  Widget _buildStepIndicator(bool isDark) {
    final labels = ['Dịch vụ', 'Ngày giờ', 'Địa điểm', 'Xác nhận'];
    const activeStep = 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _stepCircle(1, activeStep, true, isDark),
              Expanded(child: _stepConnector(true, isDark)),
              _stepCircle(2, activeStep, false, isDark),
              Expanded(child: _stepConnector(false, isDark)),
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
              _stepLabel(labels[1], 2 == activeStep, isDark),
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
      title: Text('Chọn ngày & giờ',
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17)),
      centerTitle: true,
    );
  }

  Widget _buildCalendar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inputFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: isDark
                  ? Colors.black26
                  : Colors.grey.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  _monthYearLabel(_selectedDate),
                  style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.chevron_left_rounded,
                      color:
                      isDark ? Colors.white54 : Colors.grey),
                  onPressed: () {
                    final prev = DateTime(
                        _selectedDate.year, _selectedDate.month - 1, 1);
                    if (!prev.isBefore(DateTime(
                        _firstDay.year, _firstDay.month, 1))) {
                      setState(() => _selectedDate = DateTime(
                          prev.year, prev.month, _selectedDate.day));
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right_rounded,
                      color:
                      isDark ? Colors.white54 : Colors.grey),
                  onPressed: () {
                    final next = DateTime(
                        _selectedDate.year, _selectedDate.month + 1, 1);
                    if (!next.isAfter(DateTime(
                        _lastDay.year, _lastDay.month, 1))) {
                      setState(() => _selectedDate = DateTime(
                          next.year, next.month, _selectedDate.day));
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                  .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: TextStyle(
                          color: d == 'CN'
                              ? AppTheme.secondary
                              : (isDark
                              ? Colors.white38
                              : Colors.grey),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: _buildCalendarGrid(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final firstOfMonth =
    DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final startOffset = (firstOfMonth.weekday - 1) % 7;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final day = cellIndex - startOffset + 1;

            if (day < 1 || day > daysInMonth) {
              return const Expanded(child: SizedBox(height: 40));
            }

            final date = DateTime(
                _selectedDate.year, _selectedDate.month, day);
            final isSelected = date.day == _selectedDate.day &&
                date.month == _selectedDate.month &&
                date.year == _selectedDate.year;
            final isPast = date.isBefore(_firstDay);
            final isSunday = date.weekday == 7;

            return Expanded(
              child: GestureDetector(
                onTap: isPast
                    ? null
                    : () => setState(() {
                  _selectedDate = date;
                  _selectedTime = null;
                }),
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isPast
                            ? (isDark
                            ? Colors.white12
                            : Colors.grey[300])
                            : isSunday
                            ? AppTheme.secondary
                            .withOpacity(0.8)
                            : (isDark
                            ? Colors.white
                            : AppTheme.lightTextPrimary),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildTimeSlots(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn khung giờ',
            style: TextStyle(
                color:
                isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: TextStyle(
              color: AppTheme.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, i) {
            final time = _timeSlots[i];
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = time),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.secondary
                      : (isDark ? AppTheme.inputFill : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.secondary
                        : (isDark
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Center(
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark
                          ? Colors.white70
                          : AppTheme.lightTextPrimary),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNextButton(bool isDark) {
    final canProceed = _selectedTime != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: canProceed
              ? () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingStep3Screen(
                selectedPhotographer: widget.selectedPhotographer,
                selectedMakeuper: widget.selectedMakeuper,
                bookingDate: _selectedDate,
                timeSlot: _selectedTime!,
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
                canProceed
                    ? 'Tiếp theo  •  ${_selectedDate.day}/${_selectedDate.month} lúc $_selectedTime'
                    : 'Chọn khung giờ',
                style: TextStyle(
                  color: canProceed
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.grey),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (canProceed) ...[
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

  String _monthYearLabel(DateTime date) {
    const months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}