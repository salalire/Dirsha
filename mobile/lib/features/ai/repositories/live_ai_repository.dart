import '../../../core/network/api_client.dart';
import '../models/ai_models.dart';
import 'ai_repository.dart';

class LiveAiRepository implements AiRepository {
  LiveAiRepository({required this.apiClient});
  final ApiClient apiClient;
  @override
  Future<AiAnswer> ask({
    required String message,
    required String language,
    String? ipoId,
    List<ChatMessage> history = const [],
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/ai/chat',
      data: {
        'message': message,
        'language': language,
        'ipo_id': ?ipoId,
        'history': history
            .take(6)
            .map(
              (item) => {
                'role': item.isUser ? 'user' : 'assistant',
                'content': item.content,
              },
            )
            .toList(),
      },
    );
    return AiAnswer.fromJson(response);
  }
}
