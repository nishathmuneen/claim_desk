import 'package:flutter/material.dart';
import 'custom_date_range_sheet.dart';

enum DateFilterPeriod {
  wtd,
  mtd,
  ytd,
  customRange,
}

/// Freestanding Date Period Selector Pills matching Image 2 reference.
class PeriodFilterBar extends StatelessWidget {
  final DateFilterPeriod selectedPeriod;
  final DateTimeRange? customDateRange;
  final Function(DateFilterPeriod period, DateTimeRange? range) onPeriodChanged;

  const PeriodFilterBar({
    super.key,
    required this.selectedPeriod,
    this.customDateRange,
    required this.onPeriodChanged,
  });

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await CustomDateRangeSheet.show(
      context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialRange: customDateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
    );

    if (picked != null) {
      onPeriodChanged(DateFilterPeriod.customRange, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildPill(
          label: 'WTD',
          tooltip: 'Week to Date (Sun - Today)',
          period: DateFilterPeriod.wtd,
          icon: Icons.calendar_today_outlined,
          onTap: () => onPeriodChanged(DateFilterPeriod.wtd, null),
        ),
        const SizedBox(width: 8),
        _buildPill(
          label: 'MTD',
          tooltip: 'Month to Date (1st - Today)',
          period: DateFilterPeriod.mtd,
          icon: Icons.calendar_today_outlined,
          onTap: () => onPeriodChanged(DateFilterPeriod.mtd, null),
        ),
        const SizedBox(width: 8),
        _buildPill(
          label: 'YTD',
          tooltip: 'Year to Date (Jan 1 - Today)',
          period: DateFilterPeriod.ytd,
          icon: Icons.calendar_month_outlined,
          onTap: () => onPeriodChanged(DateFilterPeriod.ytd, null),
        ),
        const SizedBox(width: 8),
        _buildPill(
          label: selectedPeriod == DateFilterPeriod.customRange && customDateRange != null
              ? '${_formatShort(customDateRange!.start)}-${_formatShort(customDateRange!.end)}'
              : 'Custom',
          tooltip: 'Select Custom Date Range',
          period: DateFilterPeriod.customRange,
          icon: Icons.edit_calendar_outlined,
          onTap: () => _pickCustomRange(context),
        ),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required String tooltip,
    required DateFilterPeriod period,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFD97706), // Rich amber gold top
                        Color(0xFFB45309), // Deep amber gold bottom
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFFD),
                        Color(0xFFFEF8EC),
                      ],
                    ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFB45309)
                    : const Color(0xFFFEF08A).withValues(alpha: 0.45),
                width: isSelected ? 1.0 : 0.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFB45309).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatShort(DateTime dt) {
    return '${dt.day}/${dt.month}';
  }
}
