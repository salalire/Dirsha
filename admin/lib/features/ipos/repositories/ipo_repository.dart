import '../models/ipo_application.dart';

/// Abstract repository interface for IPO applications.
abstract class IpoRepository {
  Future<List<IpoApplication>> getApplications();
  Future<IpoApplication> getApplicationById(String id);

  /// Approve an IPO application.
  /// [notes] is optional. [openImmediately] will advance the opening date
  /// and open subscriptions immediately if requested.
  Future<void> approveApplication(String id,
      {String? notes, bool openImmediately = false});

  /// Reject an IPO application.
  /// [reason] is required — the company needs to know what to fix.
  Future<void> rejectApplication(String id, {required String reason});

  /// Open subscriptions for an approved IPO.
  Future<void> openIpo(String id, {String? reason});

  /// Close the subscription window for an open IPO.
  Future<void> closeIpo(String id, {String? reason});

  /// Run pro-rata share allocation for a closed or open IPO.
  Future<void> allocateIpo(String id);

  /// Transition an allocated IPO to listed for secondary-market trading.
  Future<void> listIpo(String id, {String? reason});
}
