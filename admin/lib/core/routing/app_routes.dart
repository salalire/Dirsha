/// Route path constants for the entire admin app.
/// All navigation uses these constants — no magic strings in screen files.
abstract final class AppRoutes {
  static const String signIn = '/sign-in';
  static const String dashboard = '/dashboard';
  static const String userReviews = '/user-reviews';
  static const String userDetail = '/user-reviews/:id';
  static const String companyReviews = '/company-reviews';
  static const String companyDetail = '/company-reviews/:id';
  static const String brokerReviews = '/broker-reviews';
  static const String brokerDetail = '/broker-reviews/:id';
  static const String ipoManagement = '/ipo-management';
  static const String ipoDetail = '/ipo-management/:id';
  static const String audit = '/audit';

  /// Helper: build a user detail path with a real ID.
  static String userDetailPath(String id) => '/user-reviews/$id';

  /// Helper: build a company detail path with a real ID.
  static String companyDetailPath(String id) => '/company-reviews/$id';

  /// Helper: build a broker detail path with a real ID.
  static String brokerDetailPath(String id) => '/broker-reviews/$id';

  /// Helper: build an IPO detail path with a real ID.
  static String ipoDetailPath(String id) => '/ipo-management/$id';
}
