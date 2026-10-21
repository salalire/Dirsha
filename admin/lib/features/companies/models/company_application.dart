/// Represents a company onboarding application awaiting admin review.
///
/// Field names are placeholders pending final agreement with Member 2.
/// Update fromJson() once the /admin/companies API contract is confirmed.
enum CompanyApplicationStatus {
  pending,
  underReview,
  approved,
  rejected,
  suspended,
}

extension CompanyApplicationStatusLabel on CompanyApplicationStatus {
  String get label {
    switch (this) {
      case CompanyApplicationStatus.pending:
        return 'Pending';
      case CompanyApplicationStatus.underReview:
        return 'Under Review';
      case CompanyApplicationStatus.approved:
        return 'Approved';
      case CompanyApplicationStatus.rejected:
        return 'Rejected';
      case CompanyApplicationStatus.suspended:
        return 'Suspended';
    }
  }
}

class CompanyApplication {
  const CompanyApplication({
    required this.id,
    required this.companyName,
    required this.representativeName,
    required this.representativeEmail,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
    this.documents = const [],
  });

  final String id;
  final String companyName;
  final String representativeName;
  final String representativeEmail;
  final CompanyApplicationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final List<DocumentMetadata> documents;

  factory CompanyApplication.fromJson(Map<String, dynamic> json) {
    return CompanyApplication(
      id: json['id'] as String,
      companyName: json['companyName'] as String? ??
          json['name'] as String? ??
          'Unknown Company',
      representativeName:
          json['representativeName'] as String? ?? 'Unknown',
      representativeEmail:
          json['representativeEmail'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      reviewNotes: json['reviewNotes'] as String?,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) =>
                  DocumentMetadata.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static CompanyApplicationStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'pending':
        return CompanyApplicationStatus.pending;
      case 'under_review':
        return CompanyApplicationStatus.underReview;
      case 'approved':
        return CompanyApplicationStatus.approved;
      case 'rejected':
        return CompanyApplicationStatus.rejected;
      case 'suspended':
        return CompanyApplicationStatus.suspended;
      default:
        return CompanyApplicationStatus.pending;
    }
  }
}

/// Metadata for a document associated with a company application.
/// The actual file is in private S3 storage — only metadata is displayed here.
class DocumentMetadata {
  const DocumentMetadata({
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

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentMetadata(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Document',
      documentType: json['documentType'] as String? ?? 'Unknown',
      reviewStatus: json['reviewStatus'] as String? ?? 'pending',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
