import { describe, expect, it, vi } from 'vitest';
import type { Cookies } from '@sveltejs/kit';
import { ADMIN_COOKIE } from '$lib/server/session';
import { POST } from './+server';

describe('Admin logout', () => {
  it('clears the server-only session and redirects to login', () => {
    const deleteCookie = vi.fn();
    const cookies = {
      delete: deleteCookie,
    } as unknown as Cookies;

    expect(() => POST({
      cookies,
      url: new URL('https://admin.example.com/logout'),
    } as never)).toThrow();
    expect(deleteCookie).toHaveBeenCalledWith(
      ADMIN_COOKIE,
      {
        path: '/',
        httpOnly: true,
        sameSite: 'strict',
        secure: true,
      },
    );
  });
});
