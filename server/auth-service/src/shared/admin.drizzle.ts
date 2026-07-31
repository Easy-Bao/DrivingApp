import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

const authDbUrl =
  process.env.AUTH_DB_URL ||
  process.env.DATABASE_URL ||
  process.env.PASSENGER_DB_URL;

if (!authDbUrl) {
  throw new Error(
    'Configuration Error: AUTH_DB_URL, DATABASE_URL, or PASSENGER_DB_URL environment variable is required.',
  );
}

export const authPostgresClient = postgres(authDbUrl);
export const authDb = drizzle(authPostgresClient);
