import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  tablesFilter: ['service_pricing_rules', 'rating_pricing_configs', 'fare_transactions'],
  dbCredentials: {
    url: process.env.DATABASE_URL,
  },
});
