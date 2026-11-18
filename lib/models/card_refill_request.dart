enum RefillUrgency {
  normal,
  urgent,
  critical,
}

enum RefillStatus {
  requested,
  managerApproved,
  financeDispatched,
  fundsLoaded,
}

class CardRefillRequest {
  final String refillId;
  final String cardNumber;
  final String custodianId;
  final String custodianName;
  final double currentBalance;
  final double requestedAmount;
  final RefillUrgency urgency;
  final String businessJustification;
  final RefillStatus status;
  final DateTime requestDate;
  final DateTime? completedDate;

  const CardRefillRequest({
    required this.refillId,
    required this.cardNumber,
    required this.custodianId,
    required this.custodianName,
    required this.currentBalance,
    required this.requestedAmount,
    required this.urgency,
    required this.businessJustification,
    required this.status,
    required this.requestDate,
    this.completedDate,
  });

  String get urgencyDisplay {
    switch (urgency) {
      case RefillUrgency.normal:
        return 'Normal';
      case RefillUrgency.urgent:
        return 'Urgent (Within 24h)';
      case RefillUrgency.critical:
        return 'Critical (Site Work Stoppage)';
    }
  }

  String get statusDisplay {
    switch (status) {
      case RefillStatus.requested:
        return 'Under Review (AP Finance)';
      case RefillStatus.managerApproved:
        return 'Manager Endorsed';
      case RefillStatus.financeDispatched:
        return 'Dispatched to Bank';
      case RefillStatus.fundsLoaded:
        return 'Funds Loaded & Active';
    }
  }

  CardRefillRequest copyWith({
    String? refillId,
    String? cardNumber,
    String? custodianId,
    String? custodianName,
    double? currentBalance,
    double? requestedAmount,
    RefillUrgency? urgency,
    String? businessJustification,
    RefillStatus? status,
    DateTime? requestDate,
    DateTime? completedDate,
  }) {
    return CardRefillRequest(
      refillId: refillId ?? this.refillId,
      cardNumber: cardNumber ?? this.cardNumber,
      custodianId: custodianId ?? this.custodianId,
      custodianName: custodianName ?? this.custodianName,
      currentBalance: currentBalance ?? this.currentBalance,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      urgency: urgency ?? this.urgency,
      businessJustification: businessJustification ?? this.businessJustification,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      completedDate: completedDate ?? this.completedDate,
    );
  }
}

