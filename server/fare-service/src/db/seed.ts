import { db } from '../shared/drizzle.ts';
import { servicePricingRules } from '../db/schema.ts';

export async function seedPricingRules(): Promise<void> {
  try {
    await db
      .insert(servicePricingRules)
      .values([
        { serviceType: 'Solo Ride', baseFare: 20.0, perKmRate: 10.0, perMinuteRate: 1.5, minimumFare: 25.0 },
        { serviceType: 'Share-Bao', baseFare: 15.0, perKmRate: 7.0, perMinuteRate: 1.0, minimumFare: 20.0 },
        { serviceType: 'Bao Premium', baseFare: 35.0, perKmRate: 15.0, perMinuteRate: 2.0, minimumFare: 40.0 },
      ])
      .onConflictDoNothing();
  } catch (error) {
    console.error('[Database Seed] Failed to seed pricing rules:', error);
  }
}
