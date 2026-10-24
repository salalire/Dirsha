import '../models/portfolio_models.dart';

abstract interface class PortfolioRepository {
  Future<PortfolioModel> getPortfolio();
}
