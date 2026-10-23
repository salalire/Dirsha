/// Represents a broker onboarding application awaiting admin review.
enum BrokerApplicationStatus {
  pending,
  underReview,
  additionalInfoRequired,
  approved,
  rejected,
}

extension BrokerApplicationStatusLabel on BrokerApplicationStatus {
  String get label {
    switch (this) {
      case BrokerApplicationStatus.pending:
        return 'Pending';
      case BrokerApplicationStatus.underReview:
        return 'Under Review';
      case BrokerApplicationStatus.additionalInfoRequired:
        return 'Info Required';
      case BrokerApplicationStatus.approved:
        return 'Approved';
      case BrokerApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}

class BrokerApplication {
  const BrokerApplication({
    required this.id,
    required this.applicantName,
    required this.applicantEmail,
    required this.brokerType,
    required this.licenseNumber,
    required this.licenseAuthority,
    required this.jurisdiction,
    required this.status,
    required this.submittedAt,
    this.firmName,
    this.licenseExpiryDate,
    this.isLicenseExpired = false,
    this.businessAddress,
    this.businessEmail,
    this.businessPhone,
    this.reviewedAt,
    this.reviewNotes,
    this.documents = const [],
  });

  final String id;
  final String applicantName;
  final String applicantEmail;
  final String brokerType; // 'firm' or 'individual'
  final String licenseNumber;
  final String licenseAuthority;
  final String jurisdiction;
  final BrokerApplicationStatus status;
  final DateTime submittedAt;
  final String? firmName;
  final DateTime? licenseExpiryDate;
  final bool isLicenseExpired;
  final String? businessAddress;
  final String? businessEmail;
  final String? businessPhone;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final List<BrokerDocumentMetadata> documents;

  String get displayName {
    if (firmName != null && firmName!.isNotEmpty) {
      if (applicantName.isNotEmpty &&
          applicantName != 'Unknown Applicant' &&
          applicantName != firmName) {
        return '$firmName ($applicantName)';
      }
      return firmName!;
    }
    return applicantName;
  }

  factory BrokerApplication.fromJson(Map<String, dynamic> json) {
    final expiryStr = json['license_expiry_date'] as String? ??
        json['licenseExpiryDate'] as String?;
    final expiryDate =
        expiryStr != null ? DateTime.tryParse(expiryStr) : null;
    final isExpired = json['is_license_expired'] as bool? ??
        (expiryDate != null && expiryDate.isBefore(DateTime.now()));

    return BrokerApplication(
      id: json['id'] as String,
      applicantName: json['representative_name'] as String? ??
          json['applicant_name'] as String? ??
          json['applicantName'] as String? ??
          json['owner_name'] as String? ??
          json['legal_name'] as String? ??
          'Unknown Applicant',
      applicantEmail: json['representative_email'] as String? ??
          json['applicant_email'] as String? ??
          json['applicantEmail'] as String? ??
          json['owner_email'] as String? ??
          json['business_email'] as String? ??
          '',
      brokerType: json['broker_type'] as String? ??
          json['brokerType'] as String? ??
          'firm',
      licenseNumber: json['license_number'] as String? ??
          json['licenseNumber'] as String? ??
          'N/A',
      licenseAuthority: json['licensing_authority'] as String? ??
          json['license_authority'] as String? ??
          json['licenseAuthority'] as String? ??
          'ECMA',
      jurisdiction: json['jurisdiction'] as String? ?? json['country'] as String? ?? 'ET',
      status: _parseStatus(json['onboarding_status'] as String? ?? json['status'] as String?),
      submittedAt: DateTime.tryParse(json['submitted_at'] as String? ??
              json['submittedAt'] as String? ??
              json['created_at'] as String? ??
              '') ??
          DateTime.now(),
      firmName: json['legal_name'] as String? ??
          json['trade_name'] as String? ??
          json['firm_name'] as String? ??
          json['firmName'] as String?,
      licenseExpiryDate: expiryDate,
      isLicenseExpired: isExpired,
      businessAddress: json['business_address'] as String? ??
          json['businessAddress'] as String?,
      businessEmail: json['business_email'] as String? ??
          json['businessEmail'] as String?,
      businessPhone: json['business_phone'] as String? ??
          json['businessPhone'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : json['reviewedAt'] != null
              ? DateTime.tryParse(json['reviewedAt'] as String)
              : null,
      reviewNotes: json['status_notes'] as String? ??
          json['review_notes'] as String? ??
          json['reviewNotes'] as String?,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) =>
                  BrokerDocumentMetadata.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static BrokerApplicationStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'submitted':
      case 'pending':
      case 'resubmitted':
        return BrokerApplicationStatus.pending;
      case 'under_review':
        return BrokerApplicationStatus.underReview;
      case 'additional_info_required':
        return BrokerApplicationStatus.additionalInfoRequired;
      case 'approved':
        return BrokerApplicationStatus.approved;
      case 'rejected':
        return BrokerApplicationStatus.rejected;
      default:
        return BrokerApplicationStatus.pending;
    }
  }
}

class BrokerDocumentMetadata {
  const BrokerDocumentMetadata({
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

  factory BrokerDocumentMetadata.fromJson(Map<String, dynamic> json) {
    return BrokerDocumentMetadata(
      id: json['id'] as String,
      name: json['file_name'] as String? ??
          json['original_filename'] as String? ??
          json['name'] as String? ??
          'Document',
      documentType: json['document_type'] as String? ??
          json['documentType'] as String? ??
          'Unknown',
      reviewStatus: json['review_status'] as String? ??
          json['reviewStatus'] as String? ??
          'pending',
      submittedAt: DateTime.tryParse(json['created_at'] as String? ??
              json['submittedAt'] as String? ??
              '') ??
          DateTime.now(),
      reviewNotes: json['review_notes'] as String? ??
          json['reviewNotes'] as String?,
      fileSize: (json['file_size_bytes'] is num
              ? (json['file_size_bytes'] as num).toInt()
              : int.tryParse(json['file_size_bytes']?.toString() ?? '')) ??
          (json['file_size'] is num
              ? (json['file_size'] as num).toInt()
              : int.tryParse(json['file_size']?.toString() ?? '')),
    );
  }
}
