/**
 * Configuration file for drizzle-kit outlining database dialect, credentials, and schema routes.
 */
import { defineConfig } from 'drizzle-kit';

if (!process.env.DATABASE_URL) {
  throw new Error('Configuration Error: DATABASE_URL environment variable is required but not set.');
}

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL,
  },
});
