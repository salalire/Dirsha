// ⚠️  DEVELOPMENT MOCK DATA — NOT REAL IPO APPLICATIONS
//
// These are entirely fictional company and offering names for UI testing only.
// No real financial figures, prices, or share quantities are represented here.
// Replace with ApiIpoRepository once Member 2's /admin/ipos endpoint is ready.

import '../models/ipo_application.dart';
import 'ipo_repository.dart';

class MockIpoRepository implements IpoRepository {
  final List<IpoApplication> _data = [
    IpoApplication(
      id: 'ipo-001',
      offeringTitle: 'Addis Capital PLC — Series A IPO',
      companyId: 'cmp-001',
      companyName: 'Addis Capital PLC',
      status: IpoStatus.submitted,
      submittedAt: DateTime(2026, 10, 18),
      documents: [
        IpoDocumentMetadata(
          id: 'ipodoc-001',
          name: 'IPO Prospectus',
          documentType: 'prospectus',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 18),
        ),
        IpoDocumentMetadata(
          id: 'ipodoc-002',
          name: 'Audited Financial Statements',
          documentType: 'financial',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 18),
        ),
      ],
    ),
    IpoApplication(
      id: 'ipo-002',
      offeringTitle: 'Habesha Agri-Tech Ltd — Public Offering',
      companyId: 'cmp-002',
      companyName: 'Habesha Agri-Tech Ltd',
      status: IpoStatus.underReview,
      submittedAt: DateTime(2026, 10, 15),
      documents: [
        IpoDocumentMetadata(
          id: 'ipodoc-003',
          name: 'IPO Prospectus',
          documentType: 'prospectus',
          reviewStatus: 'approved',
          submittedAt: DateTime(2026, 10, 15),
        ),
      ],
    ),
    IpoApplication(
      id: 'ipo-003',
      offeringTitle: 'Nile Renewables S.C. — Green Energy IPO',
      companyId: 'cmp-003',
      companyName: 'Nile Renewables S.C.',
      status: IpoStatus.approved,
      submittedAt: DateTime(2026, 10, 10),
      reviewedAt: DateTime(2026, 10, 13),
      openDate: DateTime(2026, 10, 25),
      closeDate: DateTime(2026, 11, 5),
      // 500 ETB per share = 50 000 santim (100 santim = 1 ETB)
      // DEMO VALUE ONLY — not a real offering price.
      pricePerShareSantim: 50000,
      totalSharesOffered: 2000000,
      documents: [],
    ),
    IpoApplication(
      id: 'ipo-004',
      offeringTitle: 'Lalibela Mining Co. — Initial Offering',
      companyId: 'cmp-004',
      companyName: 'Lalibela Mining Co.',
      status: IpoStatus.rejected,
      submittedAt: DateTime(2026, 10, 8),
      reviewedAt: DateTime(2026, 10, 11),
      reviewNotes: 'Prospectus did not meet minimum disclosure requirements.',
      documents: [],
    ),
    IpoApplication(
      id: 'ipo-005',
      offeringTitle: 'Ethiopian Highlands Coffee — Share Offer',
      companyId: 'cmp-005',
      companyName: 'Ethiopian Highlands Coffee PLC',
      status: IpoStatus.submitted,
      submittedAt: DateTime(2026, 10, 20),
      documents: [
        IpoDocumentMetadata(
          id: 'ipodoc-004',
          name: 'IPO Prospectus',
          documentType: 'prospectus',
          reviewStatus: 'pending',
          submittedAt: DateTime(2026, 10, 20),
        ),
      ],
    ),
  ];

  @override
  Future<List<IpoApplication>> getApplications() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_data);
  }

  @override
  Future<IpoApplication> getApplicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _data.firstWhere(
      (i) => i.id == id,
      orElse: () => throw Exception('IPO application not found: $id'),
    );
  }

  @override
  Future<void> approveApplication(String id,
      {String? notes, bool openImmediately = false}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final idx = _data.indexWhere((i) => i.id == id);
    if (idx == -1) throw Exception('IPO application not found: $id');
    if (!_data[idx].isReviewable) {
      throw Exception(
          'IPO is not in a reviewable state: ${_data[idx].status.label}');
    }
    _data[idx] = IpoApplication(
      id: _data[idx].id,
      offeringTitle: _data[idx].offeringTitle,
      companyId: _data[idx].companyId,
      companyName: _data[idx].companyName,
      status: openImmediately ? IpoStatus.open : IpoStatus.approved,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: notes,
      openDate: openImmediately ? DateTime.now() : _data[idx].openDate,
      closeDate: _data[idx].closeDate,
      pricePerShareSantim: _data[idx].pricePerShareSantim,
      totalSharesOffered: _data[idx].totalSharesOffered,
      documents: _data[idx].documents,
    );
  }

  @override
  Future<void> openIpo(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _data.indexWhere((i) => i.id == id);
    if (idx == -1) throw Exception('IPO application not found: $id');
    if (_data[idx].status != IpoStatus.approved) {
      throw Exception('Only approved IPOs can be opened');
    }
    _data[idx] = IpoApplication(
      id: _data[idx].id,
      offeringTitle: _data[idx].offeringTitle,
      companyId: _data[idx].companyId,
      companyName: _data[idx].companyName,
      status: IpoStatus.open,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: _data[idx].reviewedAt,
      reviewNotes: reason ?? _data[idx].reviewNotes,
      openDate: DateTime.now(),
      closeDate: _data[idx].closeDate,
      pricePerShareSantim: _data[idx].pricePerShareSantim,
      totalSharesOffered: _data[idx].totalSharesOffered,
      documents: _data[idx].documents,
    );
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final idx = _data.indexWhere((i) => i.id == id);
    if (idx == -1) throw Exception('IPO application not found: $id');
    if (!_data[idx].isReviewable) {
      throw Exception(
          'IPO is not in a reviewable state: ${_data[idx].status.label}');
    }
    _data[idx] = IpoApplication(
      id: _data[idx].id,
      offeringTitle: _data[idx].offeringTitle,
      companyId: _data[idx].companyId,
      companyName: _data[idx].companyName,
      status: IpoStatus.rejected,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: reason,
      openDate: _data[idx].openDate,
      closeDate: _data[idx].closeDate,
      pricePerShareSantim: _data[idx].pricePerShareSantim,
      totalSharesOffered: _data[idx].totalSharesOffered,
      documents: _data[idx].documents,
    );
  }

  @override
  Future<void> closeIpo(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _data.indexWhere((i) => i.id == id);
    if (idx == -1) throw Exception('IPO application not found: $id');
    _data[idx] = IpoApplication(
      id: _data[idx].id,
      offeringTitle: _data[idx].offeringTitle,
      companyId: _data[idx].companyId,
      companyName: _data[idx].companyName,
      status: IpoStatus.closed,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: _data[idx].reviewedAt,
      reviewNotes: reason ?? _data[idx].reviewNotes,
      openDate: _data[idx].openDate,
      closeDate: DateTime.now(),
      pricePerShareSantim: _data[idx].pricePerShareSantim,
      totalSharesOffered: _data[idx].totalSharesOffered,
      documents: _data[idx].documents,
    );
  }

  @override
  Future<void> allocateIpo(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _data.indexWhere((i) => i.id == id);
    if (idx == -1) throw Exception('IPO application not found: $id');
    _data[idx] = IpoApplication(
      id: _data[idx].id,
      offeringTitle: _data[idx].offeringTitle,
      companyId: _data[idx].companyId,
      companyName: _data[idx].companyName,
      status: IpoStatus.allocated,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: _data[idx].reviewedAt,
      reviewNotes: _data[idx].reviewNotes,
      openDate: _data[idx].openDate,
      closeDate: _data[idx].closeDate,
      pricePerShareSantim: _data[idx].pricePerShareSantim,
      totalSharesOffered: _data[idx].totalSharesOffered,
      documents: _data[idx].documents,
    );
  }

  @override
  Future<void> listIpo(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _data.indexWhere((i) => i.id == id);
    if (idx == -1) throw Exception('IPO application not found: $id');
    _data[idx] = IpoApplication(
      id: _data[idx].id,
      offeringTitle: _data[idx].offeringTitle,
      companyId: _data[idx].companyId,
      companyName: _data[idx].companyName,
      status: IpoStatus.listed,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: _data[idx].reviewedAt,
      reviewNotes: reason ?? _data[idx].reviewNotes,
      openDate: _data[idx].openDate,
      closeDate: _data[idx].closeDate,
      pricePerShareSantim: _data[idx].pricePerShareSantim,
      totalSharesOffered: _data[idx].totalSharesOffered,
      documents: _data[idx].documents,
    );
  }
}
