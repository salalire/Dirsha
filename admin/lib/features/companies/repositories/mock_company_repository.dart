// ⚠️  DEVELOPMENT MOCK DATA — NOT REAL COMPANY RECORDS
//
// These are entirely fictional company names and contacts for UI testing only.
// Replace with ApiCompanyRepository once Member 2's /admin/companies endpoint
// is ready and the API contract is confirmed.

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
      documents: [
        DocumentMetadata(
          id: 'doc-001',
          name: 'Business Registration Certificate',
          documentType: 'registration',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 17),
        ),
        DocumentMetadata(
          id: 'doc-002',
          name: 'Memorandum of Association',
          documentType: 'legal',
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
      documents: [
        DocumentMetadata(
          id: 'doc-003',
          name: 'Business Registration Certificate',
          documentType: 'registration',
          reviewStatus: 'approved',
          submittedAt: DateTime(2026, 10, 15),
        ),
        DocumentMetadata(
          id: 'doc-004',
          name: 'Audited Financial Statements',
          documentType: 'financial',
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
      documents: [
        DocumentMetadata(
          id: 'doc-005',
          name: 'Business Registration Certificate',
          documentType: 'registration',
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
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_data);
  }

  @override
  Future<CompanyApplication> getApplicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _data.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Company application not found: $id'),
    );
  }

  @override
  Future<void> approveApplication(String id, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final idx = _data.indexWhere((c) => c.id == id);
    if (idx == -1) throw Exception('Company application not found: $id');
    _data[idx] = CompanyApplication(
      id: _data[idx].id,
      companyName: _data[idx].companyName,
      representativeName: _data[idx].representativeName,
      representativeEmail: _data[idx].representativeEmail,
      status: CompanyApplicationStatus.approved,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: notes,
      documents: _data[idx].documents,
    );
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final idx = _data.indexWhere((c) => c.id == id);
    if (idx == -1) throw Exception('Company application not found: $id');
    _data[idx] = CompanyApplication(
      id: _data[idx].id,
      companyName: _data[idx].companyName,
      representativeName: _data[idx].representativeName,
      representativeEmail: _data[idx].representativeEmail,
      status: CompanyApplicationStatus.rejected,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: reason,
      documents: _data[idx].documents,
    );
  }
}
