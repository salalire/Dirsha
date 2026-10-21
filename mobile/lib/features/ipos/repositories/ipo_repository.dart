import '../models/ipo_models.dart';

/// Contract for IPO data operations.
///
/// Implementations:
/// - [MockIpoRepository]  — deterministic in-memory mock for development.
/// - [LiveIpoRepository]  — calls GET /ipos and GET /ipos/:id (inactive
///                          until the API contract is confirmed).
abstract interface class IpoRepository {
  /// Returns a paginated list of IPOs.
  Future<PaginatedIpos> getIpos({int page = 1, int pageSize = 20});

  /// Returns full detail for a single IPO.
  Future<IpoDetail> getIpoById(String id);
}
