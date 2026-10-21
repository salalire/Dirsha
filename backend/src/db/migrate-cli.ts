import 'dotenv/config';
import { migrateUp, migrationStatus, resetDatabase } from './migrate.js';

const command = process.argv[2] ?? 'up';
const databaseUrl = process.env.DATABASE_URL;

async function main(): Promise<void> {
  if (!databaseUrl) {
    throw new Error('DATABASE_URL is not set (see .env.example)');
  }

  switch (command) {
    case 'up': {
      const applied = await migrateUp(databaseUrl);
      console.log(applied.length ? `Applied: ${applied.join(', ')}` : 'Database is up to date.');
      break;
    }
    case 'status': {
      for (const m of await migrationStatus(databaseUrl)) {
        console.log(`${m.applied ? '[x]' : '[ ]'} ${m.name}`);
      }
      break;
    }
    case 'reset': {
      if (process.env.NODE_ENV === 'production') {
        throw new Error('Refusing to reset the database when NODE_ENV=production');
      }
      const applied = await resetDatabase(databaseUrl);
      console.log(`Database reset. Applied: ${applied.join(', ')}`);
      break;
    }
    default:
      throw new Error(`Unknown command "${command}". Use: up | status | reset`);
  }
}

main().catch((err: unknown) => {
  console.error((err as Error).message);
  process.exit(1);
});
