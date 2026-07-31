import { describe, expect, it } from 'vitest';
import type { Cookies } from '@sveltejs/kit';
import { ADMIN_COOKIE, ADMIN_SESSION_SECONDS, setAdminSession } from './session';

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
});
