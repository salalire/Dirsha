import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/utils/formatters.dart';
import '../providers/ai_chat_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.ipoId});

  final String? ipoId;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiChatProvider>().setIpo(widget.ipoId);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    _input.clear();
    context.read<AiChatProvider>().send(text);
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Dirsha AI'),
        actions: [
          Consumer<AiChatProvider>(
            builder: (context, provider, child) => PopupMenuButton<String>(
              initialValue: provider.language,
              onSelected: provider.setLanguage,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'en', child: Text('English')),
                PopupMenuItem(value: 'am', child: Text('አማርኛ')),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.read<AiChatProvider>().clear(),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Consumer<AiChatProvider>(
        builder: (context, provider, _) {
          _scrollToLatest();
          return Column(
            children: [
              if (AppConfig.useMockRepositories && !AppConfig.isProduction)
                const MockDataBanner(
                  detail:
                      'Mock AI answers — not Gemini and not live market data.',
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return Align(
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 360),
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? AppColors.brandEmerald
                              : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: message.isUser
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.content,
                              style: AppTextStyles.bodyMedium,
                            ),
                            if (!message.isUser && message.answer != null) ...[
                              const SizedBox(height: 6),
                              if (message.answer!.grounded)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    for (final source
                                        in message.answer!.sources)
                                      Chip(
                                        label: Text(
                                          '${source.label} · ${Formatters.relativeDate(source.asOf)}',
                                          style: AppTextStyles.labelSmall,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                )
                              else
                                Text(
                                  'General explanation',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (message.answer!.simulated)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Demo answer (simulated)',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (provider.isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(),
                    ),
                  ),
                ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: provider.isSending
                            ? null
                            : () => provider.retry(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final prompt
                        in provider.language == 'am'
                            ? const [
                                'IPO ምንድን ነው?',
                                'የአቅርቦት ዋጋ ምንድን ነው?',
                                'ከመጠን በላይ መመዝገብ ምንድን ነው?',
                              ]
                            : const [
                                'What is an IPO?',
                                'What is an offer price?',
                                'What is oversubscription?',
                              ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(prompt),
                          onPressed: () {
                            _input.text = prompt;
                            _send();
                          },
                        ),
                      ),
                    if (widget.ipoId != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: const Text('Explain this IPO'),
                          onPressed: () {
                            _input.text = 'Explain this IPO';
                            _send();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                        style: AppTextStyles.inputText,
                        decoration: InputDecoration(
                          hintText: 'Ask an educational question',
                          hintStyle: AppTextStyles.inputHint,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: provider.isSending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
