import { afterEach, beforeEach, describe, expect, test } from 'bun:test';
import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import {
  AdminVariables,
  adminAuthMiddleware,
} from '../src/common/middleware/auth.ts';

const originalEnvironment = {
  DATABASE_URL: process.env.DATABASE_URL,
  ADMIN_JWT_SECRET: process.env.ADMIN_JWT_SECRET,
};

beforeEach(() => {
  process.env.DATABASE_URL = 'postgresql://test:test@database.invalid:5432/test';
  process.env.ADMIN_JWT_SECRET = 'admin-middleware-test-secret-value';
});

afterEach(() => {
  for (const [name, value] of Object.entries(originalEnvironment)) {
    if (value === undefined) delete process.env[name];
    else process.env[name] = value;
  }
});

function createApp() {
  const app = new Hono<{ Variables: AdminVariables }>();
  app.get('/protected', adminAuthMiddleware, (context) => context.json({
    adminId: context.get('adminId'),
    email: context.get('adminEmail'),
  }));
  return app;
}

describe('Admin authentication boundary', () => {
  test('accepts only an Admin token signed with the Admin secret', async () => {
    const token = await sign({
      sub: 'owner-1',
      email: 'owner@example.test',
      role: 'admin',
      exp: Math.floor(Date.now() / 1_000) + 60,
    }, process.env.ADMIN_JWT_SECRET!, 'HS256');
    const response = await createApp().request('/protected', {
      headers: { Authorization: `Bearer ${token}` },
    });

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      adminId: 'owner-1',
      email: 'owner@example.test',
    });
  });

  test('rejects absent, invalid, and non-Admin credentials', async () => {
    const passengerToken = await sign({
      sub: 'passenger-1',
      email: 'passenger@example.test',
      role: 'passenger',
      exp: Math.floor(Date.now() / 1_000) + 60,
    }, process.env.ADMIN_JWT_SECRET!, 'HS256');
    const responses = await Promise.all([
      createApp().request('/protected'),
      createApp().request('/protected', {
        headers: { Authorization: 'Bearer invalid' },
      }),
      createApp().request('/protected', {
        headers: { Authorization: `Bearer ${passengerToken}` },
      }),
    ]);

    expect(responses.map((response) => response.status)).toEqual([401, 401, 403]);
  });
});
