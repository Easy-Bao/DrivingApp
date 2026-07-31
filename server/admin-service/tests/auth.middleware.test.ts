import { afterEach, beforeEach, describe, expect, test } from 'bun:test';
import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import {
  type AdminVariables,
  adminAuthMiddleware,
  internalAuthMiddleware,
} from '../src/shared/middleware/auth.ts';

const originalJwtSecret = process.env.JWT_SECRET;
const originalInternalServiceToken = process.env.INTERNAL_SERVICE_TOKEN;

beforeEach(() => {
  process.env.JWT_SECRET = 'admin-middleware-test-secret';
  process.env.INTERNAL_SERVICE_TOKEN = 'admin-middleware-internal-token';
});

afterEach(() => {
  if (originalJwtSecret === undefined) delete process.env.JWT_SECRET;
  else process.env.JWT_SECRET = originalJwtSecret;

  if (originalInternalServiceToken === undefined) {
    delete process.env.INTERNAL_SERVICE_TOKEN;
  } else {
    process.env.INTERNAL_SERVICE_TOKEN = originalInternalServiceToken;
  }
});

function createAdminApp() {
  const app = new Hono<{ Variables: AdminVariables }>();
  app.get('/protected', adminAuthMiddleware, (context) => context.json({
    admin_id: context.get('adminId'),
    admin_email: context.get('adminEmail'),
  }));
  return app;
}

function createInternalApp() {
  const app = new Hono();
  app.get('/internal', internalAuthMiddleware, (context) => context.json({ ok: true }));
  return app;
}

describe('Admin authentication middleware', () => {
  test('accepts a valid Admin token and exposes its verified identity', async () => {
    const token = await sign({
      sub: 'owner-1',
      email: 'owner@example.test',
      role: 'admin',
      exp: Math.floor(Date.now() / 1000) + 60,
    }, process.env.JWT_SECRET!, 'HS256');

    const response = await createAdminApp().request('/protected', {
      headers: { Authorization: `Bearer ${token}` },
    });

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      admin_id: 'owner-1',
      admin_email: 'owner@example.test',
    });
  });

  test('rejects absent, malformed, expired, and non-Admin credentials', async () => {
    const expiredToken = await sign({
      sub: 'owner-1',
      email: 'owner@example.test',
      role: 'admin',
      exp: Math.floor(Date.now() / 1000) - 60,
    }, process.env.JWT_SECRET!, 'HS256');
    const passengerToken = await sign({
      sub: 'passenger-1',
      email: 'passenger@example.test',
      role: 'passenger',
      exp: Math.floor(Date.now() / 1000) + 60,
    }, process.env.JWT_SECRET!, 'HS256');
    const app = createAdminApp();

    const responses = await Promise.all([
      app.request('/protected'),
      app.request('/protected', {
        headers: { Authorization: 'Bearer not-a-jwt' },
      }),
      app.request('/protected', {
        headers: { Authorization: `Bearer ${expiredToken}` },
      }),
      app.request('/protected', {
        headers: { Authorization: `Bearer ${passengerToken}` },
      }),
    ]);

    expect(responses.map((response) => response.status)).toEqual([401, 401, 401, 403]);
  });
});

describe('Internal service authentication middleware', () => {
  test('accepts only the configured internal service token', async () => {
    const app = createInternalApp();
    const responses = await Promise.all([
      app.request('/internal'),
      app.request('/internal', {
        headers: { 'X-Internal-Service-Token': 'incorrect-token' },
      }),
      app.request('/internal', {
        headers: {
          'X-Internal-Service-Token': process.env.INTERNAL_SERVICE_TOKEN!,
        },
      }),
    ]);

    expect(responses.map((response) => response.status)).toEqual([403, 403, 200]);
  });
});
