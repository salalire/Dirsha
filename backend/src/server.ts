import "dotenv/config";
import { createApp } from "./app.js";
import { EnvValidationError, parseEnv } from "./config/env.js";
import { createDb } from "./db/pool.js";
import { createLogger } from "./lib/logger.js";

function main(): void {
  let env;
  try {
    env = parseEnv(process.env);
  } catch (err) {
    // Messages list the offending variable names only, never their values.
    const message =
      err instanceof EnvValidationError ? err.message : "Invalid configuration";
    process.stderr.write(`${message}\n`);
    process.exit(1);
  }

  const logger = createLogger(env.LOG_LEVEL);
  const db = createDb(env.DATABASE_URL);
  const app = createApp({ env, db, logger });

  if (env.ENABLE_TEST_FUNDS) {
    logger.warn(
      "ENABLE_TEST_FUNDS is on: simulated test-fund endpoint is available (dev/test only)",
    );
  }

  // Bind all interfaces so physical devices can reach the local dev server.
  const server = app.listen(env.PORT, "0.0.0.0", () => {
    logger.info(
      { port: env.PORT, env: env.NODE_ENV },
      "dirsha backend listening",
    );
  });

  const shutdown = (signal: string): void => {
    logger.info({ signal }, "shutting down");
    server.close(() => {
      db.end().finally(() => process.exit(0));
    });
    setTimeout(() => process.exit(1), 10_000).unref();
  };
  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
}

main();
