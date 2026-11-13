class OcrScanResult {
  final String merchantName;
  final DateTime invoiceDate;
  final String invoiceNumber;
  final double baseAmount;
  final double vatAmount;
  final double totalAmount;
  final double confidenceScore; // e.g. 0.94
  final bool isHighConfidence;
  final String category;
  final String sampleReceiptImage;

  const OcrScanResult({
    required this.merchantName,
    required this.invoiceDate,
    required this.invoiceNumber,
    required this.baseAmount,
    required this.vatAmount,
    required this.totalAmount,
    required this.confidenceScore,
    required this.isHighConfidence,
    required this.category,
    required this.sampleReceiptImage,
  });
}

