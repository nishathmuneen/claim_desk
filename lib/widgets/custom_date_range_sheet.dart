import 'package:flutter/material.dart';

/// Luxury Enterprise Date Range Picker Modal Bottom Sheet
/// Matches the reference design with deep navy header, light gold gradient card,
/// narrow navy borders, soft amber range highlight ribbon, and solid orange circular endpoints.
class CustomDateRangeSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDateRangeSheet({
    super.key,
    this.initialRange,
    this.firstDate,
    this.lastDate,
  });

  /// Static helper to display the sheet modally
  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initialRange,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomDateRangeSheet(
        initialRange: initialRange,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  State<CustomDateRangeSheet> createState() => _CustomDateRangeSheetState();
}

class _CustomDateRangeSheetState extends State<CustomDateRangeSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _startDate = DateTime(
        widget.initialRange!.start.year,
        widget.initialRange!.start.month,
        widget.initialRange!.start.day,
      );
      _endDate = DateTime(
        widget.initialRange!.end.year,
        widget.initialRange!.end.month,
        widget.initialRange!.end.day,
      );
      _displayedMonth = DateTime(_startDate!.year, _startDate!.month, 1);
    } else {
      final now = DateTime.now();
      _displayedMonth = DateTime(now.year, now.month, 1);
    }
  }

  void _onDayTapped(DateTime day) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start a fresh range
        _startDate = day;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (day.isBefore(_startDate!)) {
          // If clicked before current start date, reset start date
          _startDate = day;
        } else {
          // Set end date
          _endDate = day;
        }
      }
    });
  }

  void _navigateMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + offset, 1);
    });
  }

  String _formatRangeSummary() {
    if (_startDate == null) {
      return 'Select Start Date';
    }
    if (_endDate == null) {
      return '${_formatMonthDay(_startDate!)} – Select End Date';
    }
    return '${_formatMonthDay(_startDate!)} – ${_formatMonthDay(_endDate!)}';
  }

  String _formatMonthDay(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatMonthYear(DateTime dt) {
    const fullMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${fullMonths[dt.month - 1]} ${dt.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDayInRange(DateTime day) {
    if (_startDate == null || _endDate == null) return false;
    return (day.isAfter(_startDate!) || _isSameDay(day, _startDate!)) &&
        (day.isBefore(_endDate!) || _isSameDay(day, _endDate!));
  }

  @override
  Widget build(BuildContext context) {
    final nextMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Navy Top Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // Deep Navy
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Select Range',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30), // Balance close icon
              ],
            ),
          ),

          // 2. Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Date Range Summary Pill Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFFFD),
                          Color(0xFFFEF8EC),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFEF08A).withValues(alpha: 0.45),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date Range',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatRangeSummary(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFFB45309),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Calendar Card Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFFFD),
                          Color(0xFFFEF8EC),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFEF08A).withValues(alpha: 0.45),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First Month Header & Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Color(0xFF0F172A)),
                              tooltip: 'Previous Month',
                              onPressed: () => _navigateMonth(-1),
                            ),
                            Text(
                              _formatMonthYear(_displayedMonth),
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Color(0xFF0F172A)),
                              tooltip: 'Next Month',
                              onPressed: () => _navigateMonth(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildWeekdayHeader(),
                        const SizedBox(height: 8),
                        _buildMonthGrid(_displayedMonth),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Color(0xFFE2E8F0), height: 1),
                        ),

                        // Second Month Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatMonthYear(nextMonth),
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildWeekdayHeader(),
                        const SizedBox(height: 8),
                        _buildMonthGrid(nextMonth),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Action Buttons Footer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFFFFD),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Apply Button
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFD97706), // Rich amber gold
                            Color(0xFFB45309), // Deep amber gold
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFB45309),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB45309).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (_startDate != null) {
                              final end = _endDate ?? _startDate!;
                              Navigator.of(context).pop(
                                DateTimeRange(
                                  start: _startDate!,
                                  end: DateTime(end.year, end.month, end.day, 23, 59, 59),
                                ),
                              );
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Center(
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: weekdays
            .map(
              (day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Sunday is 0 in our column layout (DateTime.sunday % 7 == 0)
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final totalCells = ((startingWeekday + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 3,
        crossAxisSpacing: 0,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        if (index < startingWeekday || index >= startingWeekday + daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - startingWeekday + 1;
        final currentDay = DateTime(month.year, month.month, dayNumber);
        final isStart = _startDate != null && _isSameDay(currentDay, _startDate!);
        final isEnd = _endDate != null && _isSameDay(currentDay, _endDate!);
        final inRange = _isDayInRange(currentDay);
        final isSingleSelected = isStart && (_endDate == null || _isSameDay(_startDate!, _endDate!));

        // Column position: 0 = Sun, 6 = Sat
        final colIndex = index % 7;
        final isFirstCol = colIndex == 0 || dayNumber == 1;
        final isLastCol = colIndex == 6 || dayNumber == daysInMonth;

        return GestureDetector(
          onTap: () => _onDayTapped(currentDay),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Soft Gold Ribbon Highlight Strip behind range dates
              if (inRange && !isSingleSelected)
                Positioned.fill(
                  child: Row(
                    children: [
                      // Left half of cell
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: (isStart)
                                ? Colors.transparent
                                : const Color(0xFFFEF3C7),
                            borderRadius: isFirstCol && !isStart
                                ? const BorderRadius.horizontal(left: Radius.circular(16))
                                : BorderRadius.zero,
                          ),
                        ),
                      ),
                      // Right half of cell
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: (isEnd)
                                ? Colors.transparent
                                : const Color(0xFFFEF3C7),
                            borderRadius: isLastCol && !isEnd
                                ? const BorderRadius.horizontal(right: Radius.circular(16))
                                : BorderRadius.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. Solid Orange Circle for Endpoints OR Normal Number
              if (isStart || isEnd)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFEA580C), // Amber Orange top
                        Color(0xFFD97706), // Rich Amber bottom
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33D97706),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: inRange ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF0F172A), // Dark Navy
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

