import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/ipo_models.dart';
import 'ipo_repository.dart';

/// Live implementation of [IpoRepository].
///
/// STATUS: Inactive. Replaces [MockIpoRepository] once:
///   1. Member 2 confirms endpoint paths and response schemas.
///   2. GET /ipos and GET /ipos/:id are deployed and reachable.
///   3. [AppConfig.useMockRepositories] is set to false.
///
/// DEPENDENCY ON MEMBER 2:
///   - Confirm pagination envelope shape (items/data, total, page, pageSize).
///   - Confirm all IPO status enum values.
///   - Confirm monetary field representation (string vs integer minor units).
///   - Confirm whether GET /ipos/:id includes document metadata.
class LiveIpoRepository implements IpoRepository {
  const LiveIpoRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<PaginatedIpos> getIpos({int page = 1, int pageSize = 20}) async {
    final data = await _client.get<Map<String, dynamic>?>(
      '/ipos',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    if (data == null) {
      throw const ParseException(message: 'IPO list response was empty.');
    }
    try {
      return PaginatedIpos.fromJson(data);
    } catch (e) {
      throw ParseException(message: 'Could not parse IPO list.', cause: e);
    }
  }

  @override
  Future<IpoDetail> getIpoById(String id) async {
    final data = await _client.get<Map<String, dynamic>?>('/ipos/$id');
    if (data == null) {
      throw const ParseException(message: 'IPO detail response was empty.');
    }
    try {
      return IpoDetail.fromJson(data);
    } catch (e) {
      throw ParseException(message: 'Could not parse IPO detail.', cause: e);
    }
  }
}
