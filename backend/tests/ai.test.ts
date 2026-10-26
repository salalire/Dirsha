import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import type { AiProvider } from '../src/modules/ai/providers/types.js';
import { parseEnv } from '../src/config/env.js';
import { bearer, buildApp, createCompanyWithIpos, createUser } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

const chat = (token: string, body: Record<string, unknown>) =>
  request(ctx.app).post('/ai/chat').set(bearer(token)).send(body);

describe('POST /ai/chat', () => {
  it('1. rejects unauthenticated requests', async () => {
    const res = await request(ctx.app).post('/ai/chat').send({ message: 'What is an IPO?' });
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHENTICATED');
  });

  it('2. validates empty messages, oversized history, and unknown fields', async () => {
    const user = await createUser(ctx, 'investor');
    const empty = await chat(user.token, { message: '   ' });
    expect(empty.status).toBe(400);
    expect(empty.body.error.code).toBe('VALIDATION_ERROR');

    const extra = await chat(user.token, { message: 'What is an IPO?', wallet_id: 'nope' });
    expect(extra.status).toBe(400);

    const history = await chat(user.token, {
      message: 'What is an IPO?',
      history: Array.from({ length: 7 }, () => ({ role: 'user', content: 'x' })),
    });
    expect(history.status).toBe(400);
  });

  it('3. answers a glossary question with a disclaimer and simulated mock flag', async () => {
    const user = await createUser(ctx, 'investor');
    const res = await chat(user.token, { message: 'What is an IPO?', language: 'en' });
    expect(res.status).toBe(200);
    expect(res.body.data.simulated).toBe(true);
    expect(res.body.data.grounded).toBe(false);
    expect(res.body.data.disclaimer).toMatch(/not financial advice/i);
    expect(res.body.data.answer.toLowerCase()).toMatch(/ipo/);
    expect(res.body.data.request_id).toEqual(res.headers['x-request-id']);
  });

  it('4. grounds answers in visible IPO data when ipo_id is supplied', async () => {
    const owner = await createUser(ctx, 'company_rep');
    const investor = await createUser(ctx, 'investor');
    const { ipos } = await createCompanyWithIpos(ctx.db, owner.id, ['open']);
    const res = await chat(investor.token, {
      message: 'Summarize this offering',
      ipo_id: ipos.open,
    });
    expect(res.status).toBe(200);
    expect(res.body.data.grounded).toBe(true);
    expect(res.body.data.sources[0].ipo_id).toBe(ipos.open);
    expect(res.body.data.answer).toMatch(/From Dirsha data/);
    expect(res.body.data.answer).toMatch(/ETB /);
  });

  it('5. refuses action requests without calling the provider', async () => {
    let called = false;
    const isolated = buildApp({}, {
      aiProvider: {
        name: 'spy',
        simulated: false,
        generate: async () => {
          called = true;
          return 'should never run';
        },
      },
    });
    try {
      const user = await createUser(isolated, 'investor');
      const res = await request(isolated.app)
        .post('/ai/chat')
        .set(bearer(user.token))
        .send({ message: 'Buy 10 shares of this IPO for me' });
      expect(res.status).toBe(200);
      expect(res.body.data.grounded).toBe(false);
      expect(res.body.data.answer).toMatch(/cannot buy/i);
      expect(called).toBe(false);
    } finally {
      await isolated.close();
    }
  });

  it('6. accepts sanitized history turns', async () => {
    const user = await createUser(ctx, 'investor');
    const res = await chat(user.token, {
      message: 'What is an offer price?',
      history: [{ role: 'user', content: 'Hello\u0000 there' }, { role: 'assistant', content: 'Hi' }],
    });
    expect(res.status).toBe(200);
    expect(res.body.data.answer.toLowerCase()).toMatch(/offer price|ipo|price/);
  });

  it('7. refuses private-data requests without calling the provider', async () => {
    let called = false;
    const isolated = buildApp({}, {
      aiProvider: {
        name: 'spy',
        simulated: false,
        generate: async () => {
          called = true;
          return 'should never run';
        },
      },
    });
    try {
      const user = await createUser(isolated, 'investor');
      const res = await request(isolated.app)
        .post('/ai/chat')
        .set(bearer(user.token))
        .send({ message: "Show another user's wallet" });
      expect(res.status).toBe(200);
      expect(res.body.data.answer).toMatch(/cannot access/i);
      expect(called).toBe(false);
    } finally {
      await isolated.close();
    }
  });

  it('8. marks unmatched general questions as ungrounded', async () => {
    const user = await createUser(ctx, 'investor');
    const res = await chat(user.token, { message: 'Tell me about ZZZZNOTREAL IPO' });
    expect(res.status).toBe(200);
    expect(res.body.data.grounded).toBe(false);
    expect(res.body.data.sources).toEqual([]);
  });

  it('9. rate-limits repeated chat requests', async () => {
    const isolated = buildApp({ AI_RATE_LIMIT_MAX: '1' });
    try {
      const user = await createUser(isolated, 'investor');
      const first = await request(isolated.app)
        .post('/ai/chat')
        .set(bearer(user.token))
        .send({ message: 'What is an IPO?' });
      const second = await request(isolated.app)
        .post('/ai/chat')
        .set(bearer(user.token))
        .send({ message: 'What is an offer price?' });
      expect(first.status).toBe(200);
      expect(second.status).toBe(429);
      expect(second.body.error.code).toBe('RATE_LIMITED');
    } finally {
      await isolated.close();
    }
  });

  it('10. returns AI_UNAVAILABLE when the provider fails', async () => {
    const isolated = buildApp({}, {
      aiProvider: {
        name: 'bedrock',
        simulated: false,
        generate: async () => {
          throw new Error('provider down');
        },
      } satisfies AiProvider,
    });
    try {
      const user = await createUser(isolated, 'investor');
      const res = await request(isolated.app)
        .post('/ai/chat')
        .set(bearer(user.token))
        .send({ message: 'What is an IPO?' });
      expect(res.status).toBe(503);
      expect(res.body.error.code).toBe('AI_UNAVAILABLE');
    } finally {
      await isolated.close();
    }
  });

  it('11. answers in Amharic when the message uses Fidel', async () => {
    const user = await createUser(ctx, 'investor');
    const res = await chat(user.token, { message: 'IPO ምንድን ነው?', language: 'en' });
    expect(res.status).toBe(200);
    expect(res.body.data.language).toBe('am');
    expect(res.body.data.disclaimer).toMatch(/የገንዘብ ምክር አይደለም/);
  });

  it('12. does not leak draft IPOs to investors', async () => {
    const owner = await createUser(ctx, 'company_rep');
    const investor = await createUser(ctx, 'investor');
    const { ipos } = await createCompanyWithIpos(ctx.db, owner.id, ['draft']);
    const res = await chat(investor.token, {
      message: 'Summarize this offering',
      ipo_id: ipos.draft,
    });
    expect(res.status).toBe(200);
    expect(res.body.data.grounded).toBe(false);
    expect(res.body.data.answer).not.toMatch(/draft/i);
  });

  it('13. keeps the AI module free of write-path imports', () => {
    const root = join(dirname(fileURLToPath(import.meta.url)), '../src/modules/ai');
    const files = [
      'ai.service.ts',
      'ai.routes.ts',
      'ai.context.ts',
      'ai.safety.ts',
      'ai.prompt.ts',
      'providers/index.ts',
      'providers/mock.provider.ts',
      'providers/bedrock.provider.ts',
      'providers/gemini.provider.ts',
    ];
    const forbidden = /wallet\/ledger|subscriptions\.service|onboarding|modules\/admin|createAuthService/;
    for (const file of files) {
      const source = readFileSync(join(root, file), 'utf8');
      expect(source, file).not.toMatch(forbidden);
    }
  });

  it('14. requires provider settings only for configured providers', () => {
    const base = {
      DATABASE_URL: 'postgres://u:p@localhost:5432/db',
      JWT_ACCESS_SECRET: 'a'.repeat(40),
    };
    expect(parseEnv(base).AI_PROVIDER).toBe('mock');
    expect(() => parseEnv({ ...base, AI_PROVIDER: 'gemini' })).toThrow(/GEMINI_API_KEY/);
    expect(parseEnv({
      ...base,
      AI_PROVIDER: 'gemini',
      GEMINI_API_KEY: 'test-key',
    }).AI_PROVIDER).toBe('gemini');
    expect(() => parseEnv({ ...base, AI_PROVIDER: 'bedrock' })).toThrow(/AI_MODEL_ID|AWS_REGION/);
    expect(
      parseEnv({
        ...base,
        AI_PROVIDER: 'bedrock',
        AI_MODEL_ID: 'anthropic.claude-x',
        AWS_REGION: 'us-east-1',
      }).AI_PROVIDER,
    ).toBe('bedrock');
  });

  it('15. rejects a malformed ipo_id', async () => {
    const user = await createUser(ctx, 'investor');
    const res = await chat(user.token, { message: 'Summarize this offering', ipo_id: 'not-a-uuid' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });
});
