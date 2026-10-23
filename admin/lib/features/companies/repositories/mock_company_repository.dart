import '../models/company_application.dart';
import 'company_repository.dart';

class MockCompanyRepository implements CompanyRepository {
  final List<CompanyApplication> _data = [
    CompanyApplication(
      id: 'cmp-001',
      companyName: 'Addis Capital PLC',
      representativeName: 'Solomon Tadesse',
      representativeEmail: 's.tadesse@example.dev',
      status: CompanyApplicationStatus.pending,
      submittedAt: DateTime(2026, 10, 17),
      registrationNumber: 'CR-102938',
      tin: '0012345678',
      sector: 'Financial Services',
      businessAddress: 'Addis Ababa, Bole Sub-City, Kebele 03',
      documents: [
        DocumentMetadata(
          id: 'doc-001',
          name: 'Business Registration Certificate',
          documentType: 'commercial_registration',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 17),
        ),
        DocumentMetadata(
          id: 'doc-002',
          name: 'Tax Identification Number Certificate',
          documentType: 'tin_certificate',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 17),
        ),
      ],
    ),
    CompanyApplication(
      id: 'cmp-002',
      companyName: 'Habesha Agri-Tech Ltd',
      representativeName: 'Hiwot Mulugeta',
      representativeEmail: 'h.mulugeta@example.dev',
      status: CompanyApplicationStatus.underReview,
      submittedAt: DateTime(2026, 10, 15),
      registrationNumber: 'CR-887766',
      tin: '0099887766',
      sector: 'Agriculture & Technology',
      businessAddress: 'Hawassa Industrial Park, Ethiopia',
      documents: [
        DocumentMetadata(
          id: 'doc-003',
          name: 'Business Registration Certificate',
          documentType: 'commercial_registration',
          reviewStatus: 'approved',
          submittedAt: DateTime(2026, 10, 15),
        ),
        DocumentMetadata(
          id: 'doc-004',
          name: 'TIN Certificate',
          documentType: 'tin_certificate',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 15),
        ),
      ],
    ),
    CompanyApplication(
      id: 'cmp-003',
      companyName: 'Nile Renewables S.C.',
      representativeName: 'Biruk Assefa',
      representativeEmail: 'b.assefa@example.dev',
      status: CompanyApplicationStatus.approved,
      submittedAt: DateTime(2026, 10, 10),
      reviewedAt: DateTime(2026, 10, 13),
      registrationNumber: 'CR-554433',
      tin: '0055443322',
      sector: 'Renewable Energy',
      documents: [
        DocumentMetadata(
          id: 'doc-005',
          name: 'Business Registration Certificate',
          documentType: 'commercial_registration',
          reviewStatus: 'approved',
          submittedAt: DateTime(2026, 10, 10),
        ),
      ],
    ),
    CompanyApplication(
      id: 'cmp-004',
      companyName: 'Lalibela Mining Co.',
      representativeName: 'Selamawit Getachew',
      representativeEmail: 's.getachew@example.dev',
      status: CompanyApplicationStatus.rejected,
      submittedAt: DateTime(2026, 10, 8),
      reviewedAt: DateTime(2026, 10, 11),
      reviewNotes: 'Insufficient financial documentation provided.',
      documents: [],
    ),
  ];

  @override
  Future<List<CompanyApplication>> getApplications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_data);
  }

  @override
  Future<CompanyApplication> getApplicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _data.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Company application not found: $id'),
    );
  }

  @override
  Future<void> approveApplication(String id, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _data.indexWhere((c) => c.id == id);
    if (idx == -1) throw Exception('Company application not found: $id');
    final curr = _data[idx];
    _data[idx] = CompanyApplication(
      id: curr.id,
      companyName: curr.companyName,
      representativeName: curr.representativeName,
      representativeEmail: curr.representativeEmail,
      status: CompanyApplicationStatus.approved,
      submittedAt: curr.submittedAt,
      registrationNumber: curr.registrationNumber,
      tin: curr.tin,
      legalEntityType: curr.legalEntityType,
      sector: curr.sector,
      businessAddress: curr.businessAddress,
      businessEmail: curr.businessEmail,
      businessPhone: curr.businessPhone,
      website: curr.website,
      reviewedAt: DateTime.now(),
      reviewNotes: notes,
      documents: curr.documents,
    );
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _data.indexWhere((c) => c.id == id);
    if (idx == -1) throw Exception('Company application not found: $id');
    final curr = _data[idx];
    _data[idx] = CompanyApplication(
      id: curr.id,
      companyName: curr.companyName,
      representativeName: curr.representativeName,
      representativeEmail: curr.representativeEmail,
      status: CompanyApplicationStatus.rejected,
      submittedAt: curr.submittedAt,
      registrationNumber: curr.registrationNumber,
      tin: curr.tin,
      legalEntityType: curr.legalEntityType,
      sector: curr.sector,
      businessAddress: curr.businessAddress,
      businessEmail: curr.businessEmail,
      businessPhone: curr.businessPhone,
      website: curr.website,
      reviewedAt: DateTime.now(),
      reviewNotes: reason,
      documents: curr.documents,
    );
  }

  @override
  Future<void> requestAdditionalInfo(String id, {required String message}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _data.indexWhere((c) => c.id == id);
    if (idx == -1) throw Exception('Company application not found: $id');
    final curr = _data[idx];
    _data[idx] = CompanyApplication(
      id: curr.id,
      companyName: curr.companyName,
      representativeName: curr.representativeName,
      representativeEmail: curr.representativeEmail,
      status: CompanyApplicationStatus.additionalInfoRequired,
      submittedAt: curr.submittedAt,
      registrationNumber: curr.registrationNumber,
      tin: curr.tin,
      legalEntityType: curr.legalEntityType,
      sector: curr.sector,
      businessAddress: curr.businessAddress,
      businessEmail: curr.businessEmail,
      businessPhone: curr.businessPhone,
      website: curr.website,
      reviewedAt: DateTime.now(),
      reviewNotes: message,
      documents: curr.documents,
    );
  }

  @override
  Future<void> reviewDocument(String documentId, {required String status, String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
