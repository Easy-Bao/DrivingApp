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

/** Opens the Admin database only when a database-backed operation is used. */
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
