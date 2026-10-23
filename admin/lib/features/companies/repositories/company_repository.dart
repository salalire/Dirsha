import '../models/company_application.dart';

/// Abstract repository interface for company onboarding applications.
abstract class CompanyRepository {
  Future<List<CompanyApplication>> getApplications();
  Future<CompanyApplication> getApplicationById(String id);
  Future<void> approveApplication(String id, {String? notes});
  Future<void> rejectApplication(String id, {required String reason});
  Future<void> requestAdditionalInfo(String id, {required String message});
  Future<void> reviewDocument(String documentId, {required String status, String? notes});
}
