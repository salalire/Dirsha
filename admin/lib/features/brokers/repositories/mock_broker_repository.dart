import '../models/broker_application.dart';
import 'broker_repository.dart';

class MockBrokerRepository implements BrokerRepository {
  final List<BrokerApplication> _data = [
    BrokerApplication(
      id: 'brk-001',
      applicantName: 'Tewodros Kassahun',
      applicantEmail: 'tewodros.kassahun@example.dev',
      brokerType: 'firm',
      firmName: 'Abyssinia Capital Securities',
      licenseNumber: 'ECMA-BRK-2026-0042',
      licenseAuthority: 'Ethiopian Capital Market Authority (ECMA)',
      jurisdiction: 'ET',
      licenseExpiryDate: DateTime(2027, 12, 31),
      isLicenseExpired: false,
      businessAddress: 'Bole Road, Mega Building 4th Floor, Addis Ababa',
      businessEmail: 'info@abyssiniacapital.et',
      businessPhone: '+251 11 661 2233',
      status: BrokerApplicationStatus.pending,
      submittedAt: DateTime(2026, 10, 18),
      documents: [
        BrokerDocumentMetadata(
          id: 'bdoc-001',
          name: 'ECMA Broker-Dealer License.pdf',
          documentType: 'broker_license',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 18),
        ),
        BrokerDocumentMetadata(
          id: 'bdoc-002',
          name: 'Commercial Registration Certificate.pdf',
          documentType: 'firm_registration',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 18),
        ),
      ],
    ),
    BrokerApplication(
      id: 'brk-002',
      applicantName: 'Makeda Bekele',
      applicantEmail: 'makeda.bekele@example.dev',
      brokerType: 'individual',
      licenseNumber: 'ECMA-IND-2025-0118',
      licenseAuthority: 'Ethiopian Capital Market Authority (ECMA)',
      jurisdiction: 'ET',
      licenseExpiryDate: DateTime(2025, 05, 30),
      isLicenseExpired: true,
      businessAddress: 'Kazanchis, Addis Ababa',
      businessEmail: 'makeda.bekele@example.dev',
      businessPhone: '+251 91 123 4567',
      status: BrokerApplicationStatus.underReview,
      submittedAt: DateTime(2026, 10, 16),
      documents: [
        BrokerDocumentMetadata(
          id: 'bdoc-003',
          name: 'Representative License.pdf',
          documentType: 'broker_license',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 16),
        ),
      ],
    ),
    BrokerApplication(
      id: 'brk-003',
      applicantName: 'Yared Tesfaye',
      applicantEmail: 'yared.tesfaye@example.dev',
      brokerType: 'firm',
      firmName: 'Lion Financial Services',
      licenseNumber: 'ECMA-BRK-2026-0008',
      licenseAuthority: 'Ethiopian Capital Market Authority (ECMA)',
      jurisdiction: 'ET',
      licenseExpiryDate: DateTime(2027, 08, 15),
      isLicenseExpired: false,
      businessAddress: 'Mexico Square, Addis Ababa',
      businessEmail: 'contact@lionfinancial.et',
      businessPhone: '+251 11 551 7788',
      status: BrokerApplicationStatus.approved,
      submittedAt: DateTime(2026, 10, 10),
      reviewedAt: DateTime(2026, 10, 12),
      documents: [
        BrokerDocumentMetadata(
          id: 'bdoc-004',
          name: 'ECMA License.pdf',
          documentType: 'broker_license',
          reviewStatus: 'approved',
          submittedAt: DateTime(2026, 10, 10),
        ),
      ],
    ),
  ];

  @override
  Future<List<BrokerApplication>> getApplications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_data);
  }

  @override
  Future<BrokerApplication> getApplicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _data.firstWhere(
      (b) => b.id == id,
      orElse: () => throw Exception('Broker application not found: $id'),
    );
  }

  @override
  Future<void> approveApplication(String id, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _data.indexWhere((b) => b.id == id);
    if (idx == -1) throw Exception('Broker application not found: $id');
    final curr = _data[idx];
    _data[idx] = BrokerApplication(
      id: curr.id,
      applicantName: curr.applicantName,
      applicantEmail: curr.applicantEmail,
      brokerType: curr.brokerType,
      firmName: curr.firmName,
      licenseNumber: curr.licenseNumber,
      licenseAuthority: curr.licenseAuthority,
      jurisdiction: curr.jurisdiction,
      licenseExpiryDate: curr.licenseExpiryDate,
      isLicenseExpired: curr.isLicenseExpired,
      businessAddress: curr.businessAddress,
      businessEmail: curr.businessEmail,
      businessPhone: curr.businessPhone,
      status: BrokerApplicationStatus.approved,
      submittedAt: curr.submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: notes,
      documents: curr.documents,
    );
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _data.indexWhere((b) => b.id == id);
    if (idx == -1) throw Exception('Broker application not found: $id');
    final curr = _data[idx];
    _data[idx] = BrokerApplication(
      id: curr.id,
      applicantName: curr.applicantName,
      applicantEmail: curr.applicantEmail,
      brokerType: curr.brokerType,
      firmName: curr.firmName,
      licenseNumber: curr.licenseNumber,
      licenseAuthority: curr.licenseAuthority,
      jurisdiction: curr.jurisdiction,
      licenseExpiryDate: curr.licenseExpiryDate,
      isLicenseExpired: curr.isLicenseExpired,
      businessAddress: curr.businessAddress,
      businessEmail: curr.businessEmail,
      businessPhone: curr.businessPhone,
      status: BrokerApplicationStatus.rejected,
      submittedAt: curr.submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: reason,
      documents: curr.documents,
    );
  }

  @override
  Future<void> requestAdditionalInfo(String id, {required String message}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _data.indexWhere((b) => b.id == id);
    if (idx == -1) throw Exception('Broker application not found: $id');
    final curr = _data[idx];
    _data[idx] = BrokerApplication(
      id: curr.id,
      applicantName: curr.applicantName,
      applicantEmail: curr.applicantEmail,
      brokerType: curr.brokerType,
      firmName: curr.firmName,
      licenseNumber: curr.licenseNumber,
      licenseAuthority: curr.licenseAuthority,
      jurisdiction: curr.jurisdiction,
      licenseExpiryDate: curr.licenseExpiryDate,
      isLicenseExpired: curr.isLicenseExpired,
      businessAddress: curr.businessAddress,
      businessEmail: curr.businessEmail,
      businessPhone: curr.businessPhone,
      status: BrokerApplicationStatus.additionalInfoRequired,
      submittedAt: curr.submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: message,
      documents: curr.documents,
    );
  }

  @override
  Future<void> reviewDocument(
      String documentId, {required String status, String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
