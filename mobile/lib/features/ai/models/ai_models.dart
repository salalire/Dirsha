class AiSource {
  const AiSource({
    required this.label,
    required this.type,
    required this.ipoId,
    required this.asOf,
  });

  final String label;
  final String type;
  final String ipoId;
  final DateTime asOf;

  factory AiSource.fromJson(Map<String, dynamic> json) => AiSource(
    label: json['label'] as String? ?? 'Dirsha data',
    type: json['type'] as String? ?? 'ipo',
    ipoId: json['ipo_id'] as String? ?? '',
    asOf: DateTime.tryParse(json['as_of'] as String? ?? '') ?? DateTime.now(),
  );
}

class AiAnswer {
  const AiAnswer({
    required this.answer,
    required this.language,
    required this.grounded,
    required this.sources,
    required this.disclaimer,
    required this.simulated,
  });

  final String answer;
  final String language;
  final bool grounded;
  final List<AiSource> sources;
  final String disclaimer;
  final bool simulated;

  static String disclaimerFor(String language) => language == 'am'
      ? 'ይህ መረጃ ለትምህርት ብቻ ነው። ሙሉ ወይም ትክክለኛ ላይሆን ይችላል፤ የገንዘብ ምክር አይደለም።'
      : 'Educational information only. It may be incomplete or wrong and is not financial advice.';

  factory AiAnswer.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map)
        ? (json['data'] as Map).cast<String, dynamic>()
        : json;
    return AiAnswer(
      answer: data['answer'] as String? ?? '',
      language: data['language'] as String? ?? 'en',
      grounded: data['grounded'] as bool? ?? false,
      sources: ((data['sources'] as List?) ?? const [])
          .map((e) => AiSource.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      disclaimer:
          data['disclaimer'] as String? ??
          disclaimerFor(data['language'] as String? ?? 'en'),
      simulated: data['simulated'] as bool? ?? false,
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.content, required this.isUser, this.answer});

  final String content;
  final bool isUser;
  final AiAnswer? answer;

  ChatMessage copyWith({String? content, AiAnswer? answer}) => ChatMessage(
    content: content ?? this.content,
    isUser: isUser,
    answer: answer ?? this.answer,
  );
}
