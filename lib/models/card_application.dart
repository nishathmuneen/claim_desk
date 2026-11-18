enum CardFormat {
  physicalPlastic,
  virtualDigital,
}

enum ApplicationStatus {
  draft,
  submitted,
  managerReview,
  financeApproval,
  embossingAndDispatch,
  active,
  rejected,
}

class CardApplication {
  final String id;
  // Personal & Legal Identity
  final String fullNameEnglish;
  final String fullNameArabic;
  final String nationality;
  final DateTime dateOfBirth;
  final String iqamaNumber;
  final DateTime iqamaExpiryDateGregorian;
  final String iqamaExpiryDateHijri;
  final String passportNumber;
  final DateTime passportIssueDate;
  final DateTime passportExpiryDate;
  final String mobileNumberPersonal;
  final String mobileNumberOfficial;
  final String emailOfficial;

  // National Address (SPL)
  final String shortAddressCode;
  final String buildingNumber;
  final String streetName;
  final String district;
  final String city;
  final String postalCode;

  // Corporate & Project Allocation
  final String employeeId;
  final String designation;
  final String employeeGrade;
  final String company;
  final String division;
  final String department;
  final String costCenter;
  final String reportingManagerName;
  final String reportingManagerId;
  final String projectWbsCode;
  final String operatingSiteLocation;

  // Financial Controls
  final CardFormat cardFormat;
  final String embossedName;
  final double monthlyLimit;
  final double singleTransactionCap;
  final double dailySpendingCap;
  final List<String> authorizedCategories;

  // Delivery Preferences
  final String deliveryPreference; // "Head Office Collection (Dammam/Jubail)" or "Site Courier Dispatch"
  final String? siteReceivingContactName;
  final String? siteReceivingContactMobile;

  // KYC Attachments & Biometrics
  final String? passportCopyPath;
  final String? iqamaCopyPath;
  final String? applicantPhotoPath;
  final String? signatureSpecimenPath;
  final String? drivingLicensePath;
  final String? clientGatePassPath;

  // Accountability & Settlement
  final String personalIban;
  final String bankName;
  final String emergencyContactName;
  final String emergencyContactMobile;
  final String emergencyRelation;
  final bool termsAccepted;
  final DateTime submissionTimestamp;

  // Status & Audit
  final ApplicationStatus status;
  final String? reviewerComment;
  final DateTime? estimatedActivationDate;

  const CardApplication({
    required this.id,
    required this.fullNameEnglish,
    required this.fullNameArabic,
    required this.nationality,
    required this.dateOfBirth,
    required this.iqamaNumber,
    required this.iqamaExpiryDateGregorian,
    required this.iqamaExpiryDateHijri,
    required this.passportNumber,
    required this.passportIssueDate,
    required this.passportExpiryDate,
    required this.mobileNumberPersonal,
    required this.mobileNumberOfficial,
    required this.emailOfficial,
    required this.shortAddressCode,
    required this.buildingNumber,
    required this.streetName,
    required this.district,
    required this.city,
    required this.postalCode,
    required this.employeeId,
    required this.designation,
    required this.employeeGrade,
    required this.company,
    required this.division,
    required this.department,
    required this.costCenter,
    required this.reportingManagerName,
    required this.reportingManagerId,
    required this.projectWbsCode,
    required this.operatingSiteLocation,
    required this.cardFormat,
    required this.embossedName,
    required this.monthlyLimit,
    required this.singleTransactionCap,
    required this.dailySpendingCap,
    required this.authorizedCategories,
    required this.deliveryPreference,
    this.siteReceivingContactName,
    this.siteReceivingContactMobile,
    this.passportCopyPath,
    this.iqamaCopyPath,
    this.applicantPhotoPath,
    this.signatureSpecimenPath,
    this.drivingLicensePath,
    this.clientGatePassPath,
    required this.personalIban,
    required this.bankName,
    required this.emergencyContactName,
    required this.emergencyContactMobile,
    required this.emergencyRelation,
    required this.termsAccepted,
    required this.submissionTimestamp,
    required this.status,
    this.reviewerComment,
    this.estimatedActivationDate,
  });

