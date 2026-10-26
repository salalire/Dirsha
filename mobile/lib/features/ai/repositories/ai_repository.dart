import '../models/ai_models.dart';

abstract interface class AiRepository {
  Future<AiAnswer> ask({
    required String message,
    required String language,
    String? ipoId,
    List<ChatMessage> history = const [],
  });
}
