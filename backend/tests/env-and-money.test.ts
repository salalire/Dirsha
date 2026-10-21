import { describe, expect, it } from 'vitest';
import { EnvValidationError, parseEnv } from '../src/config/env.js';
import { assertMinorUnits, fromDb, MoneyError } from '../src/lib/money.js';

const valid = {
  DATABASE_URL: 'postgres://u:p@localhost:5432/db',
  JWT_ACCESS_SECRET: 'a'.repeat(40),
};

describe('environment validation', () => {
  it('accepts a valid configuration and applies safe defaults', () => {
    const env = parseEnv(valid);
    expect(env.NODE_ENV).toBe('development');
    expect(env.ENABLE_TEST_FUNDS).toBe(false);
    expect(env.CORS_ORIGINS).toEqual([]);
  });

  it('refuses to start without a database url or with a short JWT secret', () => {
    expect(() => parseEnv({ JWT_ACCESS_SECRET: valid.JWT_ACCESS_SECRET })).toThrow(
      EnvValidationError,
    );
    expect(() => parseEnv({ ...valid, JWT_ACCESS_SECRET: 'too-short' })).toThrow(/JWT_ACCESS_SECRET/);
  });

  it('never echoes configuration values in error messages', () => {
    try {
      parseEnv({ DATABASE_URL: 'mysql://user:supersecretpw@host/db', JWT_ACCESS_SECRET: 'shortvalue' });
      expect.unreachable('should have thrown');
    } catch (err) {
      const message = (err as Error).message;
      expect(message).not.toContain('supersecretpw');
      expect(message).not.toContain('shortvalue');
    }
  });

  it('forbids test funds in production', () => {
    expect(() =>
      parseEnv({ ...valid, NODE_ENV: 'production', ENABLE_TEST_FUNDS: 'true' }),
    ).toThrow(/ENABLE_TEST_FUNDS/);
    // allowed in development
    expect(parseEnv({ ...valid, NODE_ENV: 'development', ENABLE_TEST_FUNDS: 'true' }).ENABLE_TEST_FUNDS).toBe(true);
  });

  it('forbids the placeholder JWT secret in production', () => {
    expect(() =>
      parseEnv({
        ...valid,
        NODE_ENV: 'production',
        JWT_ACCESS_SECRET: 'CHANGE_ME_TO_A_RANDOM_VALUE_OF_AT_LEAST_32_CHARS',
      }),
    ).toThrow(/placeholder/);
  });

  it('rejects non-boolean ENABLE_TEST_FUNDS values', () => {
    expect(() => parseEnv({ ...valid, ENABLE_TEST_FUNDS: 'yes' })).toThrow(EnvValidationError);
  });
});

describe('money helpers (integer minor units, no floats)', () => {
  it('converts BIGINT strings from PostgreSQL to integers', () => {
    expect(fromDb('1000000')).toBe(1_000_000);
    expect(fromDb(0)).toBe(0);
  });

  it('refuses null and unsafe integers', () => {
    expect(() => fromDb(null)).toThrow(MoneyError);
    expect(() => fromDb('9007199254740993')).toThrow(MoneyError);
  });

  it('rejects fractional, zero and negative application amounts', () => {
    expect(() => assertMinorUnits(10.5)).toThrow(MoneyError);
    expect(() => assertMinorUnits(0)).toThrow(MoneyError);
    expect(() => assertMinorUnits(-5)).toThrow(MoneyError);
    expect(assertMinorUnits(1)).toBe(1);
  });
});
