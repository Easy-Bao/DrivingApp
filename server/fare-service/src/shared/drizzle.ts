import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from '../db/schema.ts';

if (!process.env.DATABASE_URL) {
  throw new Error('Configuration Error: DATABASE_URL environment variable is required but not set.');
}

const clientConnection = postgres(process.env.DATABASE_URL);

export const db = drizzle(clientConnection, { schema });
