import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { eq } from 'drizzle-orm';
import { app } from '../../src/index.ts';
import { drivers, reviews } from '../../src/db/schema.ts';
import { db } from '../../src/shared/drizzle.ts';

const driverId = `drv_profile_test_${Date.now()}`;

beforeAll(async () => {
  await db.insert(drivers).values({
    id: driverId,
    name: 'Driver Profile Test',
    email: `${driverId}@test.local`,
    phone: '09111111111',
    vehicleType: 'Bao Bao',
    plateNumber: 'TEST 999',
    passwordHash: 'not-a-real-password',
    approvalStatus: 'approved',
  });
});

afterAll(async () => {
  await db.delete(reviews).where(eq(reviews.driverId, driverId));
  await db.delete(drivers).where(eq(drivers.id, driverId));
});

describe('Driver Service Integration Tests', () => {
  test('GET /drivers/:id returns a safe driver profile', async () => {
    const response = await app.request(`/drivers/${driverId}`);
    expect(response.status).toBe(200);
    const profile = await response.json() as Record<string, unknown>;
    expect(profile).toMatchObject({
      id: driverId,
      approvalStatus: 'approved',
    });
    expect(profile.passwordHash).toBeUndefined();
  });

  test('POST and GET /drivers/:id/reviews update public reviews', async () => {
    const created = await app.request(`/drivers/${driverId}/reviews`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        passengerName: 'Passenger Test',
        rating: 4.8,
        comment: 'Safe and punctual.',
      }),
    });
    expect(created.status).toBe(201);

    const response = await app.request(`/drivers/${driverId}/reviews`);
    expect(response.status).toBe(200);
    const list = await response.json() as Array<Record<string, unknown>>;
    expect(list).toHaveLength(1);
    expect(list[0]).toMatchObject({
      passengerName: 'Passenger Test',
      rating: 4.8,
    });
  });

  test('GET /drivers/:id returns 404 for an unknown driver', async () => {
    const response = await app.request('/drivers/does-not-exist');
    expect(response.status).toBe(404);
  });
});
