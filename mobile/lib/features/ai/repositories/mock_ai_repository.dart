import '../models/ai_models.dart';
import 'ai_repository.dart';

/// Offline educational answers for Flutter mock mode.
///
/// This is not Gemini. It exists so chat works without a backend.
class MockAiRepository implements AiRepository {
  static const _delay = Duration(milliseconds: 350);

  @override
  Future<AiAnswer> ask({
    required String message,
    required String language,
    String? ipoId,
    List<ChatMessage> history = const [],
  }) async {
    await Future<void>.delayed(_delay);
    final detected = RegExp(r'[\u1200-\u137f]').hasMatch(message)
        ? 'am'
        : language;
    final lower = message.toLowerCase();

    if (RegExp(
      r'\b(buy|sell|purchase|subscribe|transfer|withdraw)\b',
      caseSensitive: false,
    ).hasMatch(message)) {
      return AiAnswer(
        answer: detected == 'am'
            ? 'መግዛት፣ መሸጥ፣ መመዝገብ ወይም ገንዘብ ማስተላለፍ አልችልም። እባክዎ መደበኛውን የመተግበሪያ መንገድ ይጠቀሙ።'
            : 'I cannot buy, sell, subscribe, or transfer funds. Please use the normal in-app flow for actions.',
        language: detected,
        grounded: false,
        sources: const [],
        disclaimer: AiAnswer.disclaimerFor(detected),
        simulated: true,
      );
    }

    if (RegExp(
      r"\b(my wallet|wallet balance|another user's wallet)\b",
      caseSensitive: false,
    ).hasMatch(message)) {
      return AiAnswer(
        answer: detected == 'am'
            ? 'የቦርሳ ቀሪ ሂሳብ ወይም ሌላ የግል መረጃ ማግኘት አልችልም።'
            : 'I cannot access wallet balances or other private account data.',
        language: detected,
        grounded: false,
        sources: const [],
        disclaimer: AiAnswer.disclaimerFor(detected),
        simulated: true,
      );
    }

    if (ipoId != null && ipoId.isNotEmpty) {
      return AiAnswer(
        answer: detected == 'am'
            ? 'ከDirsha መረጃ: ይህ የአክሲዮን መግለጫ ነው። ዋጋው እና ቀኖቹ በዝርዝር ገጹ ላይ ይታያሉ።\n\nአጠቃላይ ማብራሪያ: IPO ማለት ኩባንያ ለመጀመሪያ ጊዜ አክሲዮን ለሕዝብ ሲያቀርብ ነው።'
            : 'From Dirsha data: offer price, share count, and dates are shown on the IPO detail screen.\n\nGeneral explanation: An IPO is when a company offers shares to the public for the first time.',
        language: detected,
        grounded: true,
        sources: [
          AiSource(
            label: 'IPO Prospectus',
            type: 'ipo',
            ipoId: ipoId,
            asOf: DateTime.now().toUtc(),
          ),
        ],
        disclaimer: AiAnswer.disclaimerFor(detected),
        simulated: false,
      );
    }

    final isGlossaryQuestion =
        RegExp(
          r'\b(ipo|offer price|oversubscription|allocation|shares?|subscription|listing|prospectus|dividend)\b',
          caseSensitive: false,
        ).hasMatch(message) ||
        message.contains('አክሲዮን');
    final glossary = detected == 'am'
        ? 'IPO (የመጀመሪያ የሕዝብ የአክሲዮን ሽያጭ) ኩባንያ ለመጀመሪያ ጊዜ አክሲዮኖችን ለሕዝብ ሲያቀርብ ነው። የአቅርቦት ዋጋ የአንድ አክሲዮን ዋጋ ነው። ከመጠን በላይ መመዝገብ ማለት ከቀረበው በላይ ጥያቄ መኖር ነው። ይህ አጠቃላይ ማብራሪያ ነው።'
        : 'An IPO (initial public offering) is when a company offers shares to the public for the first time. An offer price is the stated price per share. Oversubscription means more shares are requested than offered. Allocation is how offered shares are distributed. This is a general explanation.';

    return AiAnswer(
      answer: !isGlossaryQuestion
          ? (detected == 'am'
                ? 'ይህ ረዳት ስለ Dirsha፣ IPO እና አጠቃላይ የኢንቨስትመንት ቃላት ሊያብራራ ይችላል። እባክዎ ጥያቄዎን በዚህ ዘርፍ ያቅርቡ።'
                : 'I can help with Dirsha, IPOs, and general investing terminology. Please ask a question in that area.')
          : lower.contains('oversubscription')
          ? (detected == 'am'
                ? 'ከመጠን በላይ መመዝገብ (oversubscription) ማለት ከቀረቡት አክሲዮኖች በላይ ጥያቄ ሲኖር ነው።'
                : 'Oversubscription means investors request more shares than the company offered. Extra demand is then allocated by the stated rules.')
          : glossary,
      language: detected,
      grounded: false,
      sources: const [],
      disclaimer: AiAnswer.disclaimerFor(detected),
      simulated: true,
    );
  }
}
