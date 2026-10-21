import 'dotenv/config';
import { resetDatabase } from '../src/db/migrate.js';

/**
 * Runs once before the suite: wipes and re-migrates the TEST database, which also
 * proves the migrations apply from a clean database every time.
 *
 * Safety: this DROPs the public schema, so it refuses any database whose name does not
 * end in "_test".
 */
export default async function setup(): Promise<void> {
  const url = process.env.TEST_DATABASE_URL;
  if (!url) {
    throw new Error(
      'TEST_DATABASE_URL is not set. Point it at a throw-away database whose name ends in ' +
        '"_test" (see backend/README.md).',
    );
  }
  const dbName = new URL(url).pathname.replace(/^\//, '');
  if (!/_test$/.test(dbName)) {
    throw new Error(
      `Refusing to run tests: database "${dbName}" does not end in "_test". ` +
        'The test run wipes the database it connects to.',
    );
  }
  await resetDatabase(url);
}
