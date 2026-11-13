enum ClaimStatus {
  draft,
  submitted,
  partiallyRejected,
  approved,
  fullyClosed,
}

enum LineStatus {
  pending,
  approved,
  rejected,
}

class ExpenseLineItem {
  final String id;
  final DateTime date;
  final String category;
  final String invoiceNumber;
  final double baseAmount;
  final double vatRatePercentage; // e.g. 15.0
  final double vatAmount;
  final double totalAmount;
  final String? attachmentName;
  final String? attachmentPath;
  final LineStatus status;
  final String? rejectionComment; // Mandatory if rejected
  final bool isResubmitted;

  const ExpenseLineItem({
    required this.id,
    required this.date,
    required this.category,
    required this.invoiceNumber,
    required this.baseAmount,
    required this.vatRatePercentage,
    required this.vatAmount,
    required this.totalAmount,
    this.attachmentName,
    this.attachmentPath,
    this.status = LineStatus.pending,
    this.rejectionComment,
    this.isResubmitted = false,
  });

  ExpenseLineItem copyWith({
    String? id,
    DateTime? date,
    String? category,
    String? invoiceNumber,
    double? baseAmount,
    double? vatRatePercentage,
    double? vatAmount,
    double? totalAmount,
    String? attachmentName,
    String? attachmentPath,
    LineStatus? status,
    String? rejectionComment,
    bool? isResubmitted,
  }) {
    return ExpenseLineItem(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      baseAmount: baseAmount ?? this.baseAmount,
      vatRatePercentage: vatRatePercentage ?? this.vatRatePercentage,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      status: status ?? this.status,
      rejectionComment: rejectionComment ?? this.rejectionComment,
      isResubmitted: isResubmitted ?? this.isResubmitted,
    );
  }
}

class ExpenseClaim {
  final String id;
  final String docRefNumber;
  final String docType;
  final DateTime claimDate;
  final String description;
  final String employeeId;
  final String employeeName;
  final String costCenter;
  final String cardNumber;
  final double vatRatePercentage;
  final ClaimStatus status;
  final List<ExpenseLineItem> lines;
  final String? paymentStatus;
  final String? paymentNumber;
  final String? sapDocRefNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? originalRefNumber;
  final List<String> auditTrail;

  const ExpenseClaim({
    required this.id,
    required this.docRefNumber,
    required this.docType,
    required this.claimDate,
    required this.description,
    required this.employeeId,
    required this.employeeName,
    required this.costCenter,
    required this.cardNumber,
    required this.vatRatePercentage,
    required this.status,
    required this.lines,
    this.paymentStatus,
    this.paymentNumber,
    this.sapDocRefNumber,
    required this.createdAt,
    required this.updatedAt,
    this.originalRefNumber,
    required this.auditTrail,
  });

  double get totalBaseAmount =>
      lines.fold(0.0, (sum, item) => sum + item.baseAmount);

  double get totalVatAmount =>
      lines.fold(0.0, (sum, item) => sum + item.vatAmount);

  double get grandTotal =>
      lines.fold(0.0, (sum, item) => sum + item.totalAmount);

  bool get hasRejectedLines =>
      lines.any((l) => l.status == LineStatus.rejected);

  List<ExpenseLineItem> get rejectedLines =>
      lines.where((l) => l.status == LineStatus.rejected).toList();

  ExpenseClaim copyWith({
    String? id,
    String? docRefNumber,
    String? docType,
    DateTime? claimDate,
    String? description,
    String? employeeId,
    String? employeeName,
    String? costCenter,
    String? cardNumber,
    double? vatRatePercentage,
    ClaimStatus? status,
    List<ExpenseLineItem>? lines,
    String? paymentStatus,
    String? paymentNumber,
    String? sapDocRefNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? originalRefNumber,
    List<String>? auditTrail,
  }) {
    return ExpenseClaim(
      id: id ?? this.id,
      docRefNumber: docRefNumber ?? this.docRefNumber,
      docType: docType ?? this.docType,
      claimDate: claimDate ?? this.claimDate,
      description: description ?? this.description,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      costCenter: costCenter ?? this.costCenter,
      cardNumber: cardNumber ?? this.cardNumber,
      vatRatePercentage: vatRatePercentage ?? this.vatRatePercentage,
      status: status ?? this.status,
      lines: lines ?? this.lines,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      sapDocRefNumber: sapDocRefNumber ?? this.sapDocRefNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      originalRefNumber: originalRefNumber ?? this.originalRefNumber,
      auditTrail: auditTrail ?? this.auditTrail,
    );
  }
}

