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
  });

  String get maskedCardNumber {
    if (cardNumber.length >= 4) {
      final last4 = cardNumber.substring(cardNumber.length - 4);
      return '•••• •••• •••• $last4';
    }
    return cardNumber;
  }
}

