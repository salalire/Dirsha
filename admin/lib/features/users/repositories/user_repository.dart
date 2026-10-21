import '../models/user_application.dart';

/// Abstract repository interface for user/investor applications.
///
/// The UI depends only on this interface.
/// Switch between [MockUserRepository] and [ApiUserRepository] by
/// injecting the appropriate implementation.
abstract class UserRepository {
  Future<List<UserApplication>> getApplications();
  Future<UserApplication> getApplicationById(String id);
  Future<void> approveApplication(String id, {String? notes});
  Future<void> rejectApplication(String id, {required String reason});
}
