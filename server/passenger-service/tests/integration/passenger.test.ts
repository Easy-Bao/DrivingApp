import { expect, test, describe, beforeAll } from 'bun:test';
import { app } from '../../src/index.ts';
import { db } from '../../src/shared/drizzle.ts';
import { passengers, rideRequests } from '../../src/db/schema.ts';

describe('Passenger Service Integration Tests', () => {
  beforeAll(async () => {
    await db.delete(rideRequests);
    await db.delete(passengers);
  });

  let passengerId = '';
  let token = '';

  test('POST /passengers - registers passenger successfully', async () => {
    const response = await app.request('/passengers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Test Passenger',
        email: 'passenger@example.com',
        phone: '09123456789',
        password: 'securePassword123',
        preferred_ride_type: 'solo-ride',
      }),
    });

    expect(response.status).toBe(201);
    const data: any = await response.json();
    expect(data.needs_verification).toBe(true);
    expect(data.email).toBe('passenger@example.com');
    expect(data.passenger.id).toBeDefined();
    expect(data.passenger.name).toBe('Test Passenger');
    expect(data.passenger.email).toBe('passenger@example.com');

    passengerId = data.passenger.id;
  });

  test('POST /passengers/verify-otp - verifies OTP successfully', async () => {
    const response = await app.request('/passengers/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'passenger@example.com',
        code: '123456',
      }),
    });

    expect(response.status).toBe(200);
    const data: any = await response.json();
    expect(data.success).toBe(true);
  });

  test('POST /passengers/login - authenticates passenger and returns JWT', async () => {
    const response = await app.request('/passengers/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'passenger@example.com',
        password: 'securePassword123',
      }),
    });

    expect(response.status).toBe(200);
    const data: any = await response.json();
    expect(data.token).toBeDefined();
    expect(data.passenger.id).toBe(passengerId);
    token = data.token;
  });

  test('GET /passengers/:id - retrieves profile successfully', async () => {
    const response = await app.request(`/passengers/${passengerId}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });

    expect(response.status).toBe(200);
    const data: any = await response.json();
    expect(data.id).toBe(passengerId);
    expect(data.name).toBe('Test Passenger');
  });

  test('GET /passengers/:id - forbids profile lookup for different passenger ID', async () => {
    const response = await app.request('/passengers/00000000-0000-0000-0000-000000000000', {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });

    expect(response.status).toBe(403);
  });

  test('PUT /passengers/:id - updates passenger profile successfully', async () => {
    const response = await app.request(`/passengers/${passengerId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        name: 'Updated Passenger Name',
        phone: '09998887766',
        email: 'passenger@example.com',
      }),
    });

    expect(response.status).toBe(200);
    const data: any = await response.json();
    expect(data.name).toBe('Updated Passenger Name');
    expect(data.phone).toBe('09998887766');
  });

  test('POST /rides - logs ride request successfully', async () => {
    const response = await app.request('/rides', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        passenger_id: passengerId,
        ride_type: 'solo-ride',
        pickup_latitude: 7.8286,
        pickup_longitude: 123.4361,
        pickup_name: 'Plaza Luz',
        dropoff_latitude: 7.8250,
        dropoff_longitude: 123.4380,
        dropoff_name: 'Robinson Market',
        fare: 150.0,
      }),
    });

    expect(response.status).toBe(201);
    const data: any = await response.json();
    expect(data.id).toBeDefined();
    expect(data.passenger_id).toBe(passengerId);
    expect(data.status).toBe('requested');
  });

  test('GET /passengers/:id/rides - lists passenger ride history', async () => {
    const response = await app.request(`/passengers/${passengerId}/rides`, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });

    expect(response.status).toBe(200);
    const data: any = await response.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBeGreaterThan(0);
    expect(data[0].pickup_name).toBe('Plaza Luz');
  });

  test('GET /passengers/:id/notifications - retrieves passenger notifications', async () => {
    const response = await app.request(`/passengers/${passengerId}/notifications`, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });

    expect(response.status).toBe(200);
    const data: any = await response.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBeGreaterThan(0);
  });
});
