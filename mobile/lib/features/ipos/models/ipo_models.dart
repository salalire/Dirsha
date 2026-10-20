/// IPO-related data models for Dirsha.
///
/// Field names are based on the conceptual API contract in the SRS
/// (Sections 6.4, 8.3, and the suggested API domains).
///
/// DEPENDENCY ON MEMBER 2:
/// These models will be updated to match the exact JSON field names,
/// status enum values, and pagination shape once the API specification
/// is published. Do not assume the field names here are final.
///
/// Financial values:
/// All monetary amounts are represented as integers in minor units (cents)
/// OR as strings to avoid floating-point precision loss, per the SRS
/// (Section 9 data model note). The exact representation must be agreed
/// with Member 2. Currently modelled as strings that parse to double for
/// display only — never for calculation.
library;

/// An IPO as returned by GET /ipos (list) and GET /ipos/:id (detail).
///
/// Phase 1 displays only fields that are included in the agreed contract.
/// Optional fields are nullable — the UI must handle missing values
/// intentionally rather than crashing or displaying placeholders.
class IpoSummary {
  const IpoSummary({
    required this.id,
    required this.title,
    required this.companyName,
    required this.status,
    required this.pricePerShare,
    required this.currency,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.totalShares,
    this.availableShares,
    this.minInvestment,
    this.maxInvestment,
    this.logoUrl,
    this.shortDescription,
  });

  factory IpoSummary.fromJson(Map<String, dynamic> json) {
    return IpoSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      status: json['status'] as String,
      pricePerShare: json['pricePerShare'] as String,
      currency: json['currency'] as String? ?? 'ETB',
      subscriptionStartDate: _parseDate(json['subscriptionStartDate']),
      subscriptionEndDate: _parseDate(json['subscriptionEndDate']),
      totalShares: json['totalShares'] as int?,
      availableShares: json['availableShares'] as int?,
      minInvestment: json['minInvestment'] as String?,
      maxInvestment: json['maxInvestment'] as String?,
      logoUrl: json['logoUrl'] as String?,
      shortDescription: json['shortDescription'] as String?,
    );
  }

  final String id;
  final String title;
  final String companyName;

  /// Status from the agreed state machine:
  /// DRAFT | SUBMITTED | UNDER_REVIEW | APPROVED | OPEN | CLOSED |
  /// ALLOCATED | LISTED | REJECTED | WITHDRAWN
  final String status;

  /// Price per share as a string (e.g. "100.00") to avoid float precision
  /// loss. Parse to double only for display; never use for calculations.
  final String pricePerShare;
  final String currency;

  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final int? totalShares;
  final int? availableShares;
  final String? minInvestment;
  final String? maxInvestment;
  final String? logoUrl;
  final String? shortDescription;

  /// Whether the offering is currently accepting subscriptions.
  bool get isOpen => status == 'OPEN';

  /// Whether the offering has not yet started.
  bool get isUpcoming => status == 'APPROVED' || status == 'UPCOMING';

  static DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'companyName': companyName,
    'status': status,
    'pricePerShare': pricePerShare,
    'currency': currency,
    'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
    'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
    'totalShares': totalShares,
    'availableShares': availableShares,
    'minInvestment': minInvestment,
    'maxInvestment': maxInvestment,
    'logoUrl': logoUrl,
    'shortDescription': shortDescription,
  };
}

/// Extended IPO detail returned by GET /ipos/:id.
///
/// Includes all [IpoSummary] fields plus additional offering details.
class IpoDetail extends IpoSummary {
  const IpoDetail({
    required super.id,
    required super.title,
    required super.companyName,
    required super.status,
    required super.pricePerShare,
    required super.currency,
    super.subscriptionStartDate,
    super.subscriptionEndDate,
    super.totalShares,
    super.availableShares,
    super.minInvestment,
    super.maxInvestment,
    super.logoUrl,
    super.shortDescription,
    this.description,
    this.companyDescription,
    this.documents,
    this.riskDisclosure,
    this.subscribedShares,
    this.allocatedShares,
  });

  factory IpoDetail.fromJson(Map<String, dynamic> json) {
    final base = IpoSummary.fromJson(json);
    return IpoDetail(
      id: base.id,
      title: base.title,
      companyName: base.companyName,
      status: base.status,
      pricePerShare: base.pricePerShare,
      currency: base.currency,
      subscriptionStartDate: base.subscriptionStartDate,
      subscriptionEndDate: base.subscriptionEndDate,
      totalShares: base.totalShares,
      availableShares: base.availableShares,
      minInvestment: base.minInvestment,
      maxInvestment: base.maxInvestment,
      logoUrl: base.logoUrl,
      shortDescription: base.shortDescription,
      description: json['description'] as String?,
      companyDescription: json['companyDescription'] as String?,
      documents: _parseDocuments(json['documents']),
      riskDisclosure: json['riskDisclosure'] as String?,
      subscribedShares: json['subscribedShares'] as int?,
      allocatedShares: json['allocatedShares'] as int?,
    );
  }

  /// Full offering description / prospectus summary.
  final String? description;
  final String? companyDescription;
  final List<IpoDocument>? documents;

  /// Risk disclosure text — must be displayed when present.
  final String? riskDisclosure;

  /// Aggregate subscription data — only present when authorized and
  /// when the backend includes it for the requesting user's role.
  final int? subscribedShares;
  final int? allocatedShares;

  static List<IpoDocument>? _parseDocuments(dynamic value) {
    if (value is! List) return null;
    try {
      return value
          .whereType<Map<String, dynamic>>()
          .map(IpoDocument.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }
}

/// Metadata for a document attached to an IPO.
///
/// Actual file access requires an authorized presigned URL from the backend.
/// The mobile app must NOT construct S3 URLs or bypass the backend.
class IpoDocument {
  const IpoDocument({
    required this.id,
    required this.name,
    required this.type,
    this.uploadedAt,
  });

  factory IpoDocument.fromJson(Map<String, dynamic> json) {
    return IpoDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'DOCUMENT',
      uploadedAt: IpoSummary._parseDate(json['uploadedAt']),
    );
  }

  final String id;
  final String name;
  final String type;
  final DateTime? uploadedAt;
}

/// Paginated list response wrapper.
///
/// Shape matches the expected pagination format; update if Member 2
/// uses a different envelope (e.g. { data, meta } or { items, total }).
class PaginatedIpos {
  const PaginatedIpos({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedIpos.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? json['data'] as List? ?? [];
    return PaginatedIpos(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(IpoSummary.fromJson)
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  final List<IpoSummary> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;
}
