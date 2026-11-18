enum ApprovalStatus {
  approved,
  pending,
  waiting,
  rejected,
}

class ApprovalWorkflowStage {
  final int stageOrder;
  final String roleTitle;
  final String approverName;
  final String approverDesignation;
  final ApprovalStatus status;
  final DateTime? timestamp;
  final String? comments;
  final String? badgeLabel;
  final int? remainingSlaHours;
  final String? upstreamDependency;
  final bool canPing;

  const ApprovalWorkflowStage({
    required this.stageOrder,
    required this.roleTitle,
    required this.approverName,
    required this.approverDesignation,
    required this.status,
    this.timestamp,
    this.comments,
    this.badgeLabel,
    this.remainingSlaHours,
    this.upstreamDependency,
    this.canPing = false,
  });

  bool get isApproved => status == ApprovalStatus.approved;
  bool get isPending => status == ApprovalStatus.pending;
  bool get isWaiting => status == ApprovalStatus.waiting;
  bool get isRejected => status == ApprovalStatus.rejected;

  ApprovalWorkflowStage copyWith({
    int? stageOrder,
    String? roleTitle,
    String? approverName,
    String? approverDesignation,
    ApprovalStatus? status,
    DateTime? timestamp,
    String? comments,
    String? badgeLabel,
    int? remainingSlaHours,
    String? upstreamDependency,
    bool? canPing,
  }) {
    return ApprovalWorkflowStage(
      stageOrder: stageOrder ?? this.stageOrder,
      roleTitle: roleTitle ?? this.roleTitle,
      approverName: approverName ?? this.approverName,
      approverDesignation: approverDesignation ?? this.approverDesignation,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      comments: comments ?? this.comments,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      remainingSlaHours: remainingSlaHours ?? this.remainingSlaHours,
      upstreamDependency: upstreamDependency ?? this.upstreamDependency,
      canPing: canPing ?? this.canPing,
    );
  }
}
