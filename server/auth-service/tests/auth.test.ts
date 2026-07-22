import { describe, expect, test } from 'bun:test';
import { app } from '../src/index.ts';

describe('Auth Service — Integration Tests with Argon2', () => {
  test('GET / — returns service health status', async () => {
    const res = await app.request('/');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('Auth Service OK');
    expect(body.hasher).toBe('Argon2id');
  });

  test('POST /auth/passenger/register — registers new passenger with Argon2 hash', async () => {
    const res = await app.request('/auth/passenger/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'John Doe',
        email: 'john.passenger@example.com',
        phone: '+639171234567',
        password: 'securePassword123',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.email).toBe('john.passenger@example.com');
    expect(body.data.user.role).toBe('passenger');
    expect(body.data.user.passwordHash).toBeUndefined(); // Guarantees password_hash is sanitized
  });

  test('POST /auth/passenger/login — authenticates passenger with Argon2 verification', async () => {
    const res = await app.request('/auth/passenger/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'john.passenger@example.com',
        password: 'securePassword123',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
  });

  test('POST /auth/verify-otp — verifies valid 6-digit OTP code', async () => {
    const res = await app.request('/auth/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'john.passenger@example.com',
        code: '123456',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.verified).toBe(true);
  });
});
