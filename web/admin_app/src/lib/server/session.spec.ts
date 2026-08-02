import { describe, expect, it, vi } from 'vitest';
import type { Cookies } from '@sveltejs/kit';
import {
  ADMIN_COOKIE,
  ADMIN_SESSION_SECONDS,
  adminSessionCookieIsSecure,
  clearAdminSession,
  setAdminSession,
  validateAdminSession,
} from './session';

describe('admin session', () => {
  it('stores the token in an eight-hour server-only cookie', () => {
    let saved: { name: string; value: string; options: Record<string, unknown> } | undefined;
    const cookies = {
      set(name: string, value: string, options: Record<string, unknown>) {
        saved = { name, value, options };
      },
    } as unknown as Cookies;

    setAdminSession(cookies, 'signed-token', true);

    expect(saved).toEqual({
      name: ADMIN_COOKIE,
      value: 'signed-token',
      options: {
        path: '/',
        httpOnly: true,
        sameSite: 'strict',
        secure: true,
        maxAge: ADMIN_SESSION_SECONDS,
      },
    });
  });

  it('uses the same protected attributes when clearing the cookie', () => {
    let cleared: { name: string; options: Record<string, unknown> } | undefined;
    const cookies = {
      delete(name: string, options: Record<string, unknown>) {
        cleared = { name, options };
      },
    } as unknown as Cookies;

    clearAdminSession(cookies, true);

    expect(cleared).toEqual({
      name: ADMIN_COOKIE,
      options: {
        path: '/',
        httpOnly: true,
        sameSite: 'strict',
        secure: true,
      },
    });
  });

  it('requires Secure cookies outside local development', () => {
    expect(adminSessionCookieIsSecure(new URL('http://localhost:5173'), true)).toBe(false);
    expect(adminSessionCookieIsSecure(new URL('http://localhost:5173'), false)).toBe(false);
    expect(adminSessionCookieIsSecure(new URL('https://localhost:5173'), true)).toBe(true);
    expect(adminSessionCookieIsSecure(new URL('http://admin.internal'), false)).toBe(true);
  });
});

describe('admin session validation', () => {
  it('accepts a verified Admin token without exposing it to browser code', async () => {
    const fetcher = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      expect(String(input)).toContain('/admin/v1/auth/session');
      expect(new Headers(init?.headers).get('authorization')).toBe(
        'Bearer signed-admin-token',
      );
      return Response.json({
        adminId: 'adm_test',
        email: 'owner@example.com',
        role: 'admin',
      });
    }) as unknown as typeof fetch;

    await expect(validateAdminSession(fetcher, 'signed-admin-token')).resolves.toBe(true);
    expect(fetcher).toHaveBeenCalledOnce();
  });

  it('rejects a signed non-Admin session', async () => {
    const fetcher = vi.fn(async () => Response.json({
      adminId: 'passenger_test',
      email: 'passenger@example.com',
      role: 'passenger',
    })) as unknown as typeof fetch;

    await expect(validateAdminSession(fetcher, 'signed-passenger-token')).resolves.toBe(false);
  });

  it('rejects an expired or otherwise invalid session', async () => {
    const fetcher = vi.fn(async () => Response.json(
      {
        success: false,
        error: {
          code: 'INVALID_ADMIN_SESSION',
          message: 'Admin authentication is invalid or expired.',
        },
      },
      { status: 401 },
    )) as unknown as typeof fetch;

    await expect(validateAdminSession(fetcher, 'expired-admin-token')).resolves.toBe(false);
  });
});
