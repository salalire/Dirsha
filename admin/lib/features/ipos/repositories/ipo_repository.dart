import '../models/ipo_application.dart';

/// Abstract repository interface for IPO applications.
abstract class IpoRepository {
  Future<List<IpoApplication>> getApplications();
  Future<IpoApplication> getApplicationById(String id);

  /// Approve an IPO application.
  /// [notes] is optional. The backend may require a reason — coordinate
  /// with Member 2 on whether notes are required for approval.
  Future<void> approveApplication(String id, {String? notes});

  /// Reject an IPO application.
  /// [reason] is required — the company needs to know what to fix.
  Future<void> rejectApplication(String id, {required String reason});
}
