import '../models/broker_application.dart';

/// Abstract repository interface for broker onboarding applications.
abstract class BrokerRepository {
  Future<List<BrokerApplication>> getApplications();
  Future<BrokerApplication> getApplicationById(String id);
  Future<void> approveApplication(String id, {String? notes});
  Future<void> rejectApplication(String id, {required String reason});
  Future<void> requestAdditionalInfo(String id, {required String message});
  Future<void> reviewDocument(String documentId, {required String status, String? notes});
}
