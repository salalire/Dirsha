import '../models/subscription_model.dart';
import 'subscription_repository.dart';

class MockSubscriptionsRepository implements SubscriptionsRepository {
  MockSubscriptionsRepository({List<AdminSubscription>? initialData})
      : _subscriptions = initialData ?? _seedSubscriptions();

  final List<AdminSubscription> _subscriptions;

  static List<AdminSubscription> _seedSubscriptions() {
    return [
      AdminSubscription(
        id: 'sub-mock-001',
        ipoId: 'ipo-ethio-telecom-001',
        offeringTitle: 'Ethio Telecom Class A Shares',
        symbol: 'ETHTEL',
        companyName: 'Ethio Telecom SC',
        investorId: 'usr-inv-001',
        investorName: 'Abebe Bikila',
        investorEmail: 'abebe.bikila@example.com',
        quantity: 25,
        sharePriceMinor: 30000,
        totalAmountMinor: 750000,
        allocatedQuantity: 0,
        status: AdminSubscriptionStatus.reserved,
        idempotencyKey: 'idem-mock-001',
        createdAt: DateTime.parse('2026-03-24T09:30:00Z'),
      ),
      AdminSubscription(
        id: 'sub-mock-002',
        ipoId: 'ipo-ethio-telecom-001',
        offeringTitle: 'Ethio Telecom Class A Shares',
        symbol: 'ETHTEL',
        companyName: 'Ethio Telecom SC',
        investorId: 'usr-inv-002',
        investorName: 'Almaz Ayana',
        investorEmail: 'almaz.ayana@example.com',
        quantity: 50,
        sharePriceMinor: 30000,
        totalAmountMinor: 1500000,
        allocatedQuantity: 50,
        status: AdminSubscriptionStatus.settled,
        idempotencyKey: 'idem-mock-002',
        createdAt: DateTime.parse('2026-03-23T11:15:00Z'),
        allocatedAt: DateTime.parse('2026-03-25T14:00:00Z'),
      ),
      AdminSubscription(
        id: 'sub-mock-003',
        ipoId: 'ipo-ethio-telecom-001',
        offeringTitle: 'Ethio Telecom Class A Shares',
        symbol: 'ETHTEL',
        companyName: 'Ethio Telecom SC',
        investorId: 'usr-inv-003',
        investorName: 'Kenenisa Bekele',
        investorEmail: 'kenenisa.bekele@example.com',
        quantity: 100,
        sharePriceMinor: 30000,
        totalAmountMinor: 3000000,
        allocatedQuantity: 40,
        status: AdminSubscriptionStatus.settled,
        idempotencyKey: 'idem-mock-003',
        createdAt: DateTime.parse('2026-03-22T14:45:00Z'),
        allocatedAt: DateTime.parse('2026-03-25T14:00:00Z'),
      ),
      AdminSubscription(
        id: 'sub-mock-004',
        ipoId: 'ipo-awash-bank-002',
        offeringTitle: 'Awash Bank Expansion 2026',
        symbol: 'AWASH',
        companyName: 'Awash International Bank SC',
        investorId: 'usr-inv-004',
        investorName: 'Derartu Tulu',
        investorEmail: 'derartu.tulu@example.com',
        quantity: 10,
        sharePriceMinor: 50000,
        totalAmountMinor: 500000,
        allocatedQuantity: 0,
        status: AdminSubscriptionStatus.reserved,
        idempotencyKey: 'idem-mock-004',
        createdAt: DateTime.parse('2026-03-24T16:20:00Z'),
      ),
    ];
  }

  @override
  Future<List<AdminSubscription>> getSubscriptions({
    String? ipoId,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var result = List<AdminSubscription>.from(_subscriptions);

    if (ipoId != null && ipoId.isNotEmpty) {
      result = result.where((s) => s.ipoId == ipoId).toList();
    }
    if (status != null && status.isNotEmpty) {
      result = result
          .where((s) => s.status.name.toLowerCase() == status.toLowerCase())
          .toList();
    }
    return result;
  }

  @override
  Future<AdminSubscription> getSubscriptionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final match = _subscriptions.where((s) => s.id == id);
    if (match.isEmpty) {
      throw Exception('Subscription not found with ID $id');
    }
    return match.first;
  }
}
