import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum DateFilterPeriod {
  wtd,
  mtd,
  ytd,
  customRange,
}

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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onPeriodChanged(DateFilterPeriod.customRange, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _buildPill(
            label: 'WTD',
            tooltip: 'Week to Date (Sun - Today)',
            period: DateFilterPeriod.wtd,
            onTap: () => onPeriodChanged(DateFilterPeriod.wtd, null),
          ),
          _buildPill(
            label: 'MTD',
            tooltip: 'Month to Date (1st - Today)',
            period: DateFilterPeriod.mtd,
            onTap: () => onPeriodChanged(DateFilterPeriod.mtd, null),
          ),
          _buildPill(
            label: 'YTD',
            tooltip: 'Year to Date (Jan 1 - Today)',
            period: DateFilterPeriod.ytd,
            onTap: () => onPeriodChanged(DateFilterPeriod.ytd, null),
          ),
          _buildPill(
            label: selectedPeriod == DateFilterPeriod.customRange && customDateRange != null
                ? '${_formatShort(customDateRange!.start)} - ${_formatShort(customDateRange!.end)}'
                : 'Custom',
            tooltip: 'Select Custom Date Range',
            period: DateFilterPeriod.customRange,
            icon: Icons.date_range,
            onTap: () => _pickCustomRange(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required String tooltip,
    required DateFilterPeriod period,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 13,
                    color: isSelected ? AppTheme.primaryOrange : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppTheme.primaryOrange : AppTheme.textSecondary,
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

