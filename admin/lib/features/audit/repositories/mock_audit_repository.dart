// ⚠️  DEVELOPMENT MOCK DATA — NOT REAL AUDIT RECORDS
//
// This page is a PLACEHOLDER. No real audit events exist yet because the
// /admin/audit endpoint has not been implemented by Member 2.
//
// BLOCKER: /admin/audit endpoint — owner: Member 2 (backend).
// Replace this with ApiAuditRepository once the endpoint is ready.

import '../models/audit_event.dart';
import 'audit_repository.dart';

class MockAuditRepository implements AuditRepository {
  @override
  Future<List<AuditEvent>> getRecentEvents({int limit = 50}) async {
    // Return empty list — the UI should show a placeholder/empty state
    // rather than invented audit records.
    await Future.delayed(const Duration(milliseconds: 400));
    return [];
  }
}
