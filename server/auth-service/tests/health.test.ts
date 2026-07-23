import { describe, expect, test } from 'bun:test';
import { app } from '../src/index.ts';

describe('Auth Service — Health Integration Test', () => {
  test('GET / — returns service health status', async () => {
    const res = await app.request('/');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('Auth Service OK');
    expect(body.hasher).toBe('Bun.password (Native)');
  });
});
