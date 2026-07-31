import { describe, expect, test } from 'bun:test';
import { loadAdminConfiguration } from '../src/config.ts';

const validEnvironment = {
  DATABASE_URL: 'postgresql://admin:password@localhost:5432/admin',
  JWT_SECRET: 'test-jwt-secret',
  INTERNAL_SERVICE_TOKEN: 'test-internal-token',
  DRIVER_SERVICE_URL: 'http://localhost:8082',
  PASSENGER_SERVICE_URL: 'http://localhost:8081',
  TRIP_SERVICE_URL: 'http://localhost:8083',
  BIDDING_SERVICE_URL: 'http://localhost:8084',
  FARE_SERVICE_URL: 'http://localhost:8087',
};

describe('Admin service configuration', () => {
  test('uses the Admin port default for complete valid configuration', () => {
    expect(loadAdminConfiguration(validEnvironment).PORT).toBe(8089);
  });

  test('reports missing configuration by name without including values', () => {
    expect(() => loadAdminConfiguration({
      ...validEnvironment,
      JWT_SECRET: '',
      INTERNAL_SERVICE_TOKEN: '',
    })).toThrow(
      'Admin Service Configuration Error: invalid or missing JWT_SECRET, INTERNAL_SERVICE_TOKEN',
    );
  });

  test('rejects an invalid database URL and port', () => {
    expect(() => loadAdminConfiguration({
      ...validEnvironment,
      DATABASE_URL: 'not-a-database-url',
      PORT: '70000',
    })).toThrow(
      'Admin Service Configuration Error: invalid or missing DATABASE_URL, PORT',
    );
  });
});
