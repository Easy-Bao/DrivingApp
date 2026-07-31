import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from '../db/schema.ts';

if (!process.env.DATABASE_URL) {
  throw new Error('Configuration Error: DATABASE_URL is required.');
}

export const postgresClient = postgres(process.env.DATABASE_URL);
export const db = drizzle(postgresClient, { schema });
