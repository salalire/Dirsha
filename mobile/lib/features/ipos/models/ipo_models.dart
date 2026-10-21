/// IPO-related data models for Dirsha.
///
/// Monetary contract (confirmed by Member 2):
///   All ETB amounts are integer santim in the live API.
///   1 ETB = 100 santim. Example: price_per_share_minor = 10000 → ETB 100.00
///
///   [Money] is used for all monetary fields. [Money.fromJson] accepts
///   both integer santim (live API) and decimal ETB strings (mock data),
///   so existing tested mock behavior is preserved without changes.
///
/// DEPENDENCY ON MEMBER 2:
///   Confirm final JSON field names — especially whether santim fields
///   use the _minor suffix (e.g. price_per_share_minor) or camelCase
///   (e.g. pricePerShareMinor). Update fromJson keys when confirmed.
library;

import 'package:dirsha_mobile/core/money/money.dart';

/// An IPO as returned by GET /ipos (list) and GET /ipos/:id (detail).
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
      // Accepts price_per_share_minor (santim int) or pricePerShare (legacy
      // string e.g. "100.00"). Money.fromJson handles both correctly.
      pricePerShare: Money.fromJson(
        json['price_per_share_minor'] ?? json['pricePerShare'],
      ),
      currency: json['currency'] as String? ?? 'ETB',
      subscriptionStartDate: _parseDate(json['subscriptionStartDate']),
      subscriptionEndDate: _parseDate(json['subscriptionEndDate']),
      totalShares: json['totalShares'] as int?,
      availableShares: json['availableShares'] as int?,
      // Optional monetary fields — null when not provided.
      minInvestment:
          (json['min_investment_minor'] ?? json['minInvestment']) != null
          ? Money.fromJson(
              json['min_investment_minor'] ?? json['minInvestment'],
            )
          : null,
      maxInvestment:
          (json['max_investment_minor'] ?? json['maxInvestment']) != null
          ? Money.fromJson(
              json['max_investment_minor'] ?? json['maxInvestment'],
            )
          : null,
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

  /// Price per share in santim. Use [Formatters.money] for display.
  final Money pricePerShare;
  final String currency;

  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final int? totalShares;
  final int? availableShares;

  /// Minimum subscription amount in santim. Null when not specified.
  final Money? minInvestment;

  /// Maximum subscription amount in santim. Null when not specified.
  final Money? maxInvestment;

  final String? logoUrl;
  final String? shortDescription;

  bool get isOpen => status == 'OPEN';
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
    'price_per_share_minor': pricePerShare.santim,
    'currency': currency,
    'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
    'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
    'totalShares': totalShares,
    'availableShares': availableShares,
    'min_investment_minor': minInvestment?.santim,
    'max_investment_minor': maxInvestment?.santim,
    'logoUrl': logoUrl,
    'shortDescription': shortDescription,
  };
}

/// Extended IPO detail returned by GET /ipos/:id.
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

  final String? description;
  final String? companyDescription;
  final List<IpoDocument>? documents;

  /// Risk disclosure text — must be displayed when present.
  final String? riskDisclosure;

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
