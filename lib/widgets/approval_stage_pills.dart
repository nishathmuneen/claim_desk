import 'package:flutter/material.dart';
import '../models/approval_stage.dart';
import '../theme/app_theme.dart';

/// Modern Horizontal Approval Progress Tracker for claim cards and lists.
/// Renders an enterprise horizontal pipeline strictly in corporate Blue, Orange, White, and Gold.
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
    if (title.contains('reporting') || title.contains('line') || title.contains('manager') || title.contains('accountant')) {
      return 'L1 Mgr';
    } else if (title.contains('division') || title.contains('head') || title.contains('div')) {
      return 'L2 Div';
    } else if (title.contains('section') || title.contains('ap') || title.contains('procure') || title.contains('lead')) {
      return 'L3 AP';
    } else if (title.contains('sap') || title.contains('posting') || title.contains('payout') || title.contains('treasury') || title.contains('finance')) {
      return 'L4 SAP';
    }
    return 'L${stage.stageOrder}';
  }

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Stage Labels Row (centered above nodes)
        Row(
          children: [
            for (int i = 0; i < stages.length; i++)
              Expanded(
                child: Tooltip(
                  message: '${stages[i].roleTitle}: ${stages[i].approverName} (${_statusString(stages[i].status)})',
                  child: Text(
                    _getStageShortLabel(stages[i]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11.5 : 12.5,
                      fontWeight: stages[i].isPending
                          ? FontWeight.w900
                          : (stages[i].isApproved ? FontWeight.w800 : FontWeight.w600),
                      color: _getLabelColor(stages[i]),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),

        // 2. Nodes and Continuous Connecting Pipeline Row
        Row(
          children: [
            for (int i = 0; i < stages.length; i++)
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Continuous Connecting Line
                    Row(
                      children: [
                        // Left connecting segment
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: i == 0 ? Colors.transparent : _getLeftLineColor(i),
                          ),
                        ),
                        // Right connecting segment
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: i == stages.length - 1 ? Colors.transparent : _getRightLineColor(i),
                          ),
                        ),
                      ],
                    ),

                    // Centered Circular Node
                    _buildNode(stages[i]),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _statusString(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.pending:
        return 'In Review';
      case ApprovalStatus.rejected:
        return 'Rejected';
      case ApprovalStatus.waiting:
        return 'Pending Upstream';
    }
  }

  Color _getLabelColor(ApprovalWorkflowStage stage) {
    switch (stage.status) {
      case ApprovalStatus.approved:
        return AppTheme.royalBlue;
      case ApprovalStatus.pending:
        return AppTheme.primaryOrange;
      case ApprovalStatus.rejected:
        return AppTheme.dangerRed;
      case ApprovalStatus.waiting:
        return AppTheme.textMuted;
    }
  }

  Color _getLeftLineColor(int index) {
    final prev = stages[index - 1];
    final curr = stages[index];

    if (prev.isApproved && curr.isApproved) {
      return AppTheme.royalBlue;
    } else if (prev.isApproved && curr.isPending) {
      return AppTheme.primaryOrange;
    } else if (prev.isApproved && curr.isRejected) {
      return AppTheme.dangerRed;
    } else if (prev.isRejected) {
      return AppTheme.dangerRed;
    }
    return const Color(0xFFE2E8F0);
  }

  Color _getRightLineColor(int index) {
    final curr = stages[index];
    final next = stages[index + 1];

    if (curr.isApproved && next.isApproved) {
      return AppTheme.royalBlue;
    } else if (curr.isApproved && next.isPending) {
      return AppTheme.primaryOrange;
    } else if (curr.isApproved && next.isRejected) {
      return AppTheme.dangerRed;
    } else if (curr.isRejected) {
      return AppTheme.dangerRed;
    }
    return const Color(0xFFE2E8F0);
  }

  Widget _buildNode(ApprovalWorkflowStage stage) {
    switch (stage.status) {
      case ApprovalStatus.approved:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.royalBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.royalBlue.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, size: 12, color: Colors.white),
          ),
        );

      case ApprovalStatus.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.orangeMuted,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryOrange, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.autorenew_rounded,
              size: 13,
              color: AppTheme.primaryOrange,
            ),
          ),
        );

      case ApprovalStatus.rejected:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.dangerRed, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.dangerRed.withValues(alpha: 0.25),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.close_rounded, size: 12, color: AppTheme.dangerRed),
          ),
        );

      case ApprovalStatus.waiting:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.4),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
    }
  }
}
