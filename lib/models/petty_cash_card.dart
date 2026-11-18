class PettyCashCard {
  final String cardNumber;
  final String cardholderName;
  final String employeeId;
  final String company;
  final String division;
  final String department;
  final String designation;
  final String costCenter;
  final String iqama;
  final String phone;
  final bool isInactive;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyLimit;
  final double currentBalance;
  final double spentAmount;
  final double minimumThreshold;
  final double singleTransactionCap;
  final String? activeRefillStatus;

  const PettyCashCard({
    required this.cardNumber,
    required this.cardholderName,
    required this.employeeId,
    required this.company,
    required this.division,
    required this.department,
    required this.designation,
    required this.costCenter,
    required this.iqama,
    required this.phone,
    this.isInactive = false,
    required this.startDate,
    required this.endDate,
    required this.monthlyLimit,
    required this.currentBalance,
    required this.spentAmount,
    this.minimumThreshold = 1000.0,
    this.singleTransactionCap = 2000.0,
    this.activeRefillStatus,
  });

  bool get isLowBalance => currentBalance <= minimumThreshold;

  String get maskedCardNumber {
    if (cardNumber.length >= 4) {
      final last4 = cardNumber.substring(cardNumber.length - 4);
      return '•••• •••• •••• $last4';
    }
    return cardNumber;
  }

  PettyCashCard copyWith({
    String? cardNumber,
    String? cardholderName,
    String? employeeId,
    String? company,
    String? division,
    String? department,
    String? designation,
    String? costCenter,
    String? iqama,
    String? phone,
    bool? isInactive,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyLimit,
    double? currentBalance,
    double? spentAmount,
    double? minimumThreshold,
    double? singleTransactionCap,
    String? activeRefillStatus,
  }) {
    return PettyCashCard(
      cardNumber: cardNumber ?? this.cardNumber,
      cardholderName: cardholderName ?? this.cardholderName,
      employeeId: employeeId ?? this.employeeId,
      company: company ?? this.company,
      division: division ?? this.division,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      costCenter: costCenter ?? this.costCenter,
      iqama: iqama ?? this.iqama,
      phone: phone ?? this.phone,
      isInactive: isInactive ?? this.isInactive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      spentAmount: spentAmount ?? this.spentAmount,
      minimumThreshold: minimumThreshold ?? this.minimumThreshold,
      singleTransactionCap: singleTransactionCap ?? this.singleTransactionCap,
      activeRefillStatus: activeRefillStatus ?? this.activeRefillStatus,
    );
  }
}
