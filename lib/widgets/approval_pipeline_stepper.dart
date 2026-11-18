import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/approval_stage.dart';

class ApprovalPipelineStepper extends StatelessWidget {
  final List<ApprovalWorkflowStage> stages;

  const ApprovalPipelineStepper({
    super.key,
    required this.stages,
  });

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 16, color: AppTheme.primaryOrange),
            SizedBox(width: 8),
            Text(
              'APPROVAL PIPELINE (MULTI-LEVEL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < stages.length; i++)
          _buildStageRow(stages[i], isLast: i == stages.length - 1),
      ],
    );
  }

  Widget _buildStageRow(ApprovalWorkflowStage stage, {required bool isLast}) {
    Color nodeColor;
    Color nodeBg;
    IconData nodeIcon;
    String badgeText;

    switch (stage.status) {
      case ApprovalStatus.approved:
        nodeColor = AppTheme.successGreen;
        nodeBg = AppTheme.successLight;
        nodeIcon = Icons.check;
        badgeText = 'Approved';
        break;
      case ApprovalStatus.pending:
        nodeColor = AppTheme.dangerRed;
        nodeBg = AppTheme.dangerLight;
        nodeIcon = Icons.hourglass_top;
        badgeText = 'Pending Review';
        break;
      case ApprovalStatus.waiting:
        nodeColor = AppTheme.textMuted;
        nodeBg = const Color(0xFFF1F5F9);
        nodeIcon = Icons.lock_outline;
        badgeText = 'Waiting';
        break;
      case ApprovalStatus.rejected:
        nodeColor = AppTheme.dangerRed;
        nodeBg = AppTheme.dangerLight;
        nodeIcon = Icons.close;
        badgeText = 'Rejected';
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (Node + Connecting Line)
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: nodeBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                child: Icon(nodeIcon, size: 14, color: nodeColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: stage.isApproved
                        ? AppTheme.successGreen.withValues(alpha: 0.5)
                        : AppTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Stage Details Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0.0 : 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: stage.isPending
                        ? AppTheme.dangerRed.withValues(alpha: 0.35)
                        : (stage.isApproved
                            ? AppTheme.successGreen.withValues(alpha: 0.25)
                            : AppTheme.border),
                    width: stage.isPending ? 1.4 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stage.roleTitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: stage.isPending
                                ? AppTheme.dangerRed
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: nodeBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: nodeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: nodeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${stage.approverName} • ${stage.approverDesignation}',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                    if (stage.timestamp != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Completed: ${_formatDateTime(stage.timestamp!)}',
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                      ),
                    ],
                    if (stage.comments != null && stage.comments!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          'Note: "${stage.comments}"',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: stage.isRejected ? AppTheme.dangerRed : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