  String get statusDisplay {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.submitted:
        return 'Submitted & SAMA KYC Pending';
      case ApplicationStatus.managerReview:
        return 'Line Manager Review';
      case ApplicationStatus.financeApproval:
        return 'Finance & AP Approval';
      case ApplicationStatus.embossingAndDispatch:
        return 'Embossing & Courier Dispatch';
      case ApplicationStatus.active:
        return 'Active & Funds Ready';
      case ApplicationStatus.rejected:
        return 'Application Rejected';
    }
  }

  int get currentStageIndex {
    switch (status) {
      case ApplicationStatus.draft:
        return 0;
      case ApplicationStatus.submitted:
        return 1;
      case ApplicationStatus.managerReview:
        return 2;
      case ApplicationStatus.financeApproval:
        return 3;
      case ApplicationStatus.embossingAndDispatch:
        return 4;
      case ApplicationStatus.active:
        return 5;
      case ApplicationStatus.rejected:
        return 3;
    }
  }

  CardApplication copyWith({
    String? id,
    String? fullNameEnglish,
    String? fullNameArabic,
    String? nationality,
    DateTime? dateOfBirth,
    String? iqamaNumber,
    DateTime? iqamaExpiryDateGregorian,
    String? iqamaExpiryDateHijri,
    String? passportNumber,
    DateTime? passportIssueDate,
    DateTime? passportExpiryDate,
    String? mobileNumberPersonal,
    String? mobileNumberOfficial,
    String? emailOfficial,
    String? shortAddressCode,
    String? buildingNumber,
    String? streetName,
    String? district,
    String? city,
    String? postalCode,
    String? employeeId,
    String? designation,
    String? employeeGrade,
    String? company,
    String? division,
    String? department,
    String? costCenter,
    String? reportingManagerName,
    String? reportingManagerId,
    String? projectWbsCode,
    String? operatingSiteLocation,
    CardFormat? cardFormat,
    String? embossedName,
    double? monthlyLimit,
    double? singleTransactionCap,
    double? dailySpendingCap,
    List<String>? authorizedCategories,
    String? deliveryPreference,
    String? siteReceivingContactName,
    String? siteReceivingContactMobile,
    String? passportCopyPath,
    String? iqamaCopyPath,
    String? applicantPhotoPath,
    String? signatureSpecimenPath,
    String? drivingLicensePath,
    String? clientGatePassPath,
    String? personalIban,
    String? bankName,
    String? emergencyContactName,
    String? emergencyContactMobile,
    String? emergencyRelation,
    bool? termsAccepted,
    DateTime? submissionTimestamp,
    ApplicationStatus? status,
    String? reviewerComment,
    DateTime? estimatedActivationDate,
  }) {
    return CardApplication(
      id: id ?? this.id,
      fullNameEnglish: fullNameEnglish ?? this.fullNameEnglish,
      fullNameArabic: fullNameArabic ?? this.fullNameArabic,
      nationality: nationality ?? this.nationality,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      iqamaNumber: iqamaNumber ?? this.iqamaNumber,
      iqamaExpiryDateGregorian: iqamaExpiryDateGregorian ?? this.iqamaExpiryDateGregorian,
      iqamaExpiryDateHijri: iqamaExpiryDateHijri ?? this.iqamaExpiryDateHijri,
      passportNumber: passportNumber ?? this.passportNumber,
      passportIssueDate: passportIssueDate ?? this.passportIssueDate,
      passportExpiryDate: passportExpiryDate ?? this.passportExpiryDate,
      mobileNumberPersonal: mobileNumberPersonal ?? this.mobileNumberPersonal,
      mobileNumberOfficial: mobileNumberOfficial ?? this.mobileNumberOfficial,
      emailOfficial: emailOfficial ?? this.emailOfficial,
      shortAddressCode: shortAddressCode ?? this.shortAddressCode,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      streetName: streetName ?? this.streetName,
      district: district ?? this.district,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      employeeId: employeeId ?? this.employeeId,
      designation: designation ?? this.designation,
      employeeGrade: employeeGrade ?? this.employeeGrade,
      company: company ?? this.company,
      division: division ?? this.division,
      department: department ?? this.department,
      costCenter: costCenter ?? this.costCenter,
      reportingManagerName: reportingManagerName ?? this.reportingManagerName,
      reportingManagerId: reportingManagerId ?? this.reportingManagerId,
      projectWbsCode: projectWbsCode ?? this.projectWbsCode,
      operatingSiteLocation: operatingSiteLocation ?? this.operatingSiteLocation,
      cardFormat: cardFormat ?? this.cardFormat,
      embossedName: embossedName ?? this.embossedName,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      singleTransactionCap: singleTransactionCap ?? this.singleTransactionCap,
      dailySpendingCap: dailySpendingCap ?? this.dailySpendingCap,
      authorizedCategories: authorizedCategories ?? this.authorizedCategories,
      deliveryPreference: deliveryPreference ?? this.deliveryPreference,
      siteReceivingContactName: siteReceivingContactName ?? this.siteReceivingContactName,
      siteReceivingContactMobile: siteReceivingContactMobile ?? this.siteReceivingContactMobile,
      passportCopyPath: passportCopyPath ?? this.passportCopyPath,
      iqamaCopyPath: iqamaCopyPath ?? this.iqamaCopyPath,
      applicantPhotoPath: applicantPhotoPath ?? this.applicantPhotoPath,
      signatureSpecimenPath: signatureSpecimenPath ?? this.signatureSpecimenPath,
      drivingLicensePath: drivingLicensePath ?? this.drivingLicensePath,
      clientGatePassPath: clientGatePassPath ?? this.clientGatePassPath,
      personalIban: personalIban ?? this.personalIban,
      bankName: bankName ?? this.bankName,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactMobile: emergencyContactMobile ?? this.emergencyContactMobile,
      emergencyRelation: emergencyRelation ?? this.emergencyRelation,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      submissionTimestamp: submissionTimestamp ?? this.submissionTimestamp,
      status: status ?? this.status,
      reviewerComment: reviewerComment ?? this.reviewerComment,
      estimatedActivationDate: estimatedActivationDate ?? this.estimatedActivationDate,
    );
  }
}

