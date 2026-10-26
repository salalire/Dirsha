import type { Env } from '../../../config/env.js';
import type { AiProvider } from './types.js';
import { BedrockAiProvider } from './bedrock.provider.js';
import { MockAiProvider } from './mock.provider.js';
import { GeminiAiProvider } from './gemini.provider.js';

export function createAiProvider(env: Env): AiProvider {
  if (env.AI_PROVIDER === 'bedrock') return new BedrockAiProvider(env.AI_MODEL_ID!, env.AWS_REGION!, env.AI_TIMEOUT_MS);
  if (env.AI_PROVIDER === 'gemini') {
    return new GeminiAiProvider(
      env.GEMINI_API_KEY!,
      env.GEMINI_MODEL_ID ?? env.AI_MODEL_ID ?? 'gemini-3.5-flash-lite',
      env.AI_TIMEOUT_MS,
    );
  }
  return new MockAiProvider();
}
