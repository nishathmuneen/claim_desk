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
    ),
    UserProfile(
      id: 'USR-002',
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
    ),
    UserProfile(
      id: 'USR-003',
      name: 'Sarah Al-Otaibi',
      employeeId: 'EMP-7710',
      designation: 'Admin & Facilities Coordinator',
      company: 'Expertise Contracting Co.',
      division: 'Central Division (Riyadh)',
      department: 'Administration',
      costCenter: 'CC-108',
      iqama: '1092837461',
      phone: '+966 53 456 7890',
      role: 'Custodian',
      assignedCardNumber: '4821-6621-3312-8803',
    ),
  ];
}

