import 'package:flutter/material.dart';

/// Cryptographically sealed attachment for corporate compliance and ZATCA audits.
class VerifiedAttachment {
  final String id;
  final String fileName;
  final String fileType; // e.g. "Tax Invoice", "POS Terminal Slip", "Attendance Roster"
  final String badgeText; // "ZATCA OK", "AUTH 8492", "SEALED"
  final Color badgeColor;
  final String summary; // e.g. "ZATCA QR Scanned • 1.4 MB • Cryptographic Match"
  final String size;

  const VerifiedAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.badgeText,
    this.badgeColor = const Color(0xFF059669),
    required this.summary,
    required this.size,
  });
}

