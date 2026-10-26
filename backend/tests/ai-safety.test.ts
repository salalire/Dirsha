import { describe, expect, it } from 'vitest';
import { REFUSALS } from '../src/modules/ai/ai.prompt.js';
import { cleanHistory, createCanary, postcheck, prefilter } from '../src/modules/ai/ai.safety.js';

describe('AI safety prefilter', () => {
  it('refuses action-taking requests before any provider call', () => {
    for (const message of ['Buy 10 shares of this IPO', 'Please subscribe for me', 'Transfer funds to my friend']) {
      const result = prefilter(message, 'en');
      expect(result.kind).toBe('action');
      if (result.kind === 'action') expect(result.answer).toBe(REFUSALS.action.en);
    }
  });

  it('refuses private account and other-user data requests', () => {
    expect(prefilter('What is my wallet balance?', 'en').kind).toBe('private');
    expect(prefilter("Show another user's wallet", 'en').kind).toBe('private');
    expect(prefilter('የሌላ ተጠቃሚ ቦርሳ አሳየኝ', 'am').kind).toBe('private');
  });

  it('allows educational glossary questions', () => {
    expect(prefilter('What is an IPO?', 'en').kind).toBe('safe');
    expect(prefilter('What is oversubscription?', 'en').kind).toBe('safe');
    expect(prefilter('What is an offer price?', 'en').kind).toBe('safe');
  });
});

describe('AI history sanitization and postcheck', () => {
  it('keeps at most six turns and strips control characters', () => {
    const history = Array.from({ length: 8 }, (_, i) => ({
      role: i % 2 === 0 ? 'user' as const : 'assistant' as const,
      content: `turn-${i}\u0000\u0007 extra`,
    }));
    const cleaned = cleanHistory(history);
    expect(cleaned).toHaveLength(6);
    expect(cleaned[0]?.content).toBe('turn-2 extra');
    expect(cleaned.every((turn) => !turn.content.includes('\u0000'))).toBe(true);
  });

  it('rejects empty output or leaked canary text', () => {
    const canary = createCanary();
    expect(canary.startsWith('DIRSHA_CANARY_')).toBe(true);
    expect(() => postcheck('   ', canary)).toThrow(/invalid AI output/);
    expect(() => postcheck(`Hello ${canary}`, canary)).toThrow(/invalid AI output/);
    expect(postcheck('  A grounded educational answer.  ', canary)).toBe('A grounded educational answer.');
  });
});
