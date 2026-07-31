import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { servicePricingRules } from './schema.ts';

if (!process.env.DATABASE_URL) {
  throw new Error('Configuration Error: DATABASE_URL is required.');
}

const client = postgres(process.env.DATABASE_URL);
const database = drizzle(client);

try {
  await database.insert(servicePricingRules).values([
    {
      serviceType: 'Solo Ride',
      baseFare: 20,
      perKmRate: 10,
      perMinuteRate: 1.5,
      minimumFare: 25,
      surgeMultiplier: 1,
    },
    {
      serviceType: 'Share-Bao',
      baseFare: 15,
      perKmRate: 7,
      perMinuteRate: 1,
      minimumFare: 20,
      surgeMultiplier: 1,
    },
    {
      serviceType: 'Bao Premium',
      baseFare: 35,
      perKmRate: 15,
      perMinuteRate: 2,
      minimumFare: 40,
      surgeMultiplier: 1,
    },
  ]).onConflictDoNothing({
    target: servicePricingRules.serviceType,
  });
} finally {
  await client.end();
}
