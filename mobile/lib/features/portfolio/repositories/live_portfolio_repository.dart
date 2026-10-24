import '../../../core/network/api_client.dart';
import '../models/portfolio_models.dart';
import 'portfolio_repository.dart';

class LivePortfolioRepository implements PortfolioRepository {
  const LivePortfolioRepository({required ApiClient apiClient})
      : _client = apiClient;

  final ApiClient _client;

  @override
  Future<PortfolioModel> getPortfolio() async {
    final response = await _client.get('/portfolio');
    final data = response['data'] as Map<String, dynamic>;
    return PortfolioModel.fromJson(data);
  }
}
