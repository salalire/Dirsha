import type { AuthUser } from '../../../http/types.js';

export interface AiGenerateRequest {
  systemPrompt: string;
  message: string;
  language: 'en' | 'am';
  history: Array<{ role: 'user' | 'assistant'; content: string }>;
  context: string;
}

export interface AiProvider {
  readonly name: string;
  readonly simulated: boolean;
  generate(request: AiGenerateRequest): Promise<string>;
}

export interface AiContext {
  text: string;
  grounded: boolean;
  sources: Array<{ label: string; type: 'ipo'; ipo_id: string; as_of: string }>;
}

export type AiCaller = AuthUser;
