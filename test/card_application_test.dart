import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimdesk/models/card_application.dart';
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
    final majid = UserProfile.demoUsers.firstWhere((u) => u.name == 'Majid Al-Dossary');
    const doc = PickedDocument(name: 'iqama_majid_arabic.jpg', sizeInBytes: 240000, isImage: true);
    final result = KycDocumentExtractionService.extractFromIqama(doc, majid);

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
    final majid = UserProfile.demoUsers.firstWhere((u) => u.name == 'Majid Al-Dossary');
    const iqamaDoc = PickedDocument(
      name: 'media_1795063768231_ce3aaab0.jpg',
      sizeInBytes: 50940,
      isImage: true,
      extension: 'jpg',
    );
    final iqamaResult = KycDocumentExtractionService.extractFromIqama(iqamaDoc, majid);

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
    final passportResult = KycDocumentExtractionService.extractFromPassport(passportDoc, majid);

    expect(passportResult.fullNameEnglish, 'Jomar Manansala Venancio');
    expect(passportResult.nationality, 'India');
    expect(passportResult.passportNumber, 'Z7564321');
    expect(passportResult.placeOfIssue, 'Cochin');
    expect(passportResult.passportIssueDate, DateTime(2024, 3, 15));
    expect(passportResult.passportExpiryDate, DateTime(2034, 3, 14));
    expect(passportResult.dateOfBirth, DateTime(1989, 10, 11));
  });

  test('KycDocumentExtractionService extracts ARUN KUMAR NAIR from newly uploaded sample Iqama', () {
    final majid = UserProfile.demoUsers.firstWhere((u) => u.name == 'Majid Al-Dossary');
    const iqamaDoc = PickedDocument(
      name: 'media_1795066999367_3c78c907.jpg',
      sizeInBytes: 329589,
      isImage: true,
      extension: 'jpg',
    );
    final iqamaResult = KycDocumentExtractionService.extractFromIqama(iqamaDoc, majid);

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
    final majid = UserProfile.demoUsers.firstWhere((u) => u.name == 'Majid Al-Dossary');
    // Switch to Majid Al-Dossary (new employee with no card application yet)
    provider.switchUser(majid);

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

  test('New User starts with no active application, submits to Card Awaited, and can delete and reset', () {
    final provider = ClaimDeskProvider();
    final majid = UserProfile.demoUsers.firstWhere((u) => u.name == 'Majid Al-Dossary');
    provider.switchUser(majid);

    // 1. Initially New User (no application)
    expect(provider.activeCardApplication, isNull);
    expect(provider.hasCardApplication(majid.id), isFalse);

    // 2. Submit application
    final app = CardApplication(
      id: 'APP-2026-100',
      fullNameEnglish: 'Majid Al-Dossary',
      fullNameArabic: 'ماجد الدوسري',
      nationality: 'Saudi Arabia',
      dateOfBirth: DateTime(1992, 5, 14),
      iqamaNumber: '2501928374',
      iqamaExpiryDateGregorian: DateTime(2028, 8, 20),
      iqamaExpiryDateHijri: '1450/02/29',
      passportNumber: 'N8492014',
      passportIssueDate: DateTime(2022, 1, 10),
      passportExpiryDate: DateTime(2032, 1, 9),
      mobileNumberPersonal: '+966 56 332 1144',
      mobileNumberOfficial: '+966 56 000 0000',
      emailOfficial: 'm.dossary@expertise.sa',
      shortAddressCode: 'JAZ4109',
      buildingNumber: '4012',
      streetName: 'Corniche Rd',
      district: 'Al-Shati',
      city: 'Jazan',
      postalCode: '45142',
      employeeId: majid.employeeId,
      designation: majid.designation,
      employeeGrade: 'Band-B',
      company: majid.company,
      division: majid.division,
      department: majid.department,
      costCenter: majid.costCenter,
      reportingManagerName: 'Rajesh M. Shetty',
      reportingManagerId: 'EMP-1002',
      projectWbsCode: 'PRJ-2026-JAZAN',
      operatingSiteLocation: majid.division,
      cardFormat: CardFormat.physicalPlastic,
      embossedName: 'MAJID AL-DOSSARY',
      monthlyLimit: 5000.0,
      singleTransactionCap: 2000.0,
      dailySpendingCap: 3000.0,
      authorizedCategories: const ['Fuel & Fleet'],
      deliveryPreference: 'Site Courier',
      personalIban: 'SA0380000000608010167519',
      bankName: 'Al Rajhi Bank',
      emergencyContactName: '',
      emergencyContactMobile: '',
      emergencyRelation: '',
      termsAccepted: true,
      submissionTimestamp: DateTime.now(),
      status: ApplicationStatus.submitted,
    );

    provider.submitCardApplication(app);

    // 3. User is now Card Awaited
    expect(provider.activeCardApplication, isNotNull);
    expect(provider.hasCardApplication(majid.id), isTrue);
    expect(provider.activeCardApplication!.statusDisplay, 'Submitted & SAMA KYC Pending');

    // 4. Delete application: resets user back to New User
    provider.deleteCardApplication();
    expect(provider.activeCardApplication, isNull);
    expect(provider.hasCardApplication(majid.id), isFalse);
  });

  testWidgets('CardApplicationScreen shows existing tracker with Delete KYC button, and deleting resets to upload form',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = ClaimDeskProvider();
    final majid = UserProfile.demoUsers.firstWhere((u) => u.name == 'Majid Al-Dossary');
    provider.switchUser(majid);

    // Seed an existing submitted application
    final app = CardApplication(
      id: 'APP-2026-100',
      fullNameEnglish: 'Majid Al-Dossary',
      fullNameArabic: 'ماجد الدوسري',
      nationality: 'Saudi Arabia',
      dateOfBirth: DateTime(1992, 5, 14),
      iqamaNumber: '2501928374',
      iqamaExpiryDateGregorian: DateTime(2028, 8, 20),
      iqamaExpiryDateHijri: '1450/02/29',
      passportNumber: 'N8492014',
      passportIssueDate: DateTime(2022, 1, 10),
      passportExpiryDate: DateTime(2032, 1, 9),
      mobileNumberPersonal: '+966 56 332 1144',
      mobileNumberOfficial: '+966 56 000 0000',
      emailOfficial: 'm.dossary@expertise.sa',
      shortAddressCode: 'JAZ4109',
      buildingNumber: '4012',
      streetName: 'Corniche Rd',
      district: 'Al-Shati',
      city: 'Jazan',
      postalCode: '45142',
      employeeId: majid.employeeId,
      designation: majid.designation,
      employeeGrade: 'Band-B',
      company: majid.company,
      division: majid.division,
      department: majid.department,
      costCenter: majid.costCenter,
      reportingManagerName: 'Rajesh M. Shetty',
      reportingManagerId: 'EMP-1002',
      projectWbsCode: 'PRJ-2026-JAZAN',
      operatingSiteLocation: majid.division,
      cardFormat: CardFormat.physicalPlastic,
      embossedName: 'MAJID AL-DOSSARY',
      monthlyLimit: 5000.0,
      singleTransactionCap: 2000.0,
      dailySpendingCap: 3000.0,
      authorizedCategories: const ['Fuel & Fleet'],
      deliveryPreference: 'Site Courier',
      personalIban: 'SA0380000000608010167519',
      bankName: 'Al Rajhi Bank',
      emergencyContactName: '',
      emergencyContactMobile: '',
      emergencyRelation: '',
      termsAccepted: true,
      submissionTimestamp: DateTime.now(),
      status: ApplicationStatus.submitted,
    );
    provider.submitCardApplication(app);

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

    // Confirm Tracker screen elements are displayed
    expect(find.text('APPLICATION TRACKER'), findsOneWidget);
    expect(find.text('APP-2026-100'), findsOneWidget);
    expect(find.text('Submitted & SAMA KYC Pending'), findsOneWidget);
    expect(find.text('Delete KYC Details & Apply Again'), findsOneWidget);

    // Tap Delete KYC button
    await tester.tap(find.text('Delete KYC Details & Apply Again'));
    await tester.pumpAndSettle();

    // Confirm Confirmation Dialog appears
    expect(find.text('Delete KYC Details?'), findsOneWidget);
    expect(find.text('Delete & Re-apply'), findsOneWidget);

    // Confirm deletion
    await tester.tap(find.text('Delete & Re-apply'));
    await tester.pumpAndSettle();

    // Provider state is cleared
    expect(provider.activeCardApplication, isNull);

    // Screen transitions back to 1-Step KYC upload wizard
    expect(find.text('1. UPLOAD KYC DOCUMENTS'), findsOneWidget);
    expect(find.text('Saudi Iqama'), findsOneWidget);
    expect(find.text('Passport Copy'), findsOneWidget);
    expect(find.text('Applicant Picture'), findsOneWidget);
  });
}
