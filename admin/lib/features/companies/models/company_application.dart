/// Represents a company onboarding application awaiting admin review.
enum CompanyApplicationStatus {
  pending,
  underReview,
  additionalInfoRequired,
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
      case CompanyApplicationStatus.additionalInfoRequired:
        return 'Info Required';
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
    this.registrationNumber,
    this.tin,
    this.legalEntityType,
    this.sector,
    this.businessAddress,
    this.businessEmail,
    this.businessPhone,
    this.website,
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
  final String? registrationNumber;
  final String? tin;
  final String? legalEntityType;
  final String? sector;
  final String? businessAddress;
  final String? businessEmail;
  final String? businessPhone;
  final String? website;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final List<DocumentMetadata> documents;

  factory CompanyApplication.fromJson(Map<String, dynamic> json) {
    return CompanyApplication(
      id: json['id'] as String,
      companyName: json['legal_name'] as String? ??
          json['trade_name'] as String? ??
          json['companyName'] as String? ??
          json['name'] as String? ??
          'Unknown Company',
      representativeName: json['representative_name'] as String? ??
          json['representativeName'] as String? ??
          json['authorized_rep_name'] as String? ??
          json['owner_name'] as String? ??
          'Unknown',
      representativeEmail: json['representative_email'] as String? ??
          json['representativeEmail'] as String? ??
          json['authorized_rep_email'] as String? ??
          json['owner_email'] as String? ??
          '',
      status: _parseStatus(json['onboarding_status'] as String? ?? json['status'] as String?),
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ??
              json['submitted_at'] as String? ??
              json['created_at'] as String? ??
              '') ??
          DateTime.now(),
      registrationNumber: json['registrationNumber'] as String? ??
          json['registration_number'] as String?,
      tin: json['tin'] as String?,
      legalEntityType: json['legalEntityType'] as String? ??
          json['legal_entity_type'] as String?,
      sector: json['sector'] as String? ?? json['industry_sector'] as String?,
      businessAddress: json['businessAddress'] as String? ??
          json['registered_address'] as String? ??
          json['business_address'] as String?,
      businessEmail: json['businessEmail'] as String? ??
          json['business_email'] as String?,
      businessPhone: json['businessPhone'] as String? ??
          json['business_phone'] as String?,
      website: json['website'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : json['reviewed_at'] != null
              ? DateTime.tryParse(json['reviewed_at'] as String)
              : null,
      reviewNotes: json['reviewNotes'] as String? ??
          json['status_notes'] as String? ??
          json['review_notes'] as String?,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) =>
                  DocumentMetadata.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static CompanyApplicationStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'submitted':
      case 'pending':
      case 'resubmitted':
        return CompanyApplicationStatus.pending;
      case 'under_review':
        return CompanyApplicationStatus.underReview;
      case 'additional_info_required':
        return CompanyApplicationStatus.additionalInfoRequired;
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
/// The actual file is in private storage — only metadata is displayed here.
class DocumentMetadata {
  const DocumentMetadata({
    required this.id,
    required this.name,
    required this.documentType,
    required this.reviewStatus,
    required this.submittedAt,
    this.reviewNotes,
    this.fileSize,
  });

  final String id;
  final String name;
  final String documentType;
  final String reviewStatus;
  final DateTime submittedAt;
  final String? reviewNotes;
  final int? fileSize;

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentMetadata(
      id: json['id'] as String,
      name: json['file_name'] as String? ??
          json['name'] as String? ??
          json['original_filename'] as String? ??
          'Document',
      documentType: json['document_type'] as String? ??
          json['documentType'] as String? ??
          'Unknown',
      reviewStatus: json['review_status'] as String? ??
          json['reviewStatus'] as String? ??
          'pending',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ??
              json['created_at'] as String? ??
              '') ??
          DateTime.now(),
      reviewNotes: json['reviewNotes'] as String? ??
          json['review_notes'] as String?,
      fileSize: (json['file_size_bytes'] is num
              ? (json['file_size_bytes'] as num).toInt()
              : int.tryParse(json['file_size_bytes']?.toString() ?? '')) ??
          (json['file_size'] is num
              ? (json['file_size'] as num).toInt()
              : int.tryParse(json['file_size']?.toString() ?? '')),
    );
  }
}
