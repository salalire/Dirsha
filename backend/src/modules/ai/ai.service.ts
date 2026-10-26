import type { AppDeps, AuthUser } from '../../http/types.js';
import { Errors } from '../../lib/errors.js';
import { DISCLAIMERS, systemPrompt } from './ai.prompt.js';
import { buildContext } from './ai.context.js';
import { cleanHistory, createCanary, postcheck, prefilter } from './ai.safety.js';
import { createAiProvider } from './providers/index.js';

export interface AiChatInput {
  message: string;
  language: 'en' | 'am';
  ipo_id?: string;
  history: Array<{ role: 'user' | 'assistant'; content: string }>;
}

export async function chat(deps: AppDeps, user: AuthUser, input: AiChatInput, requestId: string) {
  const started = Date.now();
  const language = /[\u1200-\u137f]/.test(input.message) ? 'am' : input.language;
  const safety = prefilter(input.message, language);
  if (safety.kind !== 'safe') {
    return {
      answer: safety.answer,
      language,
      grounded: false,
      sources: [],
      disclaimer: DISCLAIMERS[language],
      simulated: true,
      request_id: requestId,
      _outcome: safety.kind === 'action' ? 'refused_action' : 'refused_private',
      _latency_ms: Date.now() - started,
    };
  }
  let context;
  try {
    context = await buildContext(deps.db, user, input.message, input.ipo_id);
  } catch {
    if (input.ipo_id) throw Errors.aiUnavailable();
    context = {
      text: 'No Dirsha IPO data is available for this general question.',
      grounded: false,
      sources: [],
    };
  }
  const provider = deps.aiProvider ?? createAiProvider(deps.env);
  const canary = createCanary();
  try {
    const answer = postcheck(
      await provider.generate({
        systemPrompt: systemPrompt(canary),
        message: input.message,
        language,
        history: cleanHistory(input.history),
        context: context.text,
      }),
      canary,
    );
    return {
      answer,
      language,
      grounded: context.grounded,
      sources: context.sources,
      disclaimer: DISCLAIMERS[language],
      simulated: provider.simulated,
      request_id: requestId,
      _outcome: 'answered',
      _latency_ms: Date.now() - started,
    };
  } catch {
    if (deps.env.AI_ALLOW_MOCK_FALLBACK && provider.name !== 'mock') {
      const fallback = await createAiProvider({ ...deps.env, AI_PROVIDER: 'mock' }).generate({
        systemPrompt: systemPrompt(canary),
        message: input.message,
        language,
        history: [],
        context: context.text,
      });
      return {
        answer: fallback,
        language,
        grounded: context.grounded,
        sources: context.sources,
        disclaimer: DISCLAIMERS[language],
        simulated: true,
        request_id: requestId,
        _outcome: 'fallback',
        _latency_ms: Date.now() - started,
      };
    }
    deps.logger.warn({ request_id: requestId, latency_ms: Date.now() - started }, 'AI provider failure');
    throw Errors.aiUnavailable();
  }
}
