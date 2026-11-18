import 'package:flutter/material.dart';
import '../models/approval_stage.dart';
import '../theme/app_theme.dart';

class ApprovalStagePills extends StatelessWidget {
  final List<ApprovalWorkflowStage> stages;
  final bool compact;

  const ApprovalStagePills({
    super.key,
    required this.stages,
    this.compact = true,
  });

  String _getStageShortLabel(ApprovalWorkflowStage stage) {
    final title = stage.roleTitle.toLowerCase();
    if (title.contains('reporting') || title.contains('line') || title.contains('manager')) {
      return 'L1 Mgr';
    } else if (title.contains('division') || title.contains('head') || title.contains('vat')) {
      return 'L2 Div';
    } else if (title.contains('section') || title.contains('ap') || title.contains('finance')) {
      return 'L3 AP';
    } else if (title.contains('sap') || title.contains('posting') || title.contains('payout') || title.contains('treasury')) {
      return 'L4 SAP';
    }
    return 'L${stage.stageOrder}';
  }

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < stages.length; i++) ...[
            _buildStagePill(stages[i]),
            if (i < stages.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 9,
                  color: AppTheme.border.withValues(alpha: 0.8),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStagePill(ApprovalWorkflowStage stage) {
    Color bg;
    Color border;
    Color textCol;
    IconData icon;

    switch (stage.status) {
      case ApprovalStatus.approved:
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFF6EE7B7);
        textCol = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        break;
      case ApprovalStatus.pending:
        bg = const Color(0xFFFFF7ED);
        border = const Color(0xFFFDBA74);
        textCol = const Color(0xFFC2410C);
        icon = Icons.hourglass_top_rounded;
        break;
      case ApprovalStatus.rejected:
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFCA5A5);
        textCol = const Color(0xFF991B1B);
        icon = Icons.cancel_rounded;
        break;
      case ApprovalStatus.waiting:
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFE2E8F0);
        textCol = const Color(0xFF94A3B8);
        icon = Icons.lock_outline_rounded;
        break;
    }

    final isCurrent = stage.status == ApprovalStatus.pending;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.5 : 9.0,
        vertical: compact ? 2.5 : 4.0,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: border,
          width: isCurrent ? 1.4 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: textCol),
          const SizedBox(width: 4),
          Text(
            _getStageShortLabel(stage),
            style: TextStyle(
              fontSize: compact ? 10.0 : 11.0,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: textCol,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

