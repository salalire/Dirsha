import type { AiGenerateRequest, AiProvider } from './types.js';

const glossary = {
  en: 'An IPO (initial public offering) is when a company offers shares to the public for the first time. An offer price is the stated price per share. Oversubscription means more shares are requested than offered. Allocation is how offered shares are distributed. This is a general explanation.',
  am: 'IPO (የመጀመሪያ የሕዝብ የአክሲዮን ሽያጭ) ኩባንያ ለመጀመሪያ ጊዜ አክሲዮኖችን ለሕዝብ ሲያቀርብ ነው። የአቅርቦት ዋጋ የአንድ አክሲዮን ዋጋ ነው። ይህ አጠቃላይ ማብራሪያ ነው።',
} as const;

export class MockAiProvider implements AiProvider {
  readonly name = 'mock';
  readonly simulated = true;
  async generate(request: AiGenerateRequest): Promise<string> {
    if (!request.context.startsWith('<DIRSHA DATA>')) return glossary[request.language];
    return `${request.language === 'am' ? 'From Dirsha data / ከDirsha መረጃ:' : 'From Dirsha data:'}\n${request.context.replaceAll('<DIRSHA DATA>', '').replaceAll('</DIRSHA DATA>', '').trim()}\n\nGeneral explanation: Ask about any term for an educational definition.`;
  }
}
