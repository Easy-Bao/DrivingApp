import { expect, test, describe } from 'bun:test';
import { app } from '../src/index.ts';
import { SERVICE_REGISTRY } from '../src/config/gateway.config.ts';

describe('API Gateway Configuration & Zod Validation Tests', () => {
  test('SERVICE_REGISTRY validates all required microservice URLs via Zod', () => {
    expect(SERVICE_REGISTRY.passengers).toBeDefined();
    expect(SERVICE_REGISTRY.rides).toBeDefined();
    expect(SERVICE_REGISTRY.drivers).toBeDefined();
    expect(SERVICE_REGISTRY.telemetry).toBeDefined();
    expect(SERVICE_REGISTRY.bidding).toBeDefined();
    expect(SERVICE_REGISTRY.chat).toBeDefined();
    expect(SERVICE_REGISTRY.fares).toBeDefined();

    expect(() => new URL(SERVICE_REGISTRY.passengers)).not.toThrow();
    expect(() => new URL(SERVICE_REGISTRY.fares)).not.toThrow();
  });

  test('GET / — returns status OK', async () => {
    const res = await app.request('/', { method: 'GET' });
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.status).toBe('Gateway OK');
  });
});
