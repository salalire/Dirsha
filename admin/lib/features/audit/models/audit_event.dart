/// Represents a single audit log event.
///
/// Fields align with FR-ADM-03 from the SRS:
/// actor, action, target resource, timestamp, outcome, reference ID.
///
/// Endpoint: /admin/audit (not yet available — Phase 1 placeholder).
/// TODO (Member 2): Confirm /admin/audit endpoint path, pagination, and
/// field names before replacing the mock repository.
class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.actorRole,
    required this.action,
    required this.targetResource,
    required this.timestamp,
    required this.outcome,
    this.referenceId,
    this.actorId,
    this.metadata,
  });

  final String id;
  final String? actorId;
  final String actorRole;
  final String action;
  final String targetResource;
  final DateTime timestamp;
  final String outcome;
  final String? referenceId;
  final Map<String, dynamic>? metadata;

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'] as String,
      actorId: json['actorId'] as String? ?? json['actor_user_id'] as String?,
      actorRole: json['actorRole'] as String? ?? json['actor_role'] as String? ?? 'admin',
      action: json['action'] as String? ?? 'unknown',
      targetResource: json['targetResource'] as String? ??
          (json['target_type'] != null
              ? '${json['target_type']}:${json['target_id'] ?? ''}'
              : (json['target_id'] as String? ?? '')),
      timestamp: DateTime.tryParse(
              json['timestamp'] as String? ?? json['created_at'] as String? ?? '') ??
          DateTime.now(),
      outcome: json['outcome'] as String? ?? 'unknown',
      referenceId: json['referenceId'] as String? ?? json['request_id'] as String?,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }
}
