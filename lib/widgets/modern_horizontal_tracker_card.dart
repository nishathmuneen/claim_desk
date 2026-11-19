import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Data model representing a milestone stage in the horizontal tracker.
class TrackerStageItem {
  final String label;
  final String? subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isPending;
  final bool isRejected;

  const TrackerStageItem({
    required this.label,
    this.subtitle,
    this.isCompleted = false,
    this.isActive = false,
    this.isPending = false,
    this.isRejected = false,
  });
}

/// A high-precision, modern horizontal tracker card inspired by modern logistics/dispatch
/// tracking designs, styled strictly in Corporate Blue, Signature Orange, Pure White, and Saudi Gold.
class ModernHorizontalTrackerCard extends StatelessWidget {
  final String id;
  final String? statusLabel;
  final Color? statusColor;
  final Widget? statusBadge;
  final String startDate;
  final String startLocation;
  final String endDate;
  final String endLocation;
  final List<TrackerStageItem> stages;
  final Widget? itemThumbnail;
  final String itemTitle;
  final String itemSubtitle;
  final String itemPriceOrValue;
  final Color? itemBadgeColor;
  final Color? itemBadgeTextColor;
  final VoidCallback? onTap;

  const ModernHorizontalTrackerCard({
    super.key,
    required this.id,
    this.statusLabel,
    this.statusColor,
    this.statusBadge,
    required this.startDate,
    required this.startLocation,
    required this.endDate,
    required this.endLocation,
    required this.stages,
    this.itemThumbnail,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.itemPriceOrValue,
    this.itemBadgeColor,
    this.itemBadgeTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: ID & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ID: ',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        id.startsWith('ID:') ? id.substring(3).trim() : id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.royalBlue,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (statusBadge != null)
                statusBadge!
              else if (statusLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: (statusColor ?? AppTheme.goldPrimary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (statusColor ?? AppTheme.goldPrimary).withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    statusLabel!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor ?? AppTheme.goldDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Start & Destination Milestones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Origin / Start
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startDate,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      startLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Target / Delivery
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      endDate,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      endLocation,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Horizontal Stepper with perfectly aligned nodes
          _buildHorizontalStepper(context),
          const SizedBox(height: 20),

          // 4. Embedded Bottom Card Item
          _buildEmbeddedItemCard(context),
        ],
      ),
    );
  }

  Widget _buildHorizontalStepper(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Stage Labels Row (directly above nodes)
        Row(
          children: [
            for (int i = 0; i < stages.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Text(
                    stages[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: stages[i].isActive
                          ? FontWeight.w900
                          : (stages[i].isCompleted ? FontWeight.w800 : FontWeight.w600),
                      color: stages[i].isCompleted
                          ? AppTheme.royalBlue
                          : (stages[i].isActive ? AppTheme.primaryOrange : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Node & Continuous Line Row
        Row(
          children: [
            for (int i = 0; i < stages.length; i++)
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Continuous Connecting Lines
                    Row(
                      children: [
                        // Left connecting segment
                        Expanded(
                          child: Container(
                            height: 2.8,
                            color: i == 0
                                ? Colors.transparent
                                : (stages[i - 1].isCompleted
                                    ? (stages[i].isCompleted
                                        ? AppTheme.royalBlue
                                        : AppTheme.primaryOrange)
                                    : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        // Right connecting segment
                        Expanded(
                          child: Container(
                            height: 2.8,
                            color: i == stages.length - 1
                                ? Colors.transparent
                                : (stages[i].isCompleted
                                    ? (stages[i + 1].isCompleted
                                        ? AppTheme.royalBlue
                                        : AppTheme.primaryOrange)
                                    : const Color(0xFFE2E8F0)),
                          ),
                        ),
                      ],
                    ),

                    // Centered Node Circle
                    _buildNode(stages[i]),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNode(TrackerStageItem stage) {
    if (stage.isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppTheme.royalBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.royalBlue.withValues(alpha: 0.32),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
        ),
      );
    }

    if (stage.isActive) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppTheme.orangeMuted,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryOrange, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryOrange.withValues(alpha: 0.38),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.autorenew_rounded,
            size: 15,
            color: AppTheme.primaryOrange,
          ),
        ),
      );
    }

    // Upcoming / Inactive
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.6),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEmbeddedItemCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Left thumbnail / badge
          if (itemThumbnail != null)
            itemThumbnail!
          else
            _buildDefaultCardThumbnail(),
          const SizedBox(width: 12),

          // Center: Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  itemSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right: Highlighted Price / Limit Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
            decoration: BoxDecoration(
              color: itemBadgeColor ?? const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (itemBadgeTextColor ?? AppTheme.royalBlue).withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Text(
              itemPriceOrValue,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w900,
                color: itemBadgeTextColor ?? AppTheme.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDefaultCardThumbnail() {
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2B45), Color(0xFF0D1322)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.goldMetallic, width: 0.8),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.goldMetallic,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          const Positioned(
            bottom: 3,
            right: 5,
            child: Text(
              'VISA',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
