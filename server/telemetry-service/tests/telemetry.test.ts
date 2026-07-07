import { expect, test, describe } from 'bun:test';
import telemetryService from '../src/index.ts';

describe('Telemetry Service Endpoints', () => {
  const app = telemetryService;

  test('POST /telemetry/location - updates telemetry position', async () => {
    const res = await app.fetch(
      new Request('http://localhost/telemetry/location', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          driverId: 'driver-123',
          lat: 7.828282,
          lng: 123.434343,
        }),
      })
    );

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.success).toBe(true);
  });

  test('GET /telemetry/location/:driverId - retrieves latest coordinates', async () => {
    const res = await app.fetch(new Request('http://localhost/telemetry/location/driver-123'));
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.lat).toBe(7.828282);
    expect(data.lng).toBe(123.434343);
    expect(data.updatedAt).toBeDefined();
  });

  test('POST /telemetry/location - rejects GPS spoofing with 400', async () => {
    await app.fetch(
      new Request('http://localhost/telemetry/location', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          driverId: 'driver-spoof',
          lat: 7.828282,
          lng: 123.434343,
        }),
      })
    );

    await new Promise((resolve) => setTimeout(resolve, 15));

    const res = await app.fetch(
      new Request('http://localhost/telemetry/location', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          driverId: 'driver-spoof',
          lat: 8.500000,
          lng: 124.500000,
        }),
      })
    );

    expect(res.status).toBe(400);
    const data: any = await res.json();
    expect(data.error).toBe('GPS_SPOOFING_DETECTED');
  });
});
