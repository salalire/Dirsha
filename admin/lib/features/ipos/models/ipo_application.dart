/// Represents an IPO application in the admin dashboard.
///
/// Lifecycle follows the SRS state machine:
/// Draft → Submitted → Under Review → Approved → Open → Closed →
/// Allocated → Listed  (with Rejected/Withdrawn paths)
///
/// Phase 1 focus: Submitted, Under Review, Approved, Rejected.
/// Field names pending final agreement with Member 2's API contract.
///
/// ── IPO VISIBILITY RULE (backend-enforced) ────────────────────────────────
/// The backend SQL query applies a two-tier visibility filter:
///
///   Public (any authenticated user can see):
///     open, closed, allocated, listed
///
///   Restricted (admin and owning company_rep only):
///     draft, submitted, under_review, approved, rejected, withdrawn
///
/// A restricted IPO returns the SAME 404 response as a non-existent IPO
/// to avoid leaking existence. The admin dashboard will always see
/// restricted IPOs because admin accounts have elevated access, but the
/// UI must handle 404 gracefully — it may mean "not found" OR "not visible
/// to your role". Do not assume a 404 always means the IPO does not exist.
/// ─────────────────────────────────────────────────────────────────────────
enum IpoStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  withdrawn,
  open,
  closed,
  allocated,
  listed,
}

extension IpoStatusLabel on IpoStatus {
  String get label {
    switch (this) {
      case IpoStatus.draft:
        return 'Draft';
      case IpoStatus.submitted:
        return 'Submitted';
      case IpoStatus.underReview:
        return 'Under Review';
      case IpoStatus.approved:
        return 'Approved';
      case IpoStatus.rejected:
        return 'Rejected';
      case IpoStatus.withdrawn:
        return 'Withdrawn';
      case IpoStatus.open:
        return 'Open';
      case IpoStatus.closed:
        return 'Closed';
      case IpoStatus.allocated:
        return 'Allocated';
      case IpoStatus.listed:
        return 'Listed';
    }
  }
}

class IpoApplication {
  const IpoApplication({
    required this.id,
    required this.offeringTitle,
    required this.companyId,
    required this.companyName,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.openDate,
    this.closeDate,
    this.pricePerShareSantim,
    this.totalSharesOffered,
    this.reviewNotes,
    this.documents = const [],
  });

  final String id;
  final String offeringTitle;
  final String companyId;
  final String companyName;
  final IpoStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? openDate;
  final DateTime? closeDate;

  /// Price per share in SANTIM (integer minor units). 100 santim = 1 ETB.
  /// Example: 50000 santim = ETB 500.00
  ///
  /// UNIT CONTRACT: backend sends santim, not whole ETB.
  /// Display using EtbFormatter.formatSantimOrFallback(pricePerShareSantim).
  /// Never display this raw integer directly as an ETB amount.
  ///
  /// Field name expected from backend: pricePerShareSantim (TBC with Member 2).
  /// Display only — authoritative value comes from the backend.
  final int? pricePerShareSantim;

  /// Total number of shares offered. This is a SHARE COUNT, not a monetary
  /// amount. Do not apply EtbFormatter to this field.
  final int? totalSharesOffered;
  final String? reviewNotes;
  final List<IpoDocumentMetadata> documents;

  factory IpoApplication.fromJson(Map<String, dynamic> json) {
    return IpoApplication(
      id: json['id'] as String,
      offeringTitle: json['offeringTitle'] as String? ??
          json['title'] as String? ??
          'Unnamed Offering',
      companyId: json['companyId'] as String? ??
          json['company_id'] as String? ??
          '',
      companyName: json['companyName'] as String? ??
          json['company_name'] as String? ??
          'Unknown Company',
      status: _parseStatus(json['status'] as String?),
      submittedAt: DateTime.tryParse(
              json['submittedAt'] as String? ?? json['created_at'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      openDate: json['openDate'] != null
          ? DateTime.tryParse(json['openDate'] as String)
          : (json['opens_at'] != null
              ? DateTime.tryParse(json['opens_at'] as String)
              : null),
      closeDate: json['closeDate'] != null
          ? DateTime.tryParse(json['closeDate'] as String)
          : (json['closes_at'] != null
              ? DateTime.tryParse(json['closes_at'] as String)
              : null),
      pricePerShareSantim: json['pricePerShareSantim'] as int? ??
          json['price_per_share_minor'] as int? ??
          json['pricePerShareEtb'] as int?,
      totalSharesOffered: json['totalSharesOffered'] as int? ??
          json['total_shares'] as int?,
      reviewNotes: json['reviewNotes'] as String?,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) =>
                  IpoDocumentMetadata.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static IpoStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'draft':
        return IpoStatus.draft;
      case 'submitted':
        return IpoStatus.submitted;
      case 'under_review':
        return IpoStatus.underReview;
      case 'approved':
        return IpoStatus.approved;
      case 'rejected':
        return IpoStatus.rejected;
      case 'withdrawn':
        return IpoStatus.withdrawn;
      case 'open':
        return IpoStatus.open;
      case 'closed':
        return IpoStatus.closed;
      case 'allocated':
        return IpoStatus.allocated;
      case 'listed':
        return IpoStatus.listed;
      default:
        return IpoStatus.submitted;
    }
  }

  /// Returns true if the Approve/Reject actions should be shown.
  /// In Phase 1, only Submitted and Under Review states are actionable.
  bool get isReviewable =>
      status == IpoStatus.submitted || status == IpoStatus.underReview;
}

class IpoDocumentMetadata {
  const IpoDocumentMetadata({
    required this.id,
    required this.name,
    required this.documentType,
    required this.reviewStatus,
    required this.submittedAt,
  });

  final String id;
  final String name;
  final String documentType;
  final String reviewStatus;
  final DateTime submittedAt;

  factory IpoDocumentMetadata.fromJson(Map<String, dynamic> json) {
    return IpoDocumentMetadata(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Document',
      documentType: json['documentType'] as String? ?? 'Unknown',
      reviewStatus: json['reviewStatus'] as String? ?? 'pending',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
