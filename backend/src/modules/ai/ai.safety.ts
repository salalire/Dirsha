import { randomBytes } from 'node:crypto';
import { REFUSALS } from './ai.prompt.js';

export type SafetyResult = { kind: 'safe' } | { kind: 'action' | 'private'; answer: string };

const actionPattern =
  /\b(buy|sell|purchase|subscribe|transfer|withdraw|deposit|change\s+(my\s+)?balance|approve|reject|place\s+an?\s+order)\b|ግዛ|ግዢ|ሽጥ|ሽያጭ|አዘዝ|መመዝገብ|አስተላልፍ|አውጣ|ቀሪ\s*ሂሳብ|አጽድቅ|ከልክል/i;
const privatePattern =
  /\b(my|our)\s+(wallet|balance|transactions?|documents?|password|holdings?|portfolio|account)\b|\b(wallet\s+balance|available\s+balance|account\s+balance)\b|\b(another|other|someone else|user\s+\w+).*(wallet|balance|transaction|document|profile)|\b(show|give|tell).*(another|other)\b|የሌላ.*(ቦርሳ|ግብይት|ሂሳብ|ሰነድ)/i;

export function prefilter(message: string, language: 'en' | 'am'): SafetyResult {
  if (actionPattern.test(message)) return { kind: 'action', answer: REFUSALS.action[language] };
  if (privatePattern.test(message)) {
    return { kind: 'private', answer: REFUSALS.private[language] };
  }
  return { kind: 'safe' };
}

export function createCanary(): string {
  return `DIRSHA_CANARY_${randomBytes(12).toString('hex')}`;
}

export function cleanHistory(history: Array<{ role: 'user' | 'assistant'; content: string }>) {
  return history.slice(-6).map((turn) => ({
    role: turn.role,
    content: Array.from(turn.content).filter((char) => {
      const code = char.charCodeAt(0);
      return code > 31 && code !== 127;
    }).join('').slice(0, 1000),
  }));
}

export function postcheck(output: string, canary: string): string {
  const value = output.trim().slice(0, 2000);
  if (!value || value.includes(canary)) throw new Error('invalid AI output');
  return value;
}
