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
  ADMIN_SERVICE_URL: 'http://admin-service:8090',
  LOCATION_SERVICE_URL: 'http://location-service:8089',
});

const { app } = await import('../src/index.ts');
const { SERVICE_REGISTRY } = await import('../src/config/gateway.config.ts');
const originalFetch = globalThis.fetch;

afterEach(() => {
  globalThis.fetch = originalFetch;
});

describe('API gateway Admin route', () => {
  test('registers the isolated Admin service URL', () => {
    expect(SERVICE_REGISTRY.admin).toBe('http://admin-service:8090');
    expect(() => new URL(SERVICE_REGISTRY.admin)).not.toThrow();
  });

  test('forwards Admin requests without changing their path', async () => {
    let upstreamUrl = '';
    globalThis.fetch = mock(async (input: string | URL | Request) => {
      upstreamUrl = input.toString();
      return new Response(null, { status: 204 });
    }) as typeof fetch;

    const response = await app.request('/admin/v1/overview');

    expect(response.status).toBe(204);
    expect(upstreamUrl).toBe('http://admin-service:8090/admin/v1/overview');
  });
});
