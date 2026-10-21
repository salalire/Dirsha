import pg from 'pg';
import type { PoolClient, QueryResult, QueryResultRow } from 'pg';

/**
 * Thin wrapper over a pg Pool. The pool is created from validated configuration
 * (never reads process.env directly) so tests can point it at a different database.
 */
export interface Db {
  query<R extends QueryResultRow = QueryResultRow>(
    text: string,
    params?: unknown[],
  ): Promise<QueryResult<R>>;
  /** Run `fn` inside a transaction: COMMIT on success, ROLLBACK on any thrown error. */
  tx<T>(fn: (client: PoolClient) => Promise<T>): Promise<T>;
  /** Cheap connectivity probe used by the health endpoint. */
  ping(): Promise<boolean>;
  end(): Promise<void>;
}

export function createDb(databaseUrl: string): Db {
  const pool = new pg.Pool({
    connectionString: databaseUrl,
    max: 10,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000,
  });

  // An idle client erroring must not crash the process with an unhandled event.
  pool.on('error', () => {
    /* connection-level errors surface on the next query */
  });

  return {
    query: (text, params) => pool.query(text, params),
    async tx(fn) {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const result = await fn(client);
        await client.query('COMMIT');
        return result;
      } catch (err) {
        try {
          await client.query('ROLLBACK');
        } catch {
          /* keep the original error */
        }
        throw err;
      } finally {
        client.release();
      }
    },
    async ping() {
      try {
        await pool.query('SELECT 1');
        return true;
      } catch {
        return false;
      }
    },
    end: () => pool.end(),
  };
}
