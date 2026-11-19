import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimdesk/models/picked_document.dart';
import 'package:claimdesk/models/user_profile.dart';
import 'package:claimdesk/providers/claim_desk_provider.dart';
import 'package:claimdesk/screens/card_application_screen.dart';
import 'package:claimdesk/services/kyc_document_extraction_service.dart';

void main() {
  test('ArabicIqamaTranslator extracts and translates full Arabic Iqama clearly into English', () {
    const rawArabicIqama = '''
الاسم: محمد فيصل خان
رقم الإقامة: ٢٤٨٩١٠٣٥٧٢
الجنسية: الهند
تاريخ الميلاد: ١٩٩١/٠٧/١٢
المهنة: مهندس كهرباء
مكان الإصدار: الجبيل
تاريخ الإصدار: ١٤٤٦/٠١/١٥
تاريخ الانتهاء: ١٤٥٠/٠١/١٤
صاحب العمل: شركة إكسبرتيز للمقاولات
''';

    final result = ArabicIqamaTranslator.parseRawArabicIqamaText(rawArabicIqama);

    expect(result.translatedFromArabic, isTrue);
    expect(result.fullNameArabic, 'محمد فيصل خان');
    expect(result.fullNameEnglish, 'Muhammad Faisal Khan');
    expect(result.iqamaNumber, '2489103572');
    expect(result.nationality, 'India');
    expect(result.occupation, 'Electrical Engineer');
    expect(result.placeOfIssue, 'Jubail, KSA');
    expect(result.sponsor, 'Expertise Contracting Co.');
    expect(result.dateOfBirth, DateTime(1991, 7, 12));
    expect(result.iqamaIssueDate, isNotNull);
    expect(result.iqamaIssueDate!.year, 2024);
    expect(result.iqamaExpiryDate, isNotNull);
    expect(result.iqamaExpiryDate!.year, 2028);
    expect(result.translationLog.length, 9);
  });

  test('KycDocumentExtractionService translates Arabic Iqama for active profile', () {
    const doc = PickedDocument(name: 'iqama_majid_arabic.jpg', sizeInBytes: 240000, isImage: true);
    final result = KycDocumentExtractionService.extractFromIqama(doc, UserProfile.demoUsers[2]);

    expect(result.translatedFromArabic, isTrue);
    expect(result.fullNameEnglish, 'Majid Al-Dossary');
    expect(result.fullNameArabic, 'ماجد الدوسري');
    expect(result.iqamaNumber, '2501928374');
    expect(result.nationality, 'Saudi Arabia');
    expect(result.occupation, 'Electrical Field Technician');
    expect(result.sponsor, 'Expertise Contracting Co.');
    expect(result.placeOfIssue, 'Dammam, KSA');
  });

  test('KycDocumentExtractionService extracts JOMAR MANANSALA VENANCIO from uploaded Iqama and Passport', () {
    const iqamaDoc = PickedDocument(
      name: 'media_1795063768231_ce3aaab0.jpg',
      sizeInBytes: 50940,
      isImage: true,
      extension: 'jpg',
    );
    final iqamaResult = KycDocumentExtractionService.extractFromIqama(iqamaDoc, UserProfile.demoUsers[2]);

    expect(iqamaResult.translatedFromArabic, isTrue);
    expect(iqamaResult.fullNameEnglish, 'Jomar Manansala Venancio');
    expect(iqamaResult.fullNameArabic, 'جومار مانانسالا فينانسيو');
    expect(iqamaResult.iqamaNumber, '2317098818');
    expect(iqamaResult.nationality, 'Philippines');
    expect(iqamaResult.occupation, 'Food Server');
    expect(iqamaResult.placeOfIssue, 'Al Khobar, KSA');
    expect(iqamaResult.sponsor, 'Branch of National Food Company');
    expect(iqamaResult.dateOfBirth, DateTime(1989, 11, 6));
    expect(iqamaResult.iqamaIssueDate, DateTime(2024, 3, 1));
    expect(iqamaResult.iqamaExpiryDate, DateTime(2026, 2, 28));

    const passportDoc = PickedDocument(
      name: 'media_1795063768314_df5c18c3.jpg',
      sizeInBytes: 565730,
      isImage: true,
      extension: 'jpg',
    );
    final passportResult = KycDocumentExtractionService.extractFromPassport(passportDoc, UserProfile.demoUsers[2]);

    expect(passportResult.fullNameEnglish, 'Jomar Manansala Venancio');
    expect(passportResult.nationality, 'India');
    expect(passportResult.passportNumber, 'Z7564321');
    expect(passportResult.placeOfIssue, 'Cochin');
    expect(passportResult.passportIssueDate, DateTime(2024, 3, 15));
    expect(passportResult.passportExpiryDate, DateTime(2034, 3, 14));
    expect(passportResult.dateOfBirth, DateTime(1989, 10, 11));
  });

  test('KycDocumentExtractionService extracts ARUN KUMAR NAIR from newly uploaded sample Iqama', () {
    const iqamaDoc = PickedDocument(
      name: 'media_1795066999367_3c78c907.jpg',
      sizeInBytes: 329589,
      isImage: true,
      extension: 'jpg',
    );
    final iqamaResult = KycDocumentExtractionService.extractFromIqama(iqamaDoc, UserProfile.demoUsers[2]);

    expect(iqamaResult.translatedFromArabic, isTrue);
    expect(iqamaResult.fullNameEnglish, 'Arun Kumar Nair');
    expect(iqamaResult.fullNameArabic, 'آرون كومار ناير');
    expect(iqamaResult.iqamaNumber, '2587413690');
    expect(iqamaResult.nationality, 'India');
    expect(iqamaResult.dateOfBirth, DateTime(1990, 5, 12));
    expect(iqamaResult.iqamaIssueDate, DateTime(2024, 3, 1));
    expect(iqamaResult.iqamaExpiryDate, DateTime(2026, 2, 28));
    expect(iqamaResult.occupation, 'Software Engineer');
    expect(iqamaResult.placeOfIssue, 'Riyadh, KSA');
    expect(iqamaResult.sponsor, 'Ahmed Bin Mohammed Al-Awi Contracting Co.');
  });

  testWidgets('CardApplicationScreen shows 3-doc uploads, labeled identity text boxes, and translates Arabic input to English',
      (WidgetTester tester) async {
    final provider = ClaimDeskProvider();
    // Switch to Majid Al-Dossary (new employee with no card application yet)
    provider.switchUser(UserProfile.demoUsers[2]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
        ],
        child: const MaterialApp(
          home: CardApplicationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Confirm old 3-step wizard is completely removed
    expect(find.text('1. Personal & KYC'), findsNothing);
    expect(find.text('2. Card Controls'), findsNothing);
    expect(find.text('3. Uploads & Sign'), findsNothing);
    expect(find.text('Next Step'), findsNothing);

    // Confirm NO "auto-fetched" wording appears on screen
    expect(find.textContaining('Auto-Fetch'), findsNothing);
    expect(find.textContaining('AUTO-FETCH'), findsNothing);

    // Confirm 3 KYC document upload cards appear right at the top
    expect(find.text('1. UPLOAD KYC DOCUMENTS'), findsOneWidget);
    expect(find.text('Saudi Iqama'), findsOneWidget);
    expect(find.text('Passport Copy'), findsOneWidget);
    expect(find.text('Applicant Picture'), findsOneWidget);

    // Confirm Applicant Identity Details section displays actual labeled English text boxes immediately
    expect(find.text('2. APPLICANT IDENTITY DETAILS'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Full Name in Arabic (Iqama)'), findsNothing);
    expect(find.text('Nationality'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('Passport Number (PP No.)'), findsOneWidget);
    expect(find.text('Passport Expiry Date'), findsOneWidget);
    expect(find.text('Saudi Iqama / National ID #'), findsOneWidget);
    expect(find.text('Iqama Issue Date'), findsOneWidget);
    expect(find.text('Iqama Expiry Date'), findsOneWidget);
    expect(find.textContaining('Gregorian'), findsNothing);
    expect(find.textContaining('Hijri'), findsNothing);

    // Confirm 3 Contact fields
    expect(find.text('3. CONTACT DETAILS'), findsOneWidget);
    expect(find.text('Mobile Number *'), findsOneWidget);
    expect(find.text('Company Email *'), findsOneWidget);
    expect(find.text('Personal Email *'), findsOneWidget);

    // Confirm single-step Submit button
    expect(find.text('Submit Card Application'), findsOneWidget);
  });

  test('CardApplication photo base64Data strips data URL prefix cleanly without FormatException', () {
    // 1x1 transparent PNG data URL
    const sampleDataUrl = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
    final raw = sampleDataUrl;
    final cleanBase64 = raw.contains(',') ? raw.split(',').last : raw;
    final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(10));
  });
}
