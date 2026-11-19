class UserProfile {
  final String id;
  final String name;
  final String employeeId;
  final String designation;
  final String company;
  final String division;
  final String department;
  final String costCenter;
  final String iqama;
  final String phone;
  final String role; // e.g., "Custodian", "Approver", "Finance", "Admin"
  final String assignedCardNumber;
  final bool hasActiveCard;
  final String scenarioDescription;

  const UserProfile({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.designation,
    required this.company,
    required this.division,
    required this.department,
    required this.costCenter,
    required this.iqama,
    required this.phone,
    required this.role,
    required this.assignedCardNumber,
    this.hasActiveCard = true,
    this.scenarioDescription = 'Active Card Custodian',
  });

  static const List<UserProfile> demoUsers = [
    UserProfile(
      id: 'USR-001',
      name: 'Tariq Mansoor',
      employeeId: 'EMP-9021',
      designation: 'Site Operations Lead',
      company: 'Expertise Contracting Co.',
      division: 'Eastern Region (Dammam)',
      department: 'Logistics & Fleet',
      costCenter: 'CC-101',
      iqama: '2491823401',
      phone: '+966 50 123 4567',
      role: 'Custodian',
      assignedCardNumber: '4821-8890-1120-9901',
      hasActiveCard: true,
      scenarioDescription: 'Active Custodian (Low Balance • Refill & Claims Demo)',
    ),
    UserProfile(
      id: 'USR-003',
      name: 'Majid Al-Dossary',
      employeeId: 'EMP-9812',
      designation: 'Electrical Field Technician',
      company: 'Expertise Contracting Co.',
      division: 'Southern Division (Jazan Project)',
      department: 'Field Engineering',
      costCenter: 'CC-305',
      iqama: '2501928374',
      phone: '+966 56 332 1144',
      role: 'Custodian',
      assignedCardNumber: '',
      hasActiveCard: false,
      scenarioDescription: 'New Employee: Ready to Apply & Upload KYC Details',
    ),
    UserProfile(
      id: 'USR-004',
      name: 'Salman Farooq',
      employeeId: 'EMP-8419',
      designation: 'Industrial Field Supervisor',
      company: 'Expertise Contracting Co.',
      division: 'Jubail Industrial Division',
      department: 'Heavy Equipment Maintenance',
      costCenter: 'CC-104',
      iqama: '2381923412',
      phone: '+966 55 987 6543',
      role: 'Custodian',
      assignedCardNumber: '4821-7734-2201-4412',
      hasActiveCard: true,
      scenarioDescription: 'Active Custodian (Jubail Division)',
    ),
  ];
}

