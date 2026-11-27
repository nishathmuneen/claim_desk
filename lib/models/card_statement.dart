enum StatementTxType {
  posSwipe,
  online,
  atmWithdrawal,
  deposit,
}

class CardStatementTransaction {
  final String id;
  final String cardNumber;
  final String companyCode;
  final DateTime date;
  final String merchantOrAtm;
  final String description;
  final double amount;
  final StatementTxType type;
  final String? linkedClaimLineId;
  final String employeeId;
  final bool isSubmitted;

  const CardStatementTransaction({
    required this.id,
    required this.cardNumber,
    this.companyCode = 'COMP-1000',
    required this.date,
    required this.merchantOrAtm,
    required this.description,
    required this.amount,
    required this.type,
    this.linkedClaimLineId,
    required this.employeeId,
    this.isSubmitted = false,
  });

  CardStatementTransaction copyWith({
    String? id,
    String? cardNumber,
    String? companyCode,
    DateTime? date,
    String? merchantOrAtm,
    String? description,
    double? amount,
    StatementTxType? type,
    String? linkedClaimLineId,
    String? employeeId,
    bool? isSubmitted,
  }) {
    return CardStatementTransaction(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      companyCode: companyCode ?? this.companyCode,
      date: date ?? this.date,
      merchantOrAtm: merchantOrAtm ?? this.merchantOrAtm,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      linkedClaimLineId: linkedClaimLineId ?? this.linkedClaimLineId,
      employeeId: employeeId ?? this.employeeId,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}

class CashAdvanceEntry {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final bool isWithdrawal; // true = ATM withdrawal (+), false = reconciled expense (-)

  const CashAdvanceEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.isWithdrawal,
  });
}

class CashAdvanceLedger {
  final String id;
  final String employeeId;
  final String employeeName;
  final String parentCardNumber;
  final double totalWithdrawn;
  final double totalDeducted;
  final List<CashAdvanceEntry> entries;

  const CashAdvanceLedger({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.parentCardNumber,
    required this.totalWithdrawn,
    required this.totalDeducted,
    this.entries = const [],
  });

  double get remainingBalance => (totalWithdrawn - totalDeducted).clamp(0.0, double.infinity);

  CashAdvanceLedger copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? parentCardNumber,
    double? totalWithdrawn,
    double? totalDeducted,
    List<CashAdvanceEntry>? entries,
  }) {
    return CashAdvanceLedger(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      parentCardNumber: parentCardNumber ?? this.parentCardNumber,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      totalDeducted: totalDeducted ?? this.totalDeducted,
      entries: entries ?? this.entries,
    );
  }
}

class SubCustodian {
  final String id;
  final String name;
  final String employeeId;
  final String parentCardNumber;
  final String costCenter;

  const SubCustodian({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.parentCardNumber,
    required this.costCenter,
  });
}

