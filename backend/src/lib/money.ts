/**
 * Money handling (SRS §9 design principle 2: no binary floating point).
 *
 * Convention: all amounts are INTEGER MINOR UNITS of ETB ("santim", 1 ETB = 100 santim),
 * stored in PostgreSQL as BIGINT. node-postgres returns BIGINT as a string, so every
 * amount read from the database must pass through `fromDb`.
 *
 * On the wire (JSON) amounts are plain integers in minor units; the API contract
 * always names the unit in the field name (`*_minor`) and carries `currency: "ETB"`.
 */
export const CURRENCY = 'ETB';

export class MoneyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'MoneyError';
  }
}

/** Convert a BIGINT string from PostgreSQL into a JS integer, refusing unsafe values. */
export function fromDb(value: string | number | bigint | null | undefined): number {
  if (value === null || value === undefined) {
    throw new MoneyError('Amount is null');
  }
  const n = typeof value === 'bigint' ? Number(value) : Number(value);
  if (!Number.isSafeInteger(n)) {
    throw new MoneyError('Amount is not a safe integer');
  }
  return n;
}

/** Validate an integer minor-unit amount supplied by application code. */
export function assertMinorUnits(value: number, opts: { allowZero?: boolean } = {}): number {
  if (!Number.isSafeInteger(value)) {
    throw new MoneyError('Amount must be a safe integer number of minor units');
  }
  if (value < 0 || (value === 0 && !opts.allowZero)) {
    throw new MoneyError('Amount must be positive');
  }
  return value;
}
