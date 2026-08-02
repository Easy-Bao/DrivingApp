import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { loadAdminConfiguration } from './env.ts';
import * as schema from '../db/schema/index.ts';

function createConnection() {
  const client = postgres(loadAdminConfiguration().DATABASE_URL);
  return {
    client,
    database: drizzle(client, { schema }),
  };
}

type DatabaseConnection = ReturnType<typeof createConnection>;
export type AdminDatabase = DatabaseConnection['database'];
export type AdminExecutor = Pick<AdminDatabase, 'select' | 'insert' | 'update'>;

let connection: DatabaseConnection | undefined;

/**
 * Lazy Admin database lifecycle: postpones PostgreSQL initialization until an
 * authenticated operation, migration helper, or provisioning command actually
 * needs persistence.
 *
 * The first call validates configuration, opens one postgres-js client, binds
 * the complete Drizzle schema, and caches both values. Later calls reuse that
 * connection, so simultaneous Hono requests share the driver's pool instead of
 * creating a socket pool per route. Provisioning and integration tests call
 * `closeAdminDatabase` after their final operation, which closes the client and
 * clears the cache so a later isolated run can create a fresh connection.
 *
 * Consumers receive `{ client, database }`; only infrastructure code closes the
 * client, while domain services use `getAdminDatabase` for typed queries.
 */
export function getAdminConnection(): DatabaseConnection {
  connection ??= createConnection();
  return connection;
}

export function getAdminDatabase(): AdminDatabase {
  return getAdminConnection().database;
}

export async function closeAdminDatabase(): Promise<void> {
  if (!connection) return;
  await connection.client.end();
  connection = undefined;
}
