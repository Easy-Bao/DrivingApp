import { describe, expect, test } from 'bun:test';
import { app } from '../src/index.ts';
import { OneTimePasswordStoreService } from '../src/features/services/common/otp_store.ts';

process.env.JWT_SECRET = 'test_environment_jwt_secret_key_12345';

describe('Auth Service — Forgot Password & OTP Integration Tests', () => {
  const targetEmail = 'otp.user@example.com';

  test('POST /auth/forgot-password — generates OTP for password reset', async () => {
    const res = await app.request('/auth/forgot-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: targetEmail,
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
  });

  test('POST /auth/verify-otp — successfully verifies valid generated OTP', async () => {
    const generatedOtp = OneTimePasswordStoreService.retrieveOneTimePasswordCodeForTesting(targetEmail);
    expect(generatedOtp).toBeDefined();

    const res = await app.request('/auth/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: targetEmail,
        code: generatedOtp,
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.verified).toBe(true);
  });

  test('POST /auth/verify-otp — rejects invalid OTP code', async () => {
    const res = await app.request('/auth/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: targetEmail,
        code: '999999',
      }),
    });
    expect(res.status).toBe(400);
  });
});
