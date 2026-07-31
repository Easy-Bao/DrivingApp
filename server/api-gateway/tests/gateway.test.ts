import { afterEach, describe, expect, mock, test } from 'bun:test';

Object.assign(process.env, {
  AUTH_SERVICE_URL: 'http://auth-service:8088',
  PASSENGER_SERVICE_URL: 'http://passenger-service:8081',
  DRIVER_SERVICE_URL: 'http://driver-service:8082',
  TRIP_SERVICE_URL: 'http://trip-service:8083',
  BIDDING_SERVICE_URL: 'http://bidding-service:8084',
  TELEMETRY_SERVICE_URL: 'http://telemetry-service:8085',
  CHAT_SERVICE_URL: 'http://chat-service:8086',
  FARE_SERVICE_URL: 'http://fare-service:8087',
  ADMIN_SERVICE_URL: 'http://admin-service:8089',
  LOCATION_SERVICE_URL: 'http://location-service:8090',
});

const { app } = await import('../src/index.ts');
const { SERVICE_REGISTRY } = await import('../src/config/gateway.config.ts');
const originalFetch = globalThis.fetch;

afterEach(() => {
  globalThis.fetch = originalFetch;
});

describe('API Gateway Configuration & Zod Validation Tests', () => {
  test('SERVICE_REGISTRY validates all required microservice URLs via Zod', () => {
    expect(SERVICE_REGISTRY.passengers).toBeDefined();
    expect(SERVICE_REGISTRY.rides).toBeDefined();
    expect(SERVICE_REGISTRY.drivers).toBeDefined();
    expect(SERVICE_REGISTRY.telemetry).toBeDefined();
    expect(SERVICE_REGISTRY.bidding).toBeDefined();
    expect(SERVICE_REGISTRY.chat).toBeDefined();
    expect(SERVICE_REGISTRY.fares).toBeDefined();
    expect(SERVICE_REGISTRY.admin).toBeDefined();
    expect(SERVICE_REGISTRY.location).toBeDefined();

    expect(() => new URL(SERVICE_REGISTRY.passengers)).not.toThrow();
    expect(() => new URL(SERVICE_REGISTRY.fares)).not.toThrow();
    expect(() => new URL(SERVICE_REGISTRY.admin)).not.toThrow();
    expect(() => new URL(SERVICE_REGISTRY.location)).not.toThrow();
  });

  test('GET / — returns status OK', async () => {
    const res = await app.request('/', { method: 'GET' });
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.status).toBe('Gateway OK');
  });

  test('strips client-supplied internal authentication headers', async () => {
    let upstreamHeaders = new Headers();
    globalThis.fetch = mock(async (_input: string | URL | Request, init?: RequestInit) => {
      upstreamHeaders = new Headers(init?.headers);
      return new Response(JSON.stringify({ success: true }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }) as typeof fetch;

    const res = await app.request('/admin/v1/overview', {
      headers: {
        Authorization: 'Bearer owner-token',
        'X-Internal-Service-Token': 'client-controlled-secret',
        'X-Internal-Auth': 'client-controlled-secret',
      },
    });

    expect(res.status).toBe(200);
    expect(upstreamHeaders.get('authorization')).toBe('Bearer owner-token');
    expect(upstreamHeaders.has('x-internal-service-token')).toBe(false);
    expect(upstreamHeaders.has('x-internal-auth')).toBe(false);
  });
});
