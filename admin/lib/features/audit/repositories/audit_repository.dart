import '../models/audit_event.dart';

/// Abstract repository interface for audit/activity events.
///
/// DEPENDENCY: /admin/audit endpoint (Member 2 — not yet available in Phase 1).
/// The UI will use MockAuditRepository until the endpoint is confirmed.
abstract class AuditRepository {
  Future<List<AuditEvent>> getRecentEvents({int limit = 50});
}
