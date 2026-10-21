// ⚠️  DEVELOPMENT MOCK DATA — NOT REAL USER RECORDS
//
// These are entirely fictional names and emails created for UI testing only.
// They do not represent real people and are not derived from any user database.
// Replace with ApiUserRepository once Member 2's /admin/users endpoint is ready.
//
// Mock records intentionally show a variety of realistic combinations:
// - active account + unverified (common: user registered but not yet verified)
// - active account + pending verification (verification submitted, not decided)
// - active account + verified (normal approved state)
// - rejected application (account not active)
// - pending application (account not yet active)
//
// ⚠️  B3 PENDING: Whether verification is required for investing is not yet
// agreed. These records show verificationStatus for display/testing only.
// No regulated identity-verification process exists in the system yet.

import '../models/user_application.dart';
import 'user_repository.dart';

class MockUserRepository implements UserRepository {
  final List<UserApplication> _data = [
    UserApplication(
      id: 'usr-001',
      displayName: 'Abebe Girma',
      email: 'abebe.girma@example.dev',
      role: UserRole.investor,
      accountStatus: UserAccountStatus.active,
      verificationStatus: UserVerificationStatus.unverified,
      status: UserApplicationStatus.pending,
      submittedAt: DateTime(2026, 10, 18),
    ),
    UserApplication(
      id: 'usr-002',
      displayName: 'Tigist Haile',
      email: 'tigist.haile@example.dev',
      role: UserRole.investor,
      accountStatus: UserAccountStatus.active,
      verificationStatus: UserVerificationStatus.pending,
      status: UserApplicationStatus.underReview,
      submittedAt: DateTime(2026, 10, 17),
    ),
    UserApplication(
      id: 'usr-003',
      displayName: 'Yonas Tesfaye',
      email: 'yonas.t@example.dev',
      role: UserRole.investor,
      accountStatus: UserAccountStatus.active,
      verificationStatus: UserVerificationStatus.unverified,
      status: UserApplicationStatus.approved,
      submittedAt: DateTime(2026, 10, 15),
      reviewedAt: DateTime(2026, 10, 16),
    ),
    UserApplication(
      id: 'usr-004',
      displayName: 'Mekdes Alemu',
      email: 'mekdes.a@example.dev',
      role: UserRole.investor,
      accountStatus: UserAccountStatus.active,
      verificationStatus: UserVerificationStatus.unverified,
      status: UserApplicationStatus.rejected,
      submittedAt: DateTime(2026, 10, 14),
      reviewedAt: DateTime(2026, 10, 15),
      reviewNotes: 'Incomplete documentation submitted.',
    ),
    UserApplication(
      id: 'usr-005',
      displayName: 'Dawit Bekele',
      email: 'dawit.b@example.dev',
      role: UserRole.companyRep,
      accountStatus: UserAccountStatus.active,
      verificationStatus: UserVerificationStatus.unverified,
      status: UserApplicationStatus.pending,
      submittedAt: DateTime(2026, 10, 19),
    ),
  ];

  @override
  Future<List<UserApplication>> getApplications() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_data);
  }

  @override
  Future<UserApplication> getApplicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _data.firstWhere(
      (u) => u.id == id,
      orElse: () => throw Exception('User application not found: $id'),
    );
  }

  @override
  Future<void> approveApplication(String id, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final idx = _data.indexWhere((u) => u.id == id);
    if (idx == -1) throw Exception('User application not found: $id');
    _data[idx] = UserApplication(
      id: _data[idx].id,
      displayName: _data[idx].displayName,
      email: _data[idx].email,
      role: _data[idx].role,
      accountStatus: _data[idx].accountStatus,
      verificationStatus: _data[idx].verificationStatus,
      status: UserApplicationStatus.approved,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: notes,
    );
  }

  @override
  Future<void> rejectApplication(String id, {required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final idx = _data.indexWhere((u) => u.id == id);
    if (idx == -1) throw Exception('User application not found: $id');
    _data[idx] = UserApplication(
      id: _data[idx].id,
      displayName: _data[idx].displayName,
      email: _data[idx].email,
      role: _data[idx].role,
      accountStatus: _data[idx].accountStatus,
      verificationStatus: _data[idx].verificationStatus,
      status: UserApplicationStatus.rejected,
      submittedAt: _data[idx].submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: reason,
    );
  }
}
