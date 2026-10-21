import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { buildApp } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

describe('GET /health', () => {
  it('returns ok without leaking configuration', async () => {
    const res = await request(ctx.app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.checks).toEqual({ database: 'up' });
    expect(Object.keys(res.body).sort()).toEqual(['checks', 'status', 'timestamp']);
    const text = JSON.stringify(res.body);
    expect(text).not.toMatch(/postgres|secret|password|localhost/i);
  });

  it('is public (no token needed)', async () => {
    expect((await request(ctx.app).get('/health')).status).toBe(200);
  });
});

describe('HTTP behaviour', () => {
  it('returns the standard error envelope for unknown routes', async () => {
    const res = await request(ctx.app).get('/nope');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
    expect(typeof res.body.error.request_id).toBe('string');
  });

  it('returns a validation error (not a 500) for malformed JSON', async () => {
    const res = await request(ctx.app)
      .post('/auth/login')
      .set('Content-Type', 'application/json')
      .send('{"email": ');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('sets a request id and echoes a well-formed client one', async () => {
    const generated = await request(ctx.app).get('/health');
    expect(generated.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);

    const echoed = await request(ctx.app).get('/health').set('X-Request-Id', 'client-req-12345');
    expect(echoed.headers['x-request-id']).toBe('client-req-12345');

    const bad = await request(ctx.app).get('/health').set('X-Request-Id', 'bad id with spaces!');
    expect(bad.headers['x-request-id']).not.toBe('bad id with spaces!');
  });

  it('sends security headers and hides the framework', async () => {
    const res = await request(ctx.app).get('/health');
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });

  it('only allows configured CORS origins', async () => {
    const app = buildApp({ CORS_ORIGINS: 'http://localhost:8080' });
    try {
      const allowed = await request(app.app).get('/health').set('Origin', 'http://localhost:8080');
      expect(allowed.headers['access-control-allow-origin']).toBe('http://localhost:8080');
      const denied = await request(app.app).get('/health').set('Origin', 'http://evil.example');
      expect(denied.headers['access-control-allow-origin']).toBeUndefined();
    } finally {
      await app.close();
    }
  });
});
